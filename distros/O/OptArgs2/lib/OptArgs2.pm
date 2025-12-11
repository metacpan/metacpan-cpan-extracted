package OptArgs2;
use strict;
use warnings;
use Encode::Locale 'decode_argv';
use OptArgs2::Cmd;
use Exporter::Tidy
  default => [qw/class_optargs cmd optargs subcmd arg opt/],
  other   => [qw/usage cols rows/];

our $VERSION  = 'v2.0.17';
our @CARP_NOT = (
    qw/
      OptArgs2
      OptArgs2::Arg
      OptArgs2::Cmd
      OptArgs2::CmdBase
      OptArgs2::Opt
      OptArgs2::OptArgBase
      OptArgs2::SubCmd
      /
);

# constants
sub USAGE_USAGE()       { 'Usage' }         # default
sub USAGE_HELP()        { 'Help' }
sub USAGE_HELPTREE()    { 'HelpTree' }
sub USAGE_HELPSUMMARY() { 'HelpSummary' }

our $CURRENT;                               # legacy interface
my %COMMAND;
my @chars;

sub _chars {
    if ( $^O eq 'MSWin32' ) {
        require Win32::Console;
        @chars = Win32::Console->new()->Size();
    }
    else {
        require Term::Size::Perl;
        @chars = Term::Size::Perl::chars();
    }
    \@chars;
}

sub cols {
    $chars[0] // _chars()->[0];
}

sub rows {
    $chars[1] // _chars()->[1];
}

sub die_paged {
    my $err = shift // 'die_paged($ERR)';
    if ( -t STDERR ) {
        my $lines = scalar( split /\n/, $err );
        $lines++ if $err =~ m/\n\z/;

        if ( $lines >= OptArgs2::rows() ) {
            require OptArgs2::Pager;
            my $pager = OptArgs2::Pager->new( auto => 0 );
            local *STDERR = $pager->fh;
            die $err;
        }
    }

    die $err;
}

my %error_types = (
    CmdExists         => undef,
    CmdNotFound       => undef,
    Conflict          => undef,
    DuplicateAlias    => undef,
    InvalidIsa        => undef,
    ParentCmdNotFound => undef,
    SubCmdExists      => undef,
    UndefOptArg       => undef,
    Usage             => undef,
);

package OptArgs2::Status {
    use overload
      bool     => sub { 1 },
      '""'     => sub { ${ $_[0] } },
      fallback => 1;
}

sub croak {
    require Carp;
    my $type = shift // Carp::croak( 'Usage', 'croak($TYPE, [$msg])' );
    my $pkg  = 'OptArgs2::Error::' . $type;
    my $msg  = shift // "($pkg)";
    $msg = sprintf( $msg, @_ ) if @_;

    Carp::croak( 'Usage', "unknown error type: $type" )
      unless exists $error_types{$type};

    $msg .= ' ' . Carp::longmess('');

    no strict 'refs';
    *{ $pkg . '::ISA' } = ['OptArgs2::Status'];

    die_paged( bless \$msg, $pkg );
}

sub class_optargs {
    my $class = shift
      || croak( 'Usage', 'class_optargs($CMD,[@argv])' );

    my $cmd = $COMMAND{$class}
      || croak( 'CmdNotFound', 'command class not found: ' . $class );

    my @source = @_;

    if ( !@_ and @ARGV ) {
        decode_argv(Encode::FB_CROAK);
        @source = @ARGV;
    }

    $cmd->parse(@source);
}

sub cmd {
    my $class = shift || croak( 'Usage', 'cmd($CLASS,@args)' );

    croak( 'CmdExists', "command already defined: $class" )
      if exists $COMMAND{$class};

    $COMMAND{$class} = OptArgs2::Cmd->new( class => $class, @_ );
}

sub optargs {
    my $class = caller;

    if ( !@_ and exists $COMMAND{$class} ) {    # Legacy interface
        return ( class_optargs($class) )[1];
    }

    delete $COMMAND{$class};
    cmd( $class, @_ );
    ( class_optargs($class) )[1];
}

sub subcmd {
    my $class = shift || croak( 'Usage', 'subcmd($CLASS,%%args)' );

    croak( 'SubCmdExists', "subcommand already defined: $class" )
      if exists $COMMAND{$class};

    croak( 'ParentCmdNotFound',
        "no '::' in class '$class' - must have a parent" )
      unless $class =~ m/(.+)::(.+)/;

    my $parent_class = $1;

    croak( 'ParentCmdNotFound', "parent class not found: " . $parent_class )
      unless exists $COMMAND{$parent_class};

    $COMMAND{$class} = $COMMAND{$parent_class}->add_cmd(
        class => $class,
        @_
    );
}

sub usage {
    my $class = shift || do {
        my ($pkg) = caller;
        $pkg;
    };
    my $style = shift;

    croak( 'CmdNotFound', "command not found: $class" )
      unless exists $COMMAND{$class};

    return $COMMAND{$class}->usage_string($style);
}

# Legacy interface, no longer documented

sub arg {
    my $name  = shift;
    my $class = scalar caller;

    $OptArgs2::CURRENT //= cmd( $class, comment => '' );
    $OptArgs2::CURRENT->add_arg(
        name => $name,
        @_,
    );

}

sub opt {
    my $name  = shift;
    my $class = scalar caller;

    $OptArgs2::CURRENT //= cmd( $class, comment => '' );
    $OptArgs2::CURRENT->add_opt(
        name => $name,
        @_,
    );
}

1;

__END__

=head1 NAME

OptArgs2 - command-line argument and option processor

=head1 VERSION

v2.0.17 (2025-12-11)

=head1 SYNOPSIS

    #!/usr/bin/env perl
    use OptArgs2;

For simple scripts use optargs():

    my $args = optargs(
        comment => 'script to paint things',
        optargs => [
            item => {
                isa      => 'Str',
                required => 1,
                comment  => 'the item to paint',
            },
            quiet => {
                isa     => '--Flag',
                alias   => 'q',
                comment => 'output nothing while working',
            },
        ],
    );

    print "Painting $args->{item}\n" unless $args->{quiet};

For complex multi-command applications use cmd(), subcmd() and
class_optargs():

    cmd 'My::app' => (
        comment => 'handy work app',
        optargs => [
            command => {
                isa      => 'SubCmd',
                required => 1,
                comment  => 'the action to take',
            },
            quiet => {
                isa     => '--Flag',
                alias   => 'q',
                comment => 'output nothing while working',
            },
        ],
    );

    subcmd 'My::app::prepare' => (
        comment => 'prepare something',
        optargs => [
            item => {
                isa      => 'Str',
                required => 1,
                comment  => 'the item to prepare',
            },
        ],
    );

    subcmd 'My::app::paint' => (
        comment => 'paint something',
        optargs => [
            item => {
                isa      => 'Str',
                required => 1,
                comment  => 'the item to paint',
            },
            my_colour => {
                isa     => '--Str',
                alias   => 'c',
                comment => 'your faviourite',
                default => 'blue',
            },
        ],
    );

    my ( $class, $opts, $file ) = class_optargs('My::app');
    require $file;
    $class->new($opts);

=head1 DESCRIPTION

B<OptArgs2> processes command line arguments, options, and subcommands
according to the following definitions:

=over

=item Command

A program run from the command line to perform a task.

=item Arguments

Arguments are positional parameters that pass information to a command.
Arguments can be optional, but they should not be confused with Options
below.

=item Options

Options are non-positional parameters that pass information to a
command.  They are generally not required to be present (hence the name
Option) but that is configurable. All options have a long form prefixed
by '--', and may have a single letter alias prefixed by '-'.

=item Subcommands

From the users point of view a subcommand is a special argument with
its own set of arguments and options.  However from a code authoring
perspective subcommands are often implemented as stand-alone programs,
called from the main script when the appropriate command arguments are
given.

=back

=head2 Differences with Earlier Releases

B<OptArgs2> version 2.0.0 was a large re-write to improve the API and
code.  Users upgrading from version 0.0.11 or B<OptArgs> need to be
aware of the following:

=over

=item API changes: optargs(), cmd(), subcmd()

Commands and subcommands are now explicitly defined using C<optargs()>,
C<cmd()> and C<subcmd()>. The arguments to C<optargs()> have changed to
match C<cmd()>.

=item Deprecated: arg(), opt(), fallback arguments

Optargs definitions must now be defined in an array reference
containing key/value pairs as shown in the synopsis. Fallback arguments
have been replaced with a new C<fallthru> option.

=item class_optargs() no longer loads the class

Users must specifically require the class if they want to use it
afterwards.

=item Bool options with no default display as "--[no-]bool"

A Bool option without a default is now displayed with the "[no-]"
prefix. What this means in practise is that many of your existing Bool
options most likely would become Flag options instead.

=back

This module used to duplicate itself on CPAN as L<Getopt::Args2>, but
as of the version 2 series that is no longer the case.

=head2 Simple Commands

To demonstrate the simple use case (i.e. with no subcommands) lets put
the code from the synopsis in a file called C<paint> and observe the
following interactions from the shell:

    $ ./paint
    usage: paint ITEM [OPTIONS...]

      Synopsis:
        script to paint things

      Arguments:
        ITEM            (Str)   the item to paint *required*

      Options:
        --help,      -h         print a Help message and exit
        --quiet,     -q         output nothing while working

The C<optargs()> function parses the command line (C<@ARGV>) according
to the included declarations and returns a single HASH reference.  If
the command is not called correctly then an exception is thrown
containing an automatically generated usage message as shown above.

Because B<OptArgs2> fully knows the valid arguments and options it can
detect a wide range of errors:

    $ ./paint wall Perl is great
    error: unexpected option or argument: Perl

So let's add that missing argument definition inside the optargs ref

    optargs => [
        ...
        message => {
            isa      => 'Str',
            comment  => 'the message to paint on the item',
            greedy   => 1,
        },
    ],

And then check the usage again:

    $ ./paint
    usage: paint ITEM [MESSAGE...] [OPTIONS...]

      Synopsis:
        script to paint things

      Arguments:
        ITEM            (Str)   the item to paint *required*
        MESSAGE         (Str)   the message to paint on the item

      Options:
        --help,      -h         print a Help message and exit
        --quiet,     -q         output nothing while working

Note that optional arguments are surrounded by square brackets, and
that three dots (...) are postfixed to greedy arguments. A greedy
argument will swallow whatever is left on the comand line:

    $ ./paint wall Perl is great
    Painting on wall: "Perl is great".

Note that it probably doesn't make sense to define any more arguments
once you have a greedy argument. Let's imagine you now want the user to
be able to choose the colour if they don't like the default. An option
might make sense here, specified by a leading '--' type:

    optargs => [
        ...
        my_colour => {
            isa           => '--Str',
            default       => 'blue',
            comment       => 'the colour to use',
        },
    ],

This now produces the following usage output:

    usage: paint ITEM [MESSAGE...] [OPTIONS...]

      Synopsis:
        script to paint things

      Arguments:
        ITEM            (Str)   the item to paint *required*
        MESSAGE         (Str)   the message to paint on the item

      Options:
        --help,      -h         print a Help message and exit
        --my-colour, -c [blue]  the colour to paint
        --quiet,     -q         output nothing while working

=head2 Multi-Level Commands

Commands with subcommands require a different coding model and syntax
which we will describe over three phases:

=over

=item Definitions

Your command structure is defined using calls to the C<cmd()> and
C<subcmd()> functions. The first argument to both functions is the name
of the Perl class that implements the (sub-)command.

    cmd 'App::demo' => (
        comment => 'the demo command',
        optargs => [
            command => {
                isa      => 'SubCmd',
                required => 1,
                comment  => 'command to run',
            },
            quiet => {
                isa     => '--Flag',
                alias   => 'q',
                comment => 'run quietly',
            },
        ],
    );

    subcmd 'App::demo::foo' => (
        comment => 'demo foo',
        optargs => [
            action => {
                isa      => 'Str',
                required => 1,
                comment  => 'command to run',
            },
        ],
    );

    subcmd 'App::demo::bar' => (
        comment => 'demo bar',
        optargs => [
            baz => {
                isa => '--Counter',
                comment => '+1',
            },
        ],
    );

The command hierarchy for the above code is displayed when help is
asked for twice:

    $ demo -h -h
    demo COMMAND [OPTIONS...]
        demo foo ACTION [OPTIONS...]
        demo bar [OPTIONS...]

An argument of type 'SubCmd' is an explicit indication that subcommands
can occur in that position. The command hierarchy is based upon the
natural parent/child structure of the class names.  This definition can
be done in your main script, or in one or more separate packages or
plugins, as you like.

=item Parsing

The C<class_optargs()> function is called to parse the C<@ARGV> array
and call the appropriate C<arg()> and C<opt()> definitions as needed.
It's first argument is generally the top-level command name you used in
your first C<cmd()> call.

    my ($class, $opts, $file) = class_optargs('App::demo');
    require $file;
    printf "Running %s with %s\n", $class, Dumper($opts)
      unless $opts->{quiet};

The additional return value C<$class> is the name of the actual
(sub-)command to which the C<$opts> HASHref applies. Usage exceptions
are raised just the same as with the C<optargs()> function.

    error: unknown option "--invalid"

    usage: demo COMMAND [OPTIONS...]

      Command:      command to run *required*
        bar         demo bar
        foo ACTION  demo foo

      Options:
        --help,  -h   print a Help message and exit
        --quiet, -q   run quietly

Note that options are inherited by subcommands.

=item Dispatch/Execution

Once you have the subcommand name and the option/argument hashref you
can either execute the action or dispatch to the appropriate
class/package as you like.

There are probably several ways to layout command classes when you have
lots of subcommands. Here is one way that seems to work for this
module's author.

=over

=item lib/App/demo.pm, lib/App/demo/subcmd.pm

I typically put the actual (sub-)command implementations in
F<lib/App/demo.pm> and F<lib/App/demo/subcmd.pm>. App::demo itself only
needs to exists if the root command does something. However I tend to
also make App::demo the base class for all subcommands so it is often a
non-trivial piece of code.

=item lib/App/demo/OptArgs.pm

App::demo::OptArgs is where I put all of my command definitions with
names that match the actual implementation modules.

    package App::demo::OptArgs;
    use OptArgs2;

    cmd 'App::demo' => {
        comment => 'the demo app',
        optargs => [
            # arg => 'Type, ...
            # opt => '--Type, ...
        ],
    }

My reason for keeping this separate from lib/App/demo.pm is speed.  I
don't want users to wait while loading all modules that App::demo
itself uses, just to find out that the command was called incorrectly.

=item bin/demo

The command script itself is then usually fairly short:

    #!/usr/bin/env perl
    use OptArgs2 'class_optargs';
    use App::demo::OptArgs;

    my ($class, $opts, $file) = class_optargs('App::demo');
    require $file;
    $class->new($opts)->run;

=back

=back

=head2 Argument Definition

Arguments are key/hashref pairs defined inside the optargs arrayref.

    optargs => [
        file_name => {
            isa      => 'Str',
            comment  => 'the file to parse',
            default  => '-',
            greedy   => 0,
            # required => 0 | 1,
            # fallthru => 0 | 1,
        },
    ],

Any underscores in the name (i.e. the optargs "key") are kept for
presentation, matching the C<$ENV_KEY> convention:

    usage: cmd [FILE_NAME] [OPTIONS...]

      Arguments:
        FILE_NAME           (Str)  the file to parse

The following argument parameters are accepted:

=over

=item comment

Required. Used to generate the usage/help message.

=item default

The value set when the argument is not given. Conflicts with the
'required' parameter.

If this is a subroutine reference it will be called with a hashref
containg all option/argument values after parsing the source has
finished.  The value to be set must be returned, and any changes to the
hashref are ignored.

=item greedy

If true the argument swallows the rest of the command line.

=item fallthru

Only relevant for SubCmd types. Normally, a "required" SubCmd will
raise an error when the given argument doesn't match any subcommand.
However, when fallthru is true the non-subcommand-matching argument
will be passed back to the C<class_optargs()> caller.

This is typically useful when you have aliases that you can expand into
real subcommands.

=item isa

Required. Is mapped to a L<Getopt::Long> type according to the
following table:

     optargs         Getopt::Long
    ------------------------------
     'Str'           '=s'
     'Int'           '=i'
     'Input'         '=s'
     'Num'           '=f'
     'ArrayRef'      's@'
     'HashRef'       's%'
     'SubCmd'        '=s'

The C<Input> type is for automatically reading the contents of a file
into the optargs result. When the argument is '-' then the result comes
from C<STDIN>.

=item isa_name

When provided this parameter will be presented instead of the generic
presentation for the 'isa' parameter.

=item required

Set to a true value when the caller must specify this argument.
Conflicts with the 'default' parameter.

=item show_default

Boolean to indicate if the default value should be shown in usage
messages. Overrides the (sub-)command's C<show_default> setting.

=back

=head2 Option Definition

Options are defined inside the optargs arrayref, similarly to
arguments. The key difference is the leading "--" for the "isa"
parameter:

    optargs => [
        my_colour => {
            isa          => '--Str',
            alias        => 'c',
            comment      => 'the colour to paint',
            default      => 'blue',
            show_default => 1,
        },
    ],

Any underscores in the option name are replaced by dashes (-) for
presentation, but both C<--my_colour> and C<--my-colour> are accepted.

The following construction parameters are valid:

=over

=item alias

A single character alias.

=item comment

Required. Used to generate the usage/help message.

=item default

The value set when the option is not given. Conflicts with the
'required' parameter.

If this is a subroutine reference it will be called with a hashref
containing all option/argument values after parsing the source has
finished.  The value to be set must be returned, and any changes to the
hashref are ignored.

=item required

Set to a true value when the caller must specify this option. Conflicts
with the 'default' parameter.

=item hidden

When true this option will not appear in usage messages unless the
usage message is a help request.

This is handy if you have developer-only options, or options that are
very rarely used that you don't want cluttering up your normal usage
message.

=item isa

Required. Is mapped to a L<Getopt::Long> type according to the
following table:

    isa                             Getopt::Long
    ---                             ------------
     '--ArrayRef'                     's@'
     '--Flag'                         '!'
     '--Bool'                         '!'
     '--Counter'                      '+'
     '--HashRef'                      's%'
     '--Int'                          '=i'
     '--Input'                        '=s'
     '--Num'                          '=f'
     '--Str'                          '=s'

The C<Input> type is for automatically placing the contents of a file
into the optargs result. When the argument '-' is provided then the
result comes from C<STDIN>.

=item isa_name

When provided this parameter will be presented instead of the generic
presentation for the 'isa' parameter.

=item show_default

Boolean to indicate if the default value should be shown in usage
messages. Overrides the (sub-)command's C<show_default> setting.

=item trigger

The trigger parameter lets you define a subroutine that is called after
processing before usage exceptions are raised.  This is primarily to
support --help or --version options which would typically override
usage errors.

    optargs => [
        version => (
            isa     => '--Flag',
            alias   => 'V',
            comment => 'print version string and exit',
            trigger => sub {
                my ( $cmd, $value ) = @_;
                die "$cmd version $VERSION\n";
            }
        ),
    ],

The trigger subref is passed two parameters: a OptArgs2::Cmd object and
the value (if any) of the option. The OptArgs2::Cmd object is an
internal one.

=back

=head2 Formatting of Usage Messages

Usage messages attempt to present as much information as possible to
the caller. Here is a brief overview of how the various types look
and/or change depending on things like defaults.

The presentation of Bool options in usage messages is as follows:

    Name        Type        Default         Presentation
    ----        ----        -------         ------------
    option      Bool        undef           --[no-]option
    option      Bool        true            --no-option
    option      Bool        false           --option
    option      Counter     *               --option

The Flag option type is like a Bool that can only be set to true or
left undefined. This makes sense for things such as C<--help> or
C<--version> for which you never need to see a "--no" prefix.

    Name        Type        Default         Presentation
    ----        ----        -------         ------------
    option      Flag        always undef    --option

Note that Flags also makes sense for "negative" options which will only
ever turn things off:

    Name        Type        Default         Presentation
    ----        ----        -------         ------------
    no_option   Flag        always undef    --no-option

    # In Perl
    no_foo => {
        isa     => '--Flag',
        comment => 'disable the foo feature',
    }

    # Then later do { } unless $opts->{no_foo}

The remaining types are presented as follows:

    Name        Type        isa_name        Presentation
    ----        ----        --------        ------------
    option      ArrayRef    -               --option Str
    option      HashRef     -               --option Str
    option      Int         -               --option Int
    option      Input       -               --option Str
    option      Num         -               --option Num
    option      Str         -               --option Str
    option      *           XX              --option XX

Defaults TO BE COMPLETED.

=head1 FUNCTIONS

The following functions are exported by default.

=over

=item class_optargs( $class, [ @list ] ) -> ($subclass, $opts, $file)

Parse @ARGV by default (or @list when given) for the arguments and
options defined for command C<$class>.  C<@ARGV> will first be decoded
using L<Encode::Locale>.

Returns the following values:

=over

=item $subclass

The actual subcommand name that was matched by parsing the arguments.
This may be the same as C<$class>.

=item $opts

a hashref containing combined key/value pairs for options and
arguments.

=item $require_file

A file fragment (matching C<$subclass>) suitable for passing to
C<require>.

=back

Throws an error / usage exception object (typically
C<OptArgs2::Usage::*>) for missing or invalid arguments/options. Uses
L<OptArgs2::Pager> for Help output.

As an aid for testing, if the passed in argument C<@list> contains a
HASH reference, the key/value combinations of the hash will be added as
options. An undefined value is taken to mean a boolean option.

=item cols() -> Integer

Returns the terminal column width. Only exported on request.

=item cmd( $class, %parameters ) -> OptArgs2::Cmd

Define a top-level command identified by C<$class> which is typically a
Perl package name. The following parameters are accepted:

=for comment
=item name
A display name of the command. Optional - if it is not provided then the
last part of the command name is used is usage messages.

=over

=item abbrev

When set to true then subcommands can be abbreviated, up to their
shortest, unique values.

=item comment

A description of the command. Required.

=item optargs

An arrayref containing argument and option definitions. Note that
options are inherited by subcommands so you don't need to define them
again in child subcommands.

=item no_help

By default C<cmd()> automatically adds a default '--help' option. When
used once a standard help message is displayed. When used twice a help
tree showing subcommands is displayed. To disable the automatic help
set C<no_help> to a true value.

=item show_color

Boolean indicating if usage messages should use ANSI terminal colour
codes to highlight different elements. True by default.

=item show_default

Boolean indicating if default values for options and arguments should
be shown in usage messages. Can be overriden by sub-commands, args and
opts. Off by default.

=for comment
By default this subref is only called on demand when the
C<class_optargs()> function sees arguments for that particular
subcommand. However for testing it is useful to know immediately if you
have an error. For this purpose the OPTARGS2_IMMEDIATE environment
variable can be set to trigger it at definition time.

=for comment
=item colour
If $OptArgs::COLOUR is a true value and "STDOUT" is connected to a
terminal then usage and error messages will be colourized using
terminal escape codes.

=for comment
=item sort
If $OptArgs::SORT is a true value then subcommands will be listed in
usage messages alphabetically instead of in the order they were
defined.

=for comment
=item usage
Valid for C<cmd()> only. A subref for generating a custom usage
message. See XXX befow for the structure this subref receives.

=back

=item optargs( @cmd_optargs ) -> HASHref

This is a convenience function for single-level commands that:

=over

=item * passes it's arguments directly to C<cmd()>,

=item * calls C<class_optargs()> to parse '@ARGV' and returns the
C<$opts> HASHref result directly.

=back

=item rows() -> Integer

Returns the terminal row height. Only exported on request.

=item subcmd( $subclass, %parameters ) -> OptArgs2::Cmd

Defines the subcommand C<$subclass> of a previously defined
(sub-)command.

Accepts the same parameters as C<cmd()> in addition to the following:

=over

=item hidden

Hide the existence of this subcommand in non-help usage messages.  This
is handy if you have developer-only or rarely-used commands that you
don't want cluttering up your normal usage message.

=back

=item usage( [$class] ) -> Str

Only exported on request, this function returns the usage string for
the command C<$class> or the class of the calling package (.e.g
"main").

=back

=head1 SEE ALSO

L<Getopt::Long>, L<Encode::Locale>, L<OptArgs2::Pager>,
L<OptArgs2::StatusLine>

=head1 SUPPORT & DEVELOPMENT

This distribution is managed via github:

    https://github.com/mlawren/p5-OptArgs/

This distribution follows the semantic versioning model:

    http://semver.org/

Code is tidied up on Git commit using githook-perltidy:

    http://github.com/mlawren/githook-perltidy

=head1 AUTHOR

Mark Lawrence <mark@rekudos.net>

=head1 LICENSE

Copyright 2016-2025 Mark Lawrence <mark@rekudos.net>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.

