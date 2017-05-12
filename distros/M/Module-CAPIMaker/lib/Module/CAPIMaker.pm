package Module::CAPIMaker;

our $VERSION = '0.01';

use strict;
use warnings;

use Text::Template;
use File::Spec;
use POSIX qw(strftime);

use Exporter qw(import);
our @EXPORT = qw(make_c_api);

use Module::CAPIMaker::Template::Module_H;
use Module::CAPIMaker::Template::Module_C;
use Module::CAPIMaker::Template::Sample_XS;
use Module::CAPIMaker::Template::C_API_H;

sub new {
    my $class = shift;
    my %config = @_;
    my $self = { config => \%config,
                 function => {},
                 data => {}
               };

    $config{c_api_decl_filename} //= 'c_api.decl';

    bless $self, $class;
}

sub load_decl {
    my $self = shift;
    my $config = $self->{config};
    my $fn = $config->{c_api_decl_filename};
    open my $fh, '<', $fn or die "Unable to open $fn: $!\n";
    while (<$fh>) {
        chomp;
        s/^\s+//; s/\s+$//;
        next if /^(?:#.*)?$/;
        while (s/\s*\\$/ /) {
            my $next = <$fh>;
            chomp $next;
            $next =~ s/^\s+//; $next =~ s/\s+$//;
            $_ .= $next;
        }
        if (my ($k, $v) = /^(\w+)\s*=\s*(.*)/) {
            if (my ($mark) = $v =~ /^<<\s*(\w+)$/) {
                $v = '';
                while (1) {
                    my $line = <$fh>;
                    defined $line or die "Ending token '$mark' missing at $fn line $.\n";
                    last if $line =~ /^$mark$/;
                    $v .= $line;
                }
            }
            $self->{config}{$k} = $v;
        }
        elsif (/^((?:\w+\b\s*(?:\*+\s*)?)*)(\w+)\s*\(\s*(.*?)\s*\)$/) {
            my $args = $3;
            my %f = ( decl => $_,
                      type => $1,
                      name => $2,
                      args => $args );
            $self->{function}{$2} = \%f;

            if ($f{pTHX} = $args =~ s/^pTHX(?:_\s+|$)//) {
                $args =~ s/^void$//;
                my @args = split /\s*,\s*/, $args;
                # warn "args |$args| => |". join('-', @args) . "|";
                $f{macro_args} = join(', ', ('a'..'z')[0..$#args]);
                $f{call_args} = (@args ? 'aTHX_ (' . join('), (', ('a'..'z')[0..$#args]) .')' : 'aTHX');
            }

        }
        else {
            die "Invalid declaration at $fn line $.\n";
        }
    }
}

sub check_config {
    my $self = shift;
    my $config = $self->{config};

    my $module_name = $config->{module_name};
    die "module_name declaration missing from $config->{decl_filename}\n"
        unless defined $module_name;

    die "Invalid value for module_name ($module_name)\n"
        unless $module_name =~ /^\w+(?:::\w+)*$/;

    my $c_module_name = $config->{c_module_name} //= do { my $cmn = lc $module_name;
                                                          $cmn =~ s/\W+/_/g;
                                                          $cmn };
    die "Invalid value for c_module_name ($c_module_name)\n"
        unless $c_module_name =~ /^\w+$/;

    $config->{author} //= 'Unknown';
    $config->{min_version} //= 1;
    $config->{max_version} //= 1;

    die "Invalid version declaration, min_version ($config->{min_version}) > max_version ($config->{max_version})\n"
        if $config->{max_version} < $config->{min_version};

    $config->{required_version} //= $config->{max_version};
    $config->{module_version} //= '0';
    $config->{capimaker_version} = $VERSION;

    $config->{now} = strftime("%F %T", localtime);

    $config->{client_dir} //= 'c_api_client';

    $config->{module_c_filename}  //= "perl_$c_module_name.c";
    $config->{module_h_filename}  //= "perl_$c_module_name.h";
    $config->{sample_xs_filename} //= "sample.xs";
    $config->{c_api_h_filename}   //= "c_api.h";

    $config->{module_h_barrier} //= do { my $ib = "$config->{module_h_filename}_INCLUDED";
                                         $ib =~ s/\W+/_/g;
                                         uc $ib };
    die "Invalid value for module_h_barrier ($config->{module_h_barrier})\n"
        unless $config->{module_h_barrier} =~ /^\w+$/;

    $config->{c_api_h_barrier}  //= do { my $ib = "$config->{c_api_h_filename}_INCLUDED";
                                         $ib =~ s/\W+/_/g;
                                         uc $ib };
    die "Invalid value for c_api_h_barrier ($config->{c_api_h_barrier})\n"
        unless $config->{c_api_h_barrier} =~ /^\w+$/;


    $config->{$_} //= '' for qw(export_prefix
                                module_c_beginning
                                module_c_end
                                module_h_beginning
                                module_h_end);
}

sub gen_file {
    my ($self, $template, $dir, $save_as) = @_;
    my $config = $self->{config};
    system mkdir => -p => $dir unless -d $dir; # FIX ME!
    $save_as = File::Spec->rel2abs(File::Spec->join($dir, $save_as));
    open my $fh, '>', $save_as or die "Unable to create $save_as: $!\n";
    local $Text::Template::ERROR;
    my $tt = Text::Template->new(TYPE => (ref $template ? 'ARRAY' : 'FILE'),
                                 SOURCE => $template,
                                 DELIMITERS => ['<%', '%>'] );
    $tt->fill_in(HASH => { %$config, function => $self->{function} },
                 OUTPUT => $fh);
    warn "Some error happened while generating $save_as: $Text::Template::ERROR\n"
        if $Text::Template::ERROR;
}

sub gen_all {
    my $self = shift;
    my $config = $self->{config};
    $self->gen_file($config->{module_c_template_filename} // \@Module::CAPIMaker::Template::Module_C::template,
                    $config->{client_dir},
                    $config->{module_c_filename});
    $self->gen_file($config->{module_h_template_filename} // \@Module::CAPIMaker::Template::Module_H::template,
                    $config->{client_dir},
                    $config->{module_h_filename});
    $self->gen_file($config->{sample_xs_template_filename} // \@Module::CAPIMaker::Template::Sample_XS::template,
                    $config->{client_dir},
                    $config->{sample_xs_filename});
    $self->gen_file($config->{c_api_h_template_filename} // \@Module::CAPIMaker::Template::C_API_H::template,
                    '.',
                    $config->{c_api_h_filename});
}

sub make_c_api {
    my %args;
    for (@ARGV) {
        /^\s*(\w+)\s*=\s*(.*?)\s*$/
            or die "Bad argument '$_'\n";
        $args{$1} = $2;
    }
    my $mcm = Module::CAPIMaker->new(%args);
    $mcm->load_decl;
    $mcm->check_config;
    $mcm->gen_all;
}

1;
__END__

=head1 NAME

Module::CAPIMaker - Provide a C API for your XS modules

=head1 SYNOPSIS

  perl -MModule::CAPIMaker -e make_c_api

=head1 DESCRIPTION

If you are the author of a Perl module written using XS. Using
Module::CAPIMaker you will be able to provide your module users with
an easy and efficient way to access its functionality directly from
their own XS modules.

=head2 UNDER THE HOOD

The exporting/importing of the functions provided through the C API is
completely handled by the support files generated by
Module::CAPIMaker, and not the author of the module providing the API,
neither the authors of the client modules need really to know how it
works but on the other hand it does not harm to understand it and
anyway it will probably easy the understanding of the module
usage. So, read on :-) ..

Suppose that we have one module C<Foo::XS> C<Foo::XS> providing a C
API with the help of Module::CAPIMaker and another module C<Bar> that
uses that API.

When C<Foo::XS> is loaded, the addresses of the functions available
through the C API are published on the global hash C<%Foo::XS::C_API>.

When C<Bar> loads, first, it ensures that C<Foo::XS> is loaded
(loading it if required) and checks that the versions of the C API
supported by the version of C<Foo::XS> loaded include the version
required. Then, it copies the pointers on the C<%Foo::XS::C_API> hash to C
static storage where they can be efficiently accessed without
performing a hash look-up every time.

Finally calls on Bar to the C functions from C<Foo::XS> are
transparently routed through these pointers with the help of some
wrapping macros.

=head2 STRUCTURE OF THE C API

The C API is defined in a file named C<c_api.decl>. This file may
contain the prototypes of the functions that will be available through
the C API and several configuration settings.

From this file, C<Module::CAPIMaker> generates two sets of files, one
set contains the files that are used by the module providing the C API
in order to support it. The other set is to be used by client modules.

They are as follows:

=head3 C API provider support files

On the C API provider side, a file named C<c_api.h> is generated. It
defines the initialization function that populates the C<%C_API> hash.

=head3 Client support files

There are two main files to be used by client modules, one is
C<perl_${c_module_name}.c> containing the definition of the client
side C API initialization function.

The second file is C<perl_${c_module_name}.h> containing the
prototypes of the functions made available through the C API and a set
of macros to easy their usage.

C<${c_module_name}> is the module name lower-cased and with every
non-alphanumeric sequence replaced by a underscore in order to make in
C friendly. For instance, C<Foo::XS> becomes C<foo_xs> and the files
generated are C<perl_foo_xs.c> and C<perl_foo_xs.h>.

A sample/skeleton C<Sample.xs> file is also generated.

The client files go into the directory C<c_api_client> where you may
also like to place additional files as for instance a C<typemap> file.

=head2 C API DEFINITION

The C API is defined through the file C<c_api.decl>.

Two types of entries can be included in this file: function prototypes
and configuration settings.

=head3 Function declarations

Function declarations are identical to those you will use in a
C header file (without the semicolon at the end). In example:

  int foo(double)
  char *bar(void)

Functions that use the THX macros are also accepted:

  SV *make_object(pTHX_ double *)

You have to use the prototype variant (C<pTHX> or C<pTHX_>) and
Module::CAPIMaker will replace it automatically by the correct variant
of the macro depending of the usage.

=head3 Configuration settings

Configuration settings are of the form C<key=value> where key must
match /^\w+$/ and value can be anything. For instance

   module_name = Foo::XS
   author = Valentine Michael Smith

A backslash at the end of the line indicates that the following line
is a continuation of the current one:

   some_words = bicycle automobile \
                house duck

Here-docs can also be used:

   some_more_words = <<END
   car pool tree
   disc book
   END

The following configuration settings are currently supported by the
module:

=over 4

=item module_name

Perl name of the module, for instance, C<Foo::XS>.

=item c_module_name = foo_bar

C-friendly name of the module, for instance C<foo_xs>

=item module_version

Version of the Perl module. This variable should actually be set from
the C<Makefile.PL> script and is not used internally by the C API
support functions. It just appears on the comments of the generated
files.

=item author = Valentine M. Smith <vmsmith@cpan.org>

Name of the module author, to be included on the headers of the
generated files.

=item min_version

=item max_version

=item required_version

In order to support evolution of the C API a min/max version approach
is used.

The C<min_version>/C<max_version> numbers are made available through
the C<%C_API> hash. When the client module loads, it checks that the
version it requires lays between these two numbers or otherwise croaks
with an error.

By default C<required_version> is made equal to C<max_version>.

=item client_dir

The directory where the client support files are placed. By default
C<c_api_client>.


=item module_h_filename

Name of the client support header file (i.e. C<perl_foo_xs.h>).

=item module_c_filename

Name of the client C file providing the function to initialize the client
side of the C API (i.e. C<perl_foo_xs.c>).

=item c_api_h_filename

Name of the support file used on the C API provider side. Its default
value is C<c_api.h>.

=item module_h_barrier

Name of the macro used to avoid multiple loading of the definitions
inside C<${module_h_filename}>.

It defaults to C<uc("${c_module_name}_H_INCLUDED")>. For instance
C<PERL_FOO_XS_H_INCLUDED>.

=item c_api_h_barrier

Name of the macro used to avoid multiple loading of the definitions on
the header file C<c_api.h>. It defaults to C<C_API_H_INCLUDED>.

=item export_prefix

It's possible to add a prefix to the name of the functions exported
through the C API in the client side.

For instance, if the function C<bar()> is exported from the module
C<Foo::XS>, setting C<export_prefix=foo_> will make that function
available on the client module as C<foo_bar()>.

=item module_c_beginning

The text in this variable is placed inside the file
C<${module_c_filename}> at some early point. It can be used to inject
typedefs and other definitions needed to make the file compile.

=item module_c_end

The text inside this variable is placed at the end of the file
C<${module_c_filename}>.

=item module_h_beginning

The text inside this variable is placed inside the file
C<${module_h_filename}> at some early point.

=item module_h_end

The text inside this variable is placed at the end of the file
C<${module_h_filename}>.

=item c_api_decl_filename

The name of the file with the definition of the C API. Defaults to
C<c_api.decl>.

Obviously this setting can only be set from the command line!

=item module_c_template_filename

=item module_h_template_filename

=item sample_xs_template_filename

=item c_api_h_template_filename

Internally the module uses L<Text::Template> to generate the support
files with a set of default templates. For maximum customizability a
different set of templates can be used.

See L</Customizing the C API generation process>.

=back

=head2 RUNNING THE C API GENERATOR

Once your C<c_api.decl> file is ready use C<Module::CAPIMaker> to generate
the C API running the companion script C<make_perl_module_c_api>. This
script also accept a list of configuration setting from the command
line. For instance:

  make_perl_module_c_api module_name=Foo::XS \
      author="Valentine Michael Smith"

If you want to do it from some Perl script, you can also use the
C<make_c_api sub> exported by this module.

=head2 INITIALIZING THE C API

In order to initialize the C API from the module supporting it you
have to perform the following two changes on your XS file:

=over 4

=item 1

Include C<c_api.h>.

=item 2

Call the macro C<INIT_C_API> from the C<BOOT> section.

=back

For instance,

  #include "EXTERN.h"
  #include "perl.h"
  #include "XSUB.h"
  #include "ppport.h"

  /* your C code goes here */

  #include "c_api.h"

  MODULE = Foo::XS		PACKAGE = Foo::XS

  BOOT:
    INIT_C_API;

  /* your XS function declarations go here */


=head2 AUTOMATIC C API GENERATION WITH ExtUtils::MakeMaker

In order to get the C API interface files regenerated every time the
file C<c_api.decl> is changed, add the following lines at the end of
your C<Makefile.PL> script.

  package MY;

  sub postamble {
      my $self = shift;
      my $author = $self->{AUTHOR};
      $author = join(', ', @$author) if ref $author;
      $author =~ s/'/'\''/g;

      return <<MAKE_FRAG

  c_api.h: c_api.decl
  \tmake_perl_module_c_api module_name=\$(NAME) module_version=\$(VERSION) author='$author'
  MAKE_FRAG
  }
  
  sub init_dirscan {
      my $self = shift;
      $self->SUPER::init_dirscan(@_);
      push @{$self->{H}}, 'c_api.h' unless grep $_ eq 'c_api.h', @{$self->{H}};
  }

You may also like to include the generated files into the file
C<MANIFEST> in order to not require your module users to also have
C<Module::CAPIMaker> installed.

=head2 EXPORT

The module C<Module::CAPIMaker> exports the subroutine C<make_c_api> when
loaded. This sub parses module settings from @ARGV and the file
C<a_api.decl> and performs the generation of the C API support files.

=head1 USAGE OF THE C API FROM OTHER MODULES

In order to use functions provided by a XS module though a C API
generated by Module::CAPIMaker, you have to perform the following steps:

=over 4

=item 1

Copy the files from the C<c_api_client> directory into your module
directory.

=item 2

On your C<Makefile.PL> script, tell L<ExtUtils::MakeMaker> to compile
and link the C file just copied. That can be attained adding C<OBJECT
=E<gt> '$(O_FILES)'> arguments to the C<WriteMakefile>
call:

  WriteMakefile(...,
                OBJECT        => '$(O_FILES)',
                ...);

=item 3

Include the header file provided from all the compilation units
(usually C<.c> and C<.xs> files) that want to use the functions
available through the C API.

=item 4

Initialize the client side of the C API from the BOOT section of your
XS module calling the load-or-croak macro. For instance:

  #include "EXTERN.h"
  #include "perl.h"
  #include "XSUB.h"
  #include "ppport.h"

  #include "perl_foo_xs.h"

  MODULE=Bar    PACKAGE=Bar

  BOOT:
      PERL_FOO_XS_LOAD_OR_CROAK;

=back

=head1 CUSTOMIZING THE C API GENERATION PROCESS

Internally, the module uses L<Text::Template> to generate the support files.

In order to allow for maximum customizability, the set of templates
used can be changed.

As an example of a module using a customized set of templates see
L<Math::Int64>.

The default set of templates is embedded inside the sub-modules under
L<Module::CAPIMaker::Template>, you can use them as an starting point.

Finally, if you find the module limiting in some way don't hesitate to
contact me explaining your issued. I originally wrote
Module::CAPIMaker to solve my particular problems but I would gladly
expand it to make it cover a wider range of problems.

=head1 SEE ALSO

L<Math::Int128>, L<Math::Int64>, L<Tie::Array::Packed> are modules
providing or using (or both) a C API created with the help of
Module::CAPIMaker.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Salvador FandiE<ntilde>o,
E<lt>sfandino@yahoo.comE<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.4 or,
at your option, any later version of Perl 5 you may have available.


=cut
