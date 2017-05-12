
package MooseX::Getopt::Usage;

use 5.010;
our $VERSION = '0.24';

use Moose::Role;
use Try::Tiny;
use MooseX::Getopt::Usage::Formatter;

with 'MooseX::Getopt::Basic';

# As we don't use GLD insert our own help_flag.
has help_flag => (
    is            => 'rw',
    isa           => 'Bool',
    traits        => ['Getopt'],
    cmd_flag      => 'help',
    cmd_aliases   => [qw/? usage/],
    documentation => "Display the usage message and exit"
);

# Promote warnings to errors to capture invalid and missing options errors from
# Getopt::Long::GetOptions.
around _getopt_spec_warnings => sub {
    shift; my $class = shift;
    die @_;
};

sub getopt_usage_config { () }

sub getopt_usage {
    my $proto = shift;
    my $class = ref $proto || $proto;
    my %args  = @_;
    my $conf  = { $class->getopt_usage_config, %args };
    if ( ! exists $conf->{colours} && exists $conf->{colors} ) {
        $conf->{colours} = delete $conf->{colors}
    }
    $conf->{getopt_class} = $class;
    my $fmtr = MooseX::Getopt::Usage::Formatter->new($conf);
    return $args{man} ? $fmtr->manpage(%args) : $fmtr->usage(%args);
}

# Replace new_with_options.  The way it decides if usage is needed does not fit
# our needs as we don't supply a usage object. So we do it here.  We also want
# access to the $pa object returned from process_argv.
around new_with_options => sub {
    my $orig  = shift;
    my $class = shift;
    my @params = @_;
    my $self;

    my $conf = { $class->getopt_usage_config };
    $conf->{auto_man} = 1 if not exists $conf->{auto_man};
    $conf->{auto_help} = 1 if not exists $conf->{auto_help};

    try {
        # Get in early on the arg passing to look for help or man options.
        # This makes sure they still work even when required options are missing,
        # (which would fail construction and stop us seeing the man option).
        # See github issue #4
        my $pa = $class->process_argv(@params);
        my $cli_params = $pa->cli_params;
        $class->getopt_usage( man => 1)
            if $conf->{auto_man} and $class->can('man') and $cli_params->{man};
        $class->getopt_usage( exit => 0 )
            if $conf->{auto_help} and $cli_params->{help_flag};

        # Construct the object in the same way as our super new_with_options
        $self = $class->new(
            ARGV       => $pa->argv_copy,
            extra_argv => $pa->extra_argv,
            ( $pa->usage ? ( usage => $pa->usage ) : () ),
            %{ $pa->constructor_params }, # explicit params to ->new
            %{ $pa->cli_params }, # params from CLI
        );
        return $self;
    }
    catch {
        if (
            /Attribute \((\w+)\) does not pass the type constraint because: (.*?) at/
        ) {
            $class->getopt_usage( exit => 1, err => "Invalid '$1' : $2" );
        }
        elsif (/Attribute \((\w+)\) is required /) {
            $class->getopt_usage( exit => 2, err => "Required option missing: $1" );
        }
        elsif (/^Unknown option:|^Value .*? for option |Option .* does not take an argument/) {
            # Getopt::Long warnings we promoted in _getopt_spec_warnings
            s/\n+$//;
            $class->getopt_usage( exit => 3, err => $_ );
        }
        else {
            die $_;
        }
    };
};

no Moose::Role;

1;
__END__

=pod

=head1 NAME

MooseX::Getopt::Usage - Extend MooseX::Getopt with usage message and man page generated from attribute meta and POD.

=head1 VERSION

Version 0.24

=head1 SYNOPSIS

    ## In your class
    package My::App;
    use Moose;

    with 'MooseX::Getopt::Usage',
         'MooseX::Getopt::Usage::Role::Man';

    has verbose => ( is => 'ro', isa => 'Bool', default => 0,
        documentation => qq{Say lots about what we are doing} );

    has gumption => ( is => 'rw', isa => 'Int', default => 23,
        documentation => qq{How much gumption to apply} );

    # ... rest of class

    ## In your script
    #!/usr/bin/perl
    use My::App;
    my $app = My::App->new_with_options;

Can now get help,

 $ synopsis.pl -?
 Usage:
     synopsis.pl [OPTIONS]
 
 Options:
      --man             - Bool. Display man page
      --help -? --usage - Bool. Display the usage message and exit
      --verbose         - Bool. Say lots about what we are doing
      --gumption        - Int. Default=23. How much gumption to apply


trap errors with usage,

 $ synopsis.pl --elbowgrease --gumption=Lots
 Unknown option: elbowgrease
 Value "Lots" invalid for option gumption (number expected)
 Usage:
     synopsis.pl [OPTIONS]
 
 Options:
      --man             - Bool. Display man page
      --help -? --usage - Bool. Display the usage message and exit
      --verbose         - Bool. Say lots about what we are doing
      --gumption        - Int. Default=23. How much gumption to apply
 
and get a man page:

 $ synopsis.pl --man

=head1 DESCRIPTION

Perl Moose Role that extends L<MooseX::Getopt> to provide usage printing and
man page generation that inspects your classes meta information to build a
(coloured) usage message including that meta information.

If STDOUT is a tty usage message is colourised. Setting the env var
ANSI_COLORS_DISABLED will disable colour even on a tty.

The message is formatted to the width of the terminal when STDOUT is a tty, to
a width of 72 characters otherwise.

Errors in command line option parsing will be displayed along with the usage,
causing the program to exit with a non-zero status code when new_with_options
is used.

The usage message can be extended and controlled by including sections selected
from the modules POD, with the default to automatically generate SYNOPSIS and
OPTIONS sections.

By also using the L<MooseX::Getopt::Usage::Role::Man> role a --man option is
added to your class that will display the man page generated from your modules
POD documentation. This POD will include the generated SYNOPSIS and OPTIONS
sections if they are selected.

This is all much inspired (and partly implemented) by the excellent
L<Pod::Usage> module, but with added Moose meta goodness.


=head1 ATTRIBUTES

=head2 help_flag

Indicates if any of -?, --help, or --usage where given in the command line
args.

=head2 man

Added when using L<MooseX::Getopt::Usage::Role::Man>. The --man option on the
command line. If true after class construction program will exit displaying the
man generated from the POD.

=head1 METHODS

=head2 new_with_options( %params )

The normal L<MooseX::Getopt> entry point, over ridden here to add our own usage
handling. If help_flag (-?, --help or --usage) is given in the options will
display the usage message and exit.

If L<MooseX::Getopt::Usage::Role::Man> (or man method exists that returns true)
exits displaying the man page.

Traps errors from the command line processing, displaying them along with the
usage message. Will also trap type constraint fails and missing required
attribute errors from your classes constructor.

=head2 getopt_usage( %args )

Generate the usage message and return or output to stdout and exit. Used by
new_with_options. Without exit arg returns the usage string, with an exit arg
prints the usage to stdout and exits with the given exit code.

 print $self->getopt_usage if $self->help_flag;

 $self->getopt_usage( exit => 10, err => "Their all dead, Dave" );

 $self->getopt_usage( man => 1 );

Options are printed required first, then optional.  These two sections get a
heading unless C<headings> arg or config is false. Note that required
attributes of your class that have a default or builder will be considered
optional options.

%args can have any of the options from L</CONFIGURATION>, plus the following.

=over 4

=item exit

If an exit arg is given and defined then this method will exit the program with
that exit code after displaying usage to STDOUT.

=item err | error

Error message string to display before the usage. Will get the error highlight.

=item man

Display the man page instead of the usage message.

=back

=head2 getopt_usage_config

Return a hash (ie a list) of config to override the defaults. Default returns
empty list. See L</CONFIGURATION> for details of the option keys.

Note that this method gets called as a class method, before the class is
constructed. If you wish to change this method from a role you will need to use
the around method modifier. See L</Sharing config>.

=head1 CONFIGURATION

The configuration used is the defaults, followed by the return from
L</getopt_usage_config>, followed by any args passed direct to L</getopt_usage>.
The easiest way to configure the usage message is to override
L</getopt_usage_config> in your class. e.g. to use a more compact layout.

 use Moose;
 with 'MooseX::Getopt::Usage';

 sub getopt_usage_config {
    return (
        format   => "Usage: %c [OPTIONS]",
        headings => 0,
    );
 }

Available config is:

=head2 format

String to format the usage/synopsis section of the usage message. %c is
substituted for the command name. Use %% for a literal %.

If not set it will check the POD for L</format_sections>, using the POD selected
if it is found. That defaults to the SYNOPSIS section, so the easy way to add
your own usage section is to add a SYNOPSIS to your POD.

If no POD is found a default string of C<"%c [OPTIONS]"> is used.

Note that when selecting POD the headings are removed.

%a, %r and %o expand to a list of all the options on a line. %a gives all
options, %r only required and %o only optional. Option args get square
brackets around them, while non-boolean options get an =VALUE added. e.g. using
a format string of "%c %r %o" might produce:

 makestuff --name=NAME [--verbose] [--type=TYPE]

=head2 format_sections

Pod sections to select for the usage format option. Default is SYNOPSIS.
Value is an array ref of L<Pod::Select/SECTION SPECIFICATIONS> strings.

=head2 width

Width to wrap output text. Default tests for a terminal, using it's width-1 if
found (so users get usage or man that fills the terminal but wraps nicely),
defaulting to 72 otherwise.

=head2 attr_sort

Sub ref used to sort the attributes and hence the order they appear in the
usage message. Default is the order the attributes are defined.

B<NB:> the sort terms ($a and $b) are passed as the first two arguments, do
B<not> use $a and $b (you will get warnings). The arguments will be
L<Moose::Meta::Attribute>s. e.g. to sort by name alphabetically:

    attr_sort => sub { $_[0]->name cmp $_[1]->name }

=head2 headings

Whether to add headings to the generated usage message. Headings will come from
the sections selected. Default is true.

=head2 colors

Hash ref mapping highlight names to colours, given as strings to pass to
L<Term::ANSIColor>. Default looks like this:

    colours   => {
        flag          => ['yellow'],
        heading       => ['bold'],
        command       => ['green'],
        type          => ['magenta'],
        default_value => ['cyan'],
        error         => ['red']
    }

=head2 usage_sections

When generating a usage message the POD sections to select. Default is SYNOPSIS
and OPTIONS sections (which will be auto generated from meta if they don't
exist).
Value is an array ref of L<Pod::Select/SECTION SPECIFICATIONS> strings.

Headings will be displayed, titled cased with a colon on the end. Use the
L</headings> option to hide the headings. Order displayed will be the same as
the POD.

You can use this to expand the usage message. e.g. you might also want the
DESCRIPTION and EXAMPLE from your POD in the usage message:

 usage_sections => ['SYNOPSIS|USAGE|DESCRIPTION|EXAMPLES']

=head2 man_sections

When generating a man page the POD sections to select. Default is everything
except ATTRIBUTES and METHODS (as we will generate an OPTIONS section instead
of ATTRIBUTES and METHODS isn't relevant to command line users).
Value is an array ref of L<Pod::Select/SECTION SPECIFICATIONS> strings.

Use an empty array to include all POD sections.

 man_sections => [],

e.g. to exclude TODO, keeping the default excludes you could do:

 man_sections => ["!ATTRIBUTES|METHODS","!TODO"],

or maybe you only want the NAME and DESCRIPTION (along with the generated
SYNOPSIS and OPTIONS):

 man_sections => ["NAME|DESCRIPTION"],

=head2 use_color

Whether to use color in the usage message. One of 'auto', 'never', 'always' or
'env'. Auto will use color if the output is a tty, otherwise not. 'env' looks
at the ANSI_COLORS_DISABLED environment variable (see L<Term::ANSIColor>). Note
that the env is also read in auto mode.

=head2 unexpand

Set C<$Text::Wrap::unexpand>, see L<Text::Wrap/OVERRIDES>.

=head2 tabstop

Set C<$Text::Wrap::tabstop>, see L<Text::Wrap/OVERRIDES>.

=head2 auto_man

Defaults to true. Display usage when --help option is given. Set false to
disable this, allowing you to do your own processing after new_with_options
then probably call L<getopt_usage> yourself.

=head2 auto_help

Defaults to true. Display man page when --man option is given. Set false to
disable this, allowing you to do your own processing after new_with_options
then probably call C<< getopt_usage( man => 1,.. ) >> yourself.

=head1 POD GENERATION

Both the usage message and man page are generated by selecting sections
(headings) from your modules POD documentation. It will auto generate both
SYNOPSIS (usage) and OPTIONS sections if they do not exist, which means you
still get a nice usage message (and basic man page) with no POD.

The SYNOPSIS, if not present, will just contain the default L</format> message
and is inserted after NAME or at the start of the POD.
If present it is used as is, still getting %c etc substituted.

OPTIONS will generate a list of the options by examining your classes
attributes. The section is inserted after DESCRIPTION or at the end of the
file.  If an OPTIONS section already exists the list of options will be
appended to it, allowing you to add some extra documentation above the options.

All section selecting options are applied after POD generation so can be used
to hide as well as include generated sections.

=head1 EXAMPLES

=head2 Expanding the usage message. 

This adds the DESCRIPTION from the POD to the usage and changes the usage
message to show it takes files.

Put this is a file called descusage.pl and make it executable.

 #!/usr/bin/perl
 package Foo;
 
 use Moose;
 with 'MooseX::Getopt::Usage';
 with 'MooseX::Getopt::Usage::Role::Man';
 
 sub getopt_usage_config {
     return ( usage_sections => ["SYNOPSIS|OPTIONS|DESCRIPTION"] );
 }
 
 =pod
 
 =head1 SYNOPSIS
 
  %c [OPTIONS] FILES 
 
 =head1 DESCRIPTION
 
 Does amazing things with FILES.
 
 =cut
 
 package main;
 Foo->new_with_options;

Then call to get usage:

 $ descusage.pl -h
 Usage:
      descusage.pl [OPTIONS] FILES
 
 Description:
     Does amazing things with FILES.
 
 Options:
      --help -? --usage - Bool. Display the usage message and exit
      --man             - Bool. Display man page

Not that the OPTIONS section gets automatically generated for us but we still
need to select it in the usage_sections option if we want to see it.

=head2 Adding Options

Put this is a file called hello.pl and make it executable.

 #!/usr/bin/env perl
 package Hello;
 use 5.010;
 use Moose;

 with 'MooseX::Getopt::Usage';
 with 'MooseX::Getopt::Usage::Role::Man';

 has verbose => ( is => 'ro', isa => 'Bool',
     documentation => qq{Say lots about what we do} );

 has greet => ( is => 'ro', isa => 'Str', default => "World",
     documentation => qq{Who to say hello to.} );

 has times => ( is => 'rw', isa => 'Int', required => 1,
     documentation => qq{How many times to say hello} );

 sub run {
     my $self = shift;
     say "Printing message..." if $self->verbose;
     say "Hello " . $self->greet for (1..$self->times);
 }

 package main;
 Hello->new_with_options->run;

Then call with any of these to get usage output.

 $ ./hello.pl -?
 $ ./hello.pl --help
 $ ./hello.pl --usage

Which will look a bit like this, only in colour.

 Usage:
     hello.pl [OPTIONS]
 
 Options:
      Required:
          --times           - Int. How many times to say hello
      Optional:
          --help -? --usage - Bool. Display the usage message and exit
          --verbose         - Bool. Say lots about what we do
          --greet           - Str. Default=World. Who to say hello to.

=head2 Sharing config

You may find that you want to have a common set of config (ie
L</getopt_usage_config> return) shared by a number of command classes. You could
do this with a common base class or as this is Moose do it with a role.

First create the role class to hold the common config:

    package CommonGetoptConfig;
    use Moose::Role;

    around getopt_usage_config => sub {
        my $orig  = shift;
        my $class = shift;
        return (
            attr_sort => sub { $_[0]->name cmp $_[1]->name },
            format => "Usage: %c [OPTIONS]",
            headings => 0,
            $class->$orig(@_),
        );
    };

    1;

Then in you comand class consume that role:

    #!/usr/bin/env perl
    package Hello;
    use Moose;
   
    with 'MooseX::Getopt::Usage';
    with 'CommonGetoptConfig';
   
    #...

Note that if the consuming class also impliments getopt_usage_config then
the configs will be combined, with config from the class overriding that from
the role. You can change this order by moving the C<< $class->$orig(@_), >> in
the return in the role above.


=head1 SEE ALSO

L<perl>, L<Moose>, L<MooseX::Getopt>, L<Term::ANSIColor>, L<Text::Wrap>,
L<Pod::Usage>.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no exception.
Please report any bugs or feature requests via the github page at:

L<http://github.com/markpitchless/moosex-getopt-usage>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MooseX::Getopt::Usage

The source code and other information is hosted on github:

L<http://github.com/markpitchless/moosex-getopt-usage>

=head1 AUTHOR

Mark Pitchless, C<< <markpitchless at gmail.com> >>

=head1 ACKNOWLEDGEMENTS

Wayne Marquette for bug finding and pushing the use cases.

ilmari+cpan@ilmari.org for patching file based tests.

Tomas Doran for discussions and ideas that lead to all the pod mangling
goodness and the big refactor at version 0.09.

skazakoff for Moose bug fixes.

=head1 COPYRIGHT & LICENSE

Copyright 2012 Mark Pitchless

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
