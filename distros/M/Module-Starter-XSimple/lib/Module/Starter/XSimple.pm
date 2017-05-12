package Module::Starter::XSimple;
use base 'Module::Starter::Simple';
# vi:et:sw=4 ts=4

use version; $VERSION = qv(v0.0.2);

use warnings;
use strict;
use Carp;
use Path::Class;

# Other recommended modules (uncomment to use):
#  use IO::Prompt;
#  use Perl6::Export;
#  use Perl6::Slurp;
#  use Perl6::Say;
#  use Regexp::Autoflags;


# Module implementation here
sub rtname {
    my ($self, $module) = @_;
    my $rtname = lc $module;
    $rtname =~ s/::/-/g;
    return $rtname;
}

sub module_path_create {
    my ($self, $module, $ext) = @_;
    $ext = '.pm' unless defined $ext;

    my @parts = split( /::/, $module );
    my $filepart = (pop @parts) . $ext;
    my @dirparts = ( $self->{basedir}, 'lib', @parts );
    my $manifest_file = join( "/", "lib", @parts, $filepart );
    if ( @dirparts ) {
        my $dir = File::Spec->catdir( @dirparts );
        if ( not -d $dir ) {
            mkpath $dir;
            $self->progress( "Created $dir" );
        }
    }

    my $module_file = File::Spec->catfile( @dirparts,  $filepart );

    return ($manifest_file, $module_file);
}


sub create_modules {
    my $self = shift;
    my @modules = @_;

    my (@files, @xsfile);

    for my $module ( @modules ) {
        push @files, $self->_create_module( $module );
        push @files, $self->_create_xsmodule( $module );
	push @files, $self->_create_typemap( $module );
    }
    push @files, $self->_create_ppport();
    $self->{xsfiles} = 

    return @files;
}

sub _create_xsmodule {
    my $self = shift;
    my $module = shift;

    my ($manifest_file, $module_file) = 
    	$self->module_path_create($module, '.xs');
    open( my $fh, ">", $module_file ) or die "Can't create $module_file: $!\n";
    print $fh $self->xsmodule_guts( $module );
    close $fh;
    $self->progress( "Created $module" );

    return $manifest_file;
}

sub xsmodule_guts {
    my $self = shift;
    my $module = shift;
    (my $module_obj = $module) =~ s/::/_/g;

    my $year = $self->_thisyear();

    my $content = <<"HERE";
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

typedef SV * $module_obj;

MODULE = $module		PACKAGE = $module		

$module_obj
new(...)
    INIT:
    	char *classname;
	/* get the class name if called as an object method */
	if ( sv_isobject(ST(0)) ) {
	    classname = HvNAME(SvSTASH(SvRV(ST(0))));
	}
	else {
	    classname = (char *)SvPV_nolen(ST(0));
	}

    CODE:
    	/* This is a standard hash-based object */
    	RETVAL = ($module_obj)newHV();

	/* Single init value */
	if ( items == 2 ) 
	    hv_store((HV *)RETVAL, "value", 5, newSVsv(ST(1)), 0);
	/* name/value pairs */
	else if ( (items-1)%2 == 0 ) {
	    int i;
	    for ( i=1; i < items; i += 2 ) {
		hv_store_ent((HV *)RETVAL, ST(i), newSVsv(ST(i+1)), 0);
	    }
	}
	/* odd number of parameters */
	else {
	    Perl_croak(aTHX_
		"Usage: $module->new()\\n"
		"    or $module->new(number)\\n"
		"    or $module->new(key => value, ...)\\n"
	    );
	}

    OUTPUT:
    	RETVAL

IV
increment(obj)
    $module_obj obj

    INIT:
    	RETVAL = 0;
	if ( items > 1 )
	    Perl_croak(aTHX_ "Usage: $module->increment()");

    CODE:
    	SV **svp;
	if ((svp = hv_fetch((HV*)obj, "value", 5, FALSE))) {
	    RETVAL = SvIV(*svp);
	    RETVAL++;
	    hv_store((HV *)obj, "value", 5, newSViv(RETVAL), 0);
	}
    OUTPUT:
    	RETVAL
HERE

    return $content;
}

sub _create_typemap {
    my $self = shift;
    my $module = shift;

    my ($manifest_file, $typemap_file) = 
    	$self->module_path_create($module, '');
 
    #change typemap file name to 'typemap'
    $manifest_file = Path::Class::File->new($manifest_file)->parent->file('typemap');
    $typemap_file = Path::Class::File->new($typemap_file)->parent->file('typemap');

    open( my $fh, ">", $typemap_file )
    	or die "Can't create $typemap_file: $!\n";
    print "open $typemap_file to print typemap to\n";
    print $fh $self->typemap_guts($module);
    close $fh;
    $self->progress( "Created typemap" );

    return $manifest_file;
}

sub typemap_guts {
    my $self = shift;
    my $module = shift;
    (my $module_obj = $module) =~ s/::/_/g;

    my $year = $self->_thisyear();
    my $author = $self->{author};

    # First the portion that needs substitution
    my $content = qq(\
###############################################################################
##
##    Typemap for $module objects
##
##    Copyright (c) $year $author
##    All rights reserved.
##
##    This typemap is designed specifically to make it easier to handle
##    Perl-style blessed objects in XS.  In particular, it takes care of
##    blessing the object into the correct class (even for derived classes).
##   
##
###############################################################################
## vi:et:sw=4 ts=4

TYPEMAP

$module_obj T_PTROBJ_SPECIAL
);
    # And the the portion that must be literal
    $content .= q(
INPUT
T_PTROBJ_SPECIAL
    if (sv_derived_from($arg, \"${(my $ntt=$ntype)=~s/_/::/g;\$ntt}\")) {
	$var = SvRV($arg);
    }
    else
	croak(\"$var is not of type ${(my $ntt=$ntype)=~s/_/::/g;\$ntt}\")

OUTPUT
T_PTROBJ_SPECIAL
    /* inherited new() */
    if ( strcmp(classname,\"${(my $ntt=$ntype)=~s/_/::/g;\$ntt}\") != 0 )
	$arg = sv_bless(newRV_noinc($var),
	    gv_stashpv(classname,TRUE));
    else
	$arg = sv_bless(newRV_noinc($var),
	    gv_stashpv(\"${(my $ntt=$ntype)=~s/_/::/g;\$ntt}\",TRUE));
);
    return $content;
}

sub _create_ppport {
    use Devel::PPPort;
    my $self = shift;

    my $ppport_file = File::Spec->catfile( $self->{basedir}, "ppport.h" );
    Devel::PPPort::WriteFile($ppport_file);
    $self->progress( "Created ppport" );

    return "ppport.h";
}

sub Build_PL_guts {
    my $self = shift;
    my $main_module = shift;
    my $main_pm_file = shift;
    my $xsmodule = ( split (/::/, $main_module) )[-1];
    (my $xsmodule_path = $main_pm_file) =~ s/\.pm$/.xs/;

    (my $author = "$self->{author} <$self->{email}>") =~ s/'/\'/g;

    return <<"HERE";
use strict;
use warnings;
use Module::Build;

my \$builder = Module::Build->new(
    module_name         => '$main_module',
    license             => '$self->{license}',
    dist_author         => '$author',
    dist_version_from   => '$main_pm_file',
    include_dirs        => ['.'],
    requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ '$self->{distro}-*' ],
);

\$builder->create_build_script();
HERE
}

sub module_guts {
    my $self = shift;
    my $module = shift;

    my $year = $self->_thisyear();
    my $rtname = $self->rtname($module);

    my $content = <<"HERE";
package $module;

use warnings;
use strict;

\=head1 NAME

$module - The great new $module!

\=head1 VERSION

Version 0.01

\=cut

our \$VERSION = '0.01';

require XSLoader;
XSLoader::load('$module', \$VERSION);

\=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use $module;

    my \$foo = $module->new();
    ...

\=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

\=head1 FUNCTIONS

\=head2 new

Creates a new $module object.  Takes the following optional parameters:

\=over 4

\=item value

If you pass a single numeric value, it will be stored in the 'value' slot
of the object hash.

\=item key/value pair

A generic input method which takes an unlimited number of key/value pairs
and stores them in the object hash.  Performs no validation.

\=back

\=cut

#sub new {
# Defined in the XS code
#}

\=head2 increment

An object method which increments the 'value' slot of the the object hash,
if it exists.  Called like this:

  my \$obj = $module->new(5);
  \$obj->increment(); # now equal to 6

\=cut

#sub function2 {
# Defined in the XS code
#}

\=head1 AUTHOR

$self->{author}, C<< <$self->{email}> >>

\=head1 BUGS

Please report any bugs or feature requests to
C<bug-$rtname\@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=$self->{distro}>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

\=head1 ACKNOWLEDGEMENTS

\=head1 COPYRIGHT & LICENSE

Copyright $year $self->{author}, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

\=cut

1; # End of $module
HERE
    return $content;
}

sub t_guts {
    my $self = shift;
    my @modules = @_;
    my %t_files = $self->SUPER::t_guts(@modules);
    my $main_module = $modules[0];
    my $use_lines = join( "\n", map { "use_ok( '$_' );" } @modules );

    $t_files{'01-object.t'} = <<"HERE";

use Test::More tests => 10;

BEGIN {
$use_lines
}

my \$obj;

ok( \$obj = ${main_module}->new(), "no initializer");
isa_ok(\$obj,"${main_module}");

ok( \$obj = ${main_module}->new(1), "initial numeric value");
ok(\$obj->{value} == 1, "implicit initializer");

ok( \$obj = ${main_module}->new("fish"), "initial string value");
ok(\$obj->{value} eq "fish", "implicit initializer");

ok( \$obj = ${main_module}->new(color => "red", flavor => "sour"), 
	"hash as initializer");
ok( \$obj->{color} eq "red", "first hash key");
ok( \$obj->{flavor} eq "sour", "first hash key");
HERE

    $t_files{'02-feature.t'} = <<"HERE";
use Test::More tests => 5;

BEGIN {
$use_lines
}

my \$obj = ${main_module}->new(1);
ok( \$obj->increment );
ok( \$obj->{value} == 2);

\$obj = ${main_module}->new(value => 3);
ok( \$obj->{value} == 3 );
ok( \$obj->increment == 4 );
HERE

    return %t_files;
}
    
1; # Magic true value required at end of module
__END__

=head1 NAME

Module::Starter::XSimple - Create XS modules with Module::Starter


=head1 VERSION

This document describes Module::Starter::XSimple version v0.0.2


=head1 DESCRIPTION

Replacement class for Module::Starter::Simple.

Can be used in two ways:

=over 4

=item * Using the commandline 

Pass as an override class to the module-starter script:

  module-starter --module=[modulename] \
  --class=Module::Starter::XSimple

=item * Using a config file

Create a .module-starter/config file with at least the following:

    author:  your name
    email:   your_address@example.com
    builder: Module::Build
    plugins: Module::Starter::XSimple

At present, M::S::XSimple only supports Module::Build, because the XS 
and associated files locations are different between Module::Build and 
ExtUtils::ModuleMaker.

=back

All methods are replacements or additions to the methods provided by
Module::Starter::Simple.
  
=head2 Build_PL_guts

Creates the custom Build.PL file for the generated module.

=head2 create_modules

Creates the .PM, .XS, and typemap files for each requested module.
Calls the following three subs:

=over 4

=item module_guts

Generates the .PM file from skeleton code.

=item xsmodule_guts

Generates the .XS file from skeleton code.

=item typemap_guts

Generates the typemap file from skeleton code.

=back

=head2 module_path_create

Replacement sub for M::S::Simple routine; permits the caller to set
the file extension when creating non .PM files.

=head2 rtname

Generate the special e-mail address to use when reporting bugs via
rt.cpan.org.

=head2 t_guts

Add additional test files.

=head1 DEPENDENCIES

  Devel::PPPort
  Module::Starter
  Test::More
  version

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-module-starter-xsimple@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

John Peacock  C<< <jpeacock@cpan.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2005,2012 John Peacock C<< <jpeacock@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
