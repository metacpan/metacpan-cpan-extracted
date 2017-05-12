#
# This file is part of MooX-Options
#
# This software is copyright (c) 2013 by celogeek <me@celogeek.com>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package MooX::Options;

# ABSTRACT: Explicit Options eXtension for Object Class

use strict;
use warnings;

our $VERSION = '4.023';    # VERSION

use Locale::TextDomain 'MooX-Options';

my @OPTIONS_ATTRIBUTES
    = qw/format short repeatable negativable autosplit autorange doc long_doc order json hidden spacer_before spacer_after/;

sub import {
    my ( undef, @import ) = @_;
    my $options_config = {
        protect_argv          => 1,
        flavour               => [],
        skip_options          => [],
        prefer_commandline    => 0,
        with_config_from_file => 0,
        usage_string          => undef,

        #long description (manual)
        description => undef,
        authors     => [],
        synopsis    => undef,
        spacer      => " ",
        @import
    };

    my $target = caller;
    for my $needed_methods (qw/with around has/) {
        next if $target->can($needed_methods);
        croak(
            __x("Can't find the method <{needed_methods}> in <{target}> ! Ensure to load a Role::Tiny compatible module like Moo or Moose before using MooX::Options.",
                'needed_methods' => $needed_methods,
                'target'         => $target
            )
        );
    }

    my $with   = $target->can('with');
    my $around = $target->can('around');
    my $has    = $target->can('has');

    my @target_isa;
    { no strict 'refs'; @target_isa = @{"${target}::ISA"} };

    if (@target_isa) {    #only in the main class, not a role

        use warnings FATAL => 'redefine';
        ## no critic (ProhibitStringyEval, ErrorHandling::RequireCheckingReturnValueOfEval, ValuesAndExpressions::ProhibitImplicitNewlines)
        eval '{
        package ' . $target . ';

            sub _options_data {
                my ( $class, @meta ) = @_;
                return $class->maybe::next::method(@meta);
            }

            sub _options_config {
                my ( $class, @params ) = @_;
                return $class->maybe::next::method(@params);
            }

        1;
        }';
        use warnings FATAL => qw/void/;

        croak($@) if $@;

        $around->(
            _options_config => sub {
                my ( $orig, $self ) = ( shift, shift );
                return $self->$orig(@_), %$options_config;
            }
        );

        ## use critic
    }
    else {
        if ( $options_config->{with_config_from_file} ) {
            croak(
                __( "Please, don\'t use the option <with_config_from_file> into a role."
                )
            );
        }
    }

    my $options_data = {};
    if ( $options_config->{with_config_from_file} ) {
        $options_data->{config_prefix} = {
            format => 's',
            doc    => 'config prefix',
            order  => 0,
        };
        $options_data->{config_files} = {
            format => 's@',
            doc    => 'config files',
            order  => 0,
        };
    }

    my $apply_modifiers = sub {
        return if $target->can('new_with_options');
        $with->('MooX::Options::Role');
        if ( $options_config->{with_config_from_file} ) {
            $with->('MooX::ConfigFromFile::Role');
        }

        $around->(
            _options_data => sub {
                my ( $orig, $self ) = ( shift, shift );
                return ( $self->$orig(@_), %$options_data );
            }
        );
    };

    my @banish_keywords
        = qw/h help man usage option new_with_options parse_options options_usage _options_data _options_config/;
    if ( $options_config->{with_config_from_file} ) {
        push @banish_keywords, qw/config_files config_prefix config_dirs/;
    }

    my $option = sub {
        my ( $name, %attributes ) = @_;
        for my $ban (@banish_keywords) {
            croak(
                __x("You cannot use an option with the name '{ban}', it is implied by MooX::Options",
                    ban => $ban
                )
            ) if $name eq $ban;
        }

        $has->( $name => _filter_attributes(%attributes) );

        $options_data->{$name}
            = { _validate_and_filter_options(%attributes) };

        $apply_modifiers->();
        return;
    };

    if ( my $info = $Role::Tiny::INFO{$target} ) {
        $info->{not_methods}{$option} = $option;
    }

    { no strict 'refs'; *{"${target}::option"} = $option; }

    $apply_modifiers->();

    return;
}

sub _filter_attributes {
    my %attributes = @_;
    my %filter_key = map { $_ => 1 } @OPTIONS_ATTRIBUTES;
    return map { ( $_ => $attributes{$_} ) }
        grep { !exists $filter_key{$_} } keys %attributes;
}

sub _validate_and_filter_options {
    my (%options) = @_;
    $options{doc} = $options{documentation} if !defined $options{doc};
    $options{order} = 0 if !defined $options{order};
    $options{autosplit} = ','
        if !defined $options{autosplit} && $options{autorange};

    if ( $options{json}
        || ( defined $options{format} && $options{format} eq 'json' ) )
    {
        delete $options{repeatable};
        delete $options{autosplit};
        delete $options{autorange};
        delete $options{negativable};
        $options{json}   = 1;
        $options{format} = 's';
    }

    my %cmdline_options = map { ( $_ => $options{$_} ) }
        grep { exists $options{$_} } @OPTIONS_ATTRIBUTES, 'required';

    $cmdline_options{repeatable} = 1 if $cmdline_options{autosplit};
    $cmdline_options{format} .= "@"
        if $cmdline_options{repeatable}
        && defined $cmdline_options{format}
        && substr( $cmdline_options{format}, -1 ) ne '@';

    croak(
        __( "Negativable params is not usable with non boolean value, don't pass format to use it !"
        )
        )
        if $cmdline_options{negativable} && defined $cmdline_options{format};

    return %cmdline_options;
}

sub croak {
    require Carp;
    goto &Carp::croak;
}

1;

__END__

=pod

=head1 NAME

MooX::Options - Explicit Options eXtension for Object Class

=head1 VERSION

version 4.023

=head1 DESCRIPTION

Create a command line tool with your L<Mo>, L<Moo>, L<Moose> objects.

Everything is explicit. You have an C<option> keyword to replace the usual C<has> to explicitly use your attribute into the command line.

The C<option> keyword takes additional parameters and uses L<Getopt::Long::Descriptive>
to generate a command line tool.

=head1 SYNOPSIS

In myOptions.pm :

  package myOptions;
  use Moo;
  use MooX::Options;

  option 'show_this_file' => (
      is => 'ro',
      format => 's',
      required => 1,
      doc => 'the file to display'
  );
  1;

In myTool.pl :

  use myOptions;
  use Path::Class;

  my $opt = myOptions->new_with_options;

  print "Content of the file : ",
       file($opt->show_this_file)->slurp;

To use it :

  perl myTool.pl --show_this_file=myFile.txt
  Content of the file: myFile content

The help message :

  perl myTool.pl --help
  USAGE: myTool.pl [-h] [long options...]

      --show_this_file: String
          the file to display

      -h --help:
          show this help message

      --man:
          show the manual

The usage message :

  perl myTool.pl --usage
  USAGE: myTool.pl [ --show_this_file=String ] [ --usage ] [ --help ] [ --man ]

The manual :

  perl myTool.pl --man

=head1 METHODS

=head2 croak

Call Carp::croak dynamically

=head1 IMPORTED METHODS

The list of the methods automatically imported into your class.

=head2 new_with_options

It will parse your command line params and your inline params, validate and call the C<new> method.

  myTool --str=ko

  t->new_with_options()->str # ko
  t->new_with_options(str => 'ok')->str #ok

=head2 option

The C<option> keyword replaces the C<has> method and adds support for special options for the command line only.

See L</OPTION PARAMETERS> for the documentation.

=head2 options_usage | --help

It displays the usage message and returns the exit code.

  my $t = t->new_with_options();
  my $exit_code = 1;
  my $pre_message = "str is not valid";
  $t->options_usage($exit_code, $pre_message);

This method is also automatically fired if the command option "--help" is passed.

  myTool --help

=head2 options_man | --man

It displays the manual.

  my $t = t->new_with_options();
  $t->options_man();

This is automatically fired if the command option "--man" is passed.

  myTool --man

=head2 options_short_usage | --usage

It displays a short version of the help message.

  my $t = t->new_with_options();
  $t->options_short_usage($exit_code);

This is automatically fired if the command option "--usage" is passed.

  myTool --usage

=head1 IMPORT PARAMETERS

The list of parameters supported by L<MooX::Options>.

=head2 flavour

Passes extra arguments for L<Getopt::Long::Descriptive>. It is useful if you
want to configure L<Getopt::Long>.

  use MooX::Options flavour => [qw( pass_through )];

Any flavour is passed to L<Getopt::Long> as a configuration, check the doc to see what is possible.

=head2 protect_argv

By default, C<@ARGV> is protected. If you want to do something else on it, use this option and it will change the real C<@ARGV>.

  use MooX::Options protect_argv => 0;

=head2 skip_options

If you have Role with options and you want to deactivate some of them, you can use this parameter.
In that case, the C<option> keyword will just work like an C<has>.

  use MooX::Options skip_options => [qw/multi/];

=head2 prefer_commandline

By default, arguments passed to C<new_with_options> have a higher priority than the command line options.

This parameter will give the command line an higher priority.

  use MooX::Options prefer_commandline => 1;

=head2 with_config_from_file

This parameter will load L<MooX::ConfigFromFile> in your module. 
The config option will be used between the command line and parameters.

myTool :

  use MooX::Options with_config_from_file => 1;

In /etc/myTool.json

  {"test" : 1}

=head1 usage_string

This parameter is passed to Getopt::Long::Descriptive::describe_options() as
the first parameter.  

It is a "sprintf"-like string that is used in generating the first line of the
usage message. It's a one-line summary of how the command is to be invoked. 
The default value is "USAGE: %c %o".

%c will be replaced with what Getopt::Long::Descriptive thinks is the
program name (it's computed from $0, see "prog_name").

%o will be replaced with a list of the short options, as well as the text
"[long options...]" if any have been defined.

The rest of the usage description can be used to summarize what arguments
are expected to follow the program's options, and is entirely free-form.

Literal "%" characters will need to be written as "%%", just like with
"sprintf".

=head2 spacer

This indicate the char to use for spacer. Please only use 1 char otherwize the text will be too long.

The default char is " ".

  use MooX::Options space => '+'

Then the "spacer_before" and "spacer_after" will use it for "man" and "help" message.

  option 'x' => (is => 'ro', spacer_before => 1, spacer_after => 1);

=head1 OPTION PARAMETERS

The keyword C<option> extend the keyword C<has> with specific parameters for the command line.

=head2 doc | documentation

Documentation for the command line option.

=head2 long_doc

Documentation for the man page. By default the C<doc> parameter will be used.

See also L<Man parameters|MooX::Options::Manual::Man> to get more examples how to build a nice man page.

=head2 required

This attribute indicates that the parameter is mandatory.
This attribute is not really used by L<MooX::Options> but ensures that consistent error message will be displayed.

=head2 format

Format of the params, same as L<Getopt::Long::Descriptive>.

=over

=item * i : integer

=item * i@: array of integer

=item * s : string

=item * s@: array of string

=item * f : float value

=back

By default, it's a boolean value.

Take a look of available formats with L<Getopt::Long::Descriptive>.

You need to understand that everything is explicit here. 
If you use L<Moose> and your attribute has C<< isa => 'Array[Int]' >>, that will B<not> imply the format C<i@>.

=head2 format json : special format support

The parameter will be treated like a json string.

  option 'hash' => (is => 'ro', json => 1);

You can also use the json format

  option 'hash' => (is => 'ro', format => "json");

  myTool --hash='{"a":1,"b":2}' # hash = { a => 1, b => 2 }

=head2 negativable

It adds the negative version for the option.

  option 'verbose' => (is => 'ro', negativable => 1);

  myTool --verbose    # verbose = 1
  myTool --no-verbose # verbose = 0

=head2 repeatable

It appends to the L</format> the array attribute C<@>.

I advise to add a default value to your attribute to always have an array.
Otherwise the default value will be an undefined value.

  option foo => (is => 'rw', format => 's@', default => sub { [] });

  myTool --foo="abc" --foo="def" # foo = ["abc", "def"]

=head2 autosplit

For repeatable option, you can add the autosplit feature with your specific parameters.

  option test => (is => 'ro', format => 'i@', default => sub {[]}, autosplit => ',');
  
  myTool --test=1 --test=2 # test = (1, 2)
  myTool --test=1,2,3      # test = (1, 2, 3)

It will also handle quoted params with the autosplit.

  option testStr => (is => 'ro', format => 's@', default => sub {[]}, autosplit => ',');

  myTool --testStr='a,b,"c,d",e,f' # testStr ("a", "b", "c,d", "e", "f")

=head2 autorange

For another repeatable option you can add the autorange feature with your specific parameters. This 
allows you to pass number ranges instead of passing each individual number.

  option test => (is => 'ro', format => 'i@', default => sub {[]}, autorange => 1);
  
  myTool --test=1 --test=2 # test = (1, 2)
  myTool --test=1,2,3      # test = (1, 2, 3)
  myTool --test=1,2,3..6   # test = (1, 2, 3, 4, 5, 6)

It will also handle quoted params like C<autosplit>, and will not rangify them.

  option testStr => (is => 'ro', format => 's@', default => sub {[]}, autorange => 1);

  myTool --testStr='1,2,"3,a,4",5' # testStr (1, 2, "3,a,4", 5)

C<autosplit> will be set to ',' if undefined. You may set C<autosplit> to a different delimiter than ','
for your group separation, but the range operator '..' cannot be changed. 

  option testStr => (is => 'ro', format => 's@', default => sub {[]}, autorange => 1, autosplit => '-');

  myTool --testStr='1-2-3-5..7' # testStr (1, 2, 3, 5, 6, 7) 

=head2 short

Long option can also have short version or aliased.

  option 'verbose' => (is => 'ro', short => 'v');

  myTool --verbose # verbose = 1
  myTool -v        # verbose = 1

  option 'account_id' => (is => 'ro', format => 'i', short => 'a|id');

  myTool --account_id=1
  myTool -a=1
  myTool --id=1

You can also use a shorter option without attribute :

  option 'account_id' => (is => 'ro', format => 'i');

  myTool --acc=1
  myTool --account=1

=head2 order

Specifies the order of the attribute. If you want to push some attributes at the end of the list.
By default all options have an order set to C<0>, and options are sorted by their names.

  option 'at_the_end' => (is => 'ro', order => 999);

=head2 hidden

Hide option from doc but still an option you can use on command line.

  option 'debug' => (is => 'ro', doc => 'hidden');

Or

  option 'debug' => (is => 'ro', hidden => 1);

=head2 spacer_before, spacer_after

Add spacer before or after or both the params

  option 'myoption' => (is => 'ro', spacer_before => 1, spacer_after => 1);

=head1 ADDITIONAL MANUALS

=over

=item * L<Man parameters|MooX::Options::Manual::Man>

=item * L<Using namespace::clean|MooX::Options::Manual::NamespaceClean>

=item * L<Manage your tools with MooX::Cmd|MooX::Options::Manual::MooXCmd>

=back

=head1 EXTERNAL EXAMPLES

=over

=item * L<Slide3D about MooX::Options|http://perltalks.celogeek.com/slides/2012/08/moox-options-slide3d.html>

=back

=head1 Translation

Translation is now supported.

Use the dzil command to update the pot and merge into the po files.

=over

=item * dzil msg-init

Create a new language po

=item * dzil msg-scan

Scan and generate or update the pot file

=item * dzil msg-merge

Update all languages using the pot file

=back

=head2 THANKS

=over

=item * sschober

For implementation and German translation.

=back

=head1 THANKS

=over

=item * Matt S. Trout (mst) <mst@shadowcat.co.uk>

For his patience and advice.

=item * Tomas Doran (t0m) <bobtfish@bobtfish.net>

To help me release the new version, and using it :)

=item * Torsten Raudssus (Getty)

to use it a lot in L<DuckDuckGo|http://duckduckgo.com> (go to see L<MooX> module also)

=item * Jens Rehsack (REHSACK)

Use with L<PkgSrc|http://www.pkgsrc.org/>, and many really good idea (L<MooX::Cmd>, L<MooX::ConfigFromFile>, and more to come I'm sure)

=item * All contributors

For improving and add more feature to MooX::Options

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/celogeek/MooX-Options/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

celogeek <me@celogeek.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by celogeek <me@celogeek.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
