# ============================================================================«
package MooseX::App;
# ============================================================================«

use 5.010;
use utf8;
use strict;
use warnings;

our $AUTHORITY = 'cpan:MAROS';
our $VERSION = 1.37_01;

use MooseX::App::Meta::Role::Attribute::Option;
use MooseX::App::Exporter qw(app_usage app_description app_base app_fuzzy app_strict app_prefer_commandline app_permute option parameter);
use MooseX::App::Message::Envelope;
use Moose::Exporter;
use Scalar::Util qw(blessed);

my ($IMPORT,$UNIMPORT,$INIT_META) = Moose::Exporter->build_import_methods(
    with_meta           => [ qw(app_usage app_description app_namespace app_exclude app_base app_fuzzy app_command_name app_command_register app_strict app_prefer_commandline option parameter app_permute) ],
    also                => [ 'Moose' ],
    as_is               => [ 'new_with_command' ],
    install             => [ 'unimport','init_meta' ],
);

sub import {
    my ( $class, @plugins ) = @_;

    # Get caller
    my ($caller_class) = caller();

    # Process plugins
    MooseX::App::Exporter->process_plugins($caller_class,@plugins);

    # Call Moose-Exporter generated importer
    return $class->$IMPORT( { into => $caller_class } );
}

sub init_meta {
    my ($class,%args) = @_;

    # Get required roles and metaroles
    $args{roles}        = ['MooseX::App::Role::Base'];
    $args{metaroles}    = {
        class               => [
            'MooseX::App::Meta::Role::Class::Base',
            'MooseX::App::Meta::Role::Class::Documentation'
        ],
        attribute           => [
            'MooseX::App::Meta::Role::Attribute::Option'
        ],
    };

    return MooseX::App::Exporter->process_init_meta(%args);
}

sub app_command_name(&) {
    my ( $meta, $namesub ) = @_;
    return $meta->app_command_name($namesub);
}

sub app_command_register(%) {
    my ( $meta, %commands ) = @_;

    foreach my $command (keys %commands) {
        $meta->command_register($command,$commands{$command});
    }
    return;
}

sub app_namespace(@) {
    my ( $meta, @namespaces ) = @_;
    return $meta->app_namespace( \@namespaces );
}

sub app_exclude(@) {
    my ( $meta, @namespaces ) = @_;
    return $meta->app_exclude( \@namespaces );
}

sub new_with_command {
    my ($class,@args) = @_;

    Moose->throw_error('new_with_command is a class method')
        if ! defined $class || blessed($class);

    my $meta        = $class->meta;
    my $metameta    = $meta->meta;

    # Sanity check
    Moose->throw_error('new_with_command may only be called from the application base package:'.$class)
        if $metameta->does_role('MooseX::App::Meta::Role::Class::Command')
        || ! $metameta->does_role('MooseX::App::Meta::Role::Class::Base');

    $meta->command_check()
        if $ENV{APP_DEVELOPER} || $ENV{HARNESS_ACTIVE};

    # Extra args
    my %args;
    if (scalar @args == 1
        && ref($args[0]) eq 'HASH' ) {
        %args = %{$args[0]};
    } elsif (scalar @args % 2 == 0) {
        %args = @args;
    } else {
        Moose->throw_error('new_with_command got invalid extra arguments');
    }

    # Get ARGV
    my $argv = delete $args{ARGV};
    my $parsed_argv;
    if (defined $argv) {
        $parsed_argv = MooseX::App::ParsedArgv->new( argv => $argv );
    } else {
        $parsed_argv = MooseX::App::ParsedArgv->instance();
    }

    my $first_argv  = $parsed_argv->first_argv;

    # Requested help
    if (defined $first_argv
        && lc($first_argv) =~ m/^(help|h|\?|usage|-h|--help|-\?|--usage)$/) {
        return MooseX::App::Message::Envelope->new(
            $meta->command_usage_global(),
        );
    # No args
    } elsif (! defined $first_argv
        || $first_argv =~ m/^\s*$/
        || $first_argv =~ m/^-{1,2}\w/) {
        return MooseX::App::Message::Envelope->new(
            $meta->command_message(
                header          => "Missing command", # LOCALIZE
                type            => "error",
            ),
            $meta->command_usage_global(),
            127, # exitcode
        );
    # Looks like a command
    } else {
        my $return = $meta->command_find();

        # Nothing found
        if (blessed $return
            && $return->isa('MooseX::App::Message::Block')) {
            return MooseX::App::Message::Envelope->new(
                $return,
                $meta->command_usage_global(),
                127, # exitcode
            );
        # One command found
        } else {
            my $command_class = $meta->command_get($return);
            return $class->initialize_command_class($command_class,%args);
        }
    }
}


no Moose;
1;

__END__

=encoding utf8

=head1 NAME

MooseX::App - Write user-friendly command line apps with even less suffering

=head1 SYNOPSIS

In your base class:

  package MyApp;
  use MooseX::App qw(Color);
 
  option 'global_option' => (
      is            => 'rw',
      isa           => 'Bool',
      documentation => q[Enable this to do fancy stuff],
  ); # Global option
  
  has 'private' => (
      is              => 'rw',
  ); # not exposed

Write multiple command classes (If you have only a single command class
you should use L<MooseX::App::Simple> instead). Packackes in the namespace may be
deeply nested.

  package MyApp::SomeCommand;
  use MooseX::App::Command; # important (also imports Moose)
  extends qw(MyApp); # optional, only if you want to use global options from base class
  
  # Positional parameter
  parameter 'some_parameter' => (
      is            => 'rw',
      isa           => 'Str',
      required      => 1,
      documentation => q[Some parameter that you need to supply],
  );
  
  option 'some_option' => (
      is            => 'rw',
      isa           => 'Int',
      required      => 1,
      documentation => q[Very important option!],
  ); # Option
  
  sub run {
      my ($self) = @_;
      # Do something
  }

And then you need a simple wrapper script (called eg. myapp):

 #!/usr/bin/env perl
 use MyApp;
 MyApp->new_with_command->run;

On the command line:

 bash$ myapp help
 usage:
     myapp <command> [long options...]
     myapp help
 
 global options:
     --global_option    Enable this to do fancy stuff [Flag]
     --help --usage -?  Prints this usage information. [Flag]
 
 available commands:
     some_command    Description of some command
     another_command Description of another command
     help            Prints this usage information

or

 bash$ myapp some_command --help
 usage:
     myapp some_command <SOME_PARAMETER> [long options...]
     myapp help
     myapp some_command --help
 
 parameters:
     some_parameter     Some parameter that you need to supply [Required]
 
 options:
     --global_option    Enable this to do fancy stuff [Flag]
     --some_option      Very important option! [Int,Required]
     --help --usage -?  Prints this usage information. [Flag]

=head1 DESCRIPTION

MooseX-App is a highly customisable helper to write user-friendly
command line applications without having to worry about most of the annoying
things usually involved. Just take any existing L<Moose> class, add a single
line (C<use MooseX-App qw(PluginA PluginB ...);>) and create one class
for each command in an underlying namespace. Options and positional parameters
can be defined as simple L<Moose> accessors using the C<option> and
C<parameter> keywords respectively.

MooseX-App will then

=over

=item * Find, load and initialise the command classes (see
L<MooseX::App::Simple> for single class/command applications)

=item * Create automated help and documentation from modules POD as well as
attributes metadata and type constraints

=item * Read, encode and validate the command line options and positional
parameters entered by the user from @ARGV and %ENV (and possibly prompt
the user for additional parameters see L<MooseX::App::Plugin::Term>)

=item * Provide helpful error messages if user input cannot be validated
(either missing or wrong attributes or Moose type constraints not satisfied)
or if the user requests help.

=back

Commandline options are defined using the 'option' keyword which accepts
the same attributes as Moose' 'has' keyword.

  option 'some_option' => (
      is            => 'rw',
      isa           => 'Str',
  );

This is equivalent to

  has 'some_option' => (
      is            => 'rw',
      isa           => 'Str',
      traits        => ['AppOption'],   # Load extra metaclass
      cmd_type      => 'option',        # Set attribute type
  );

Single letter options are treated as flags and may be combined with eachother.

Positional parameters are defined with the 'parameter' keyword

  parameter 'some_option' => (
      is            => 'rw',
      isa           => 'Str',
  );

This is equivalent to

  has 'some_option' => (
      is            => 'rw',
      isa           => 'Str',
      traits        => ['AppOption'],
      cmd_type      => 'parameter',
  );

All keywords are imported by L<Moosex::App> (in the app base class) and
L<MooseX::App::Command> (in the command class) or L<MooseX::App::Simple>
(single class application).

Furthermore, all options and parameters can also be supplied via %ENV

  option 'some_option' => (
      is            => 'rw',
      isa           => 'Str',
      cmd_env       => 'SOME_OPTION', # sets the env key
  );

Moose type constraints help MooseX::App to construct helpful error messages
and parse @ARGV in a meaningful way. The following type constraints are
supported:

=over

=item * ArrayRef: Specify multiple values ('--opt value1 --opt value2',
also see L<app_permute> and L<cmd_split>)

=item * HashRef: Specify multiple key value pairs ('--opt key=value --opt
key2=value2', also see L<app_permute>)

=item * Enum: Display all possibilities

=item * Bool: Flags that do not require values

=item * Int, Num: Used for proper error messages

=back

Read the L<Tutorial|MooseX::App::Tutorial> for getting started with a simple
MooseX::App command line application.

=head1 METHODS

=head2 new_with_command

 my $myapp_command = MyApp->new_with_command();

This constructor reads the command line arguments and tries to create a
command class instance. If it fails it returns a
L<MooseX::App::Message::Envelope> object holding an error message.

You can pass a hash of default/fallback params to new_with_command

 my $obj = MyApp->new_with_command(%default);

Optionally you can pass a custom ARGV to this constructor

 my $obj = MyApp->new_with_command( ARGV => \@myARGV );

However, if you do so you must take care of propper @ARGV encoding yourself.

=head2 initialize_command_class

 my $obj = MyApp->initialize_command_class($command_name,%default);

Helper method to instantiate the command class for the given command.

=head1 GLOBAL OPTIONS

These options may be used to alter the default behaviour of MooseX-App.

=head2 app_base

 app_base 'my_script'; # Defaults to $0

Usually MooseX::App will take the name of the calling wrapper script to
construct the program name in various help messages. This name can
be changed via the app_base function.

=head2 app_fuzzy

 app_fuzzy 1; # default
 OR
 app_fuzzy 0;

Enables fuzzy matching of commands and attributes. Is turned on by default.

=head2 app_strict

 app_strict 0; # default
 OR
 app_strict 1;

If strict is enabled the program will terminate with an error message if
superfluous/unknown positional parameters are supplied. If disabled all
extra parameters will be copied to the L<extra_argv> attribute. Unknown
options (with leading dashes) will always yield an error message.

The command_strict config in the command classes allows one to set this option
individually for each command in the respective command class.

=head2 app_prefer_commandline

 app_prefer_commandline 0; # default
 or
 app_prefer_commandline 1;

Specifies if parameters/options supplied via @ARGV,%ENV should take precedence
over arguments passed directly to new_with_command.

=head2 app_namespace

 app_namespace 'MyApp::Commands', 'YourApp::MoreCommands';
 OR
 app_namespace();

Usually MooseX::App will take the package name of the base class as the
namespace for commands. This namespace can be changed and you can add
multiple extra namespaces.

If app_namespace is called with no arguments then autoloading of command
classes will be disabled entirely.

=head2 app_exclude

 app_exclude 'MyApp::Commands::Roles','MyApp::Commands::Utils';

A sub namespace included via app_namespace (or the default behaviour) can
be excluded using app_exclude.

=head2 app_command_name

 app_command_name {
     my ($package_short,$package_full) = @_;
     # munge package name;
     return $command_name;
 };

This coderef can be used to control how autoloaded package names should be
translated to command names. If this command returns nothing the respective
command class will be skipped and not loaded.

=head2 app_command_register

 app_command_register
    do      => 'MyApp::Commands::DoSomething',
    undo    => 'MyApp::Commands::UndoSomething';

This keyword can be used to register additional commands. Especially
useful in conjunction with app_namespace and disabled autoloading.

=head2 app_description

 app_description qq[Description text];

Set the app description text. If not set this information will be taken from
the Pod DESCRIPTION or OVERVIEW sections. (see command_description to set
usage per command)

=head2 app_usage

 app_usage qq[myapp --option ...];

Set a custom usage text. If not set this will be taken from the Pod SYNOPSIS
or USAGE section. If both sections are not available, the usage information
will be autogenerated. (see command_usage to set usage per command)

=head2 app_permute

 app_permute 0; # default
 OR
 app_permute 1;

Allows one to specify multiple values with one key. So instead of writing
C<--list element1 --list element2 --list element3> one might write
C<--list element1 element2 element3> for ArrayRef elements. HashRef elements
may be expressed as <--hash key=value key2=value2>.

=head1 GLOBAL ATTRIBUTES

All MooseX::App classes will have two extra attributes

=head2 extra_argv

Carries all parameters from @ARGV that were not consumed (only if app_strict
is turned off, otherwise superfluous parameters will raise an exception).

=head2 help_flag

Help flag that is set when help was requested.

=head1 ATTRIBUTE OPTIONS

Options and parameters accept extra attributes for customisation:

=over

=item * cmd_tags - Extra tags (as used by the help)

=item * cmd_flag - Override option/parameter name

=item * cmd_aliases - Additional option/parameter name aliases

=item * cmd_split - Split values into ArrayRefs on this token

=item * cmd_position - Specify option/parameter order in help

=item * cmd_env - Read options/parameters from %ENV

=item * cmd_count - Value of option equals to number of occurrences in @ARGV

=item * cmd_negate - Adds an option to negate boolean flags

=back

Refer to L<MooseX::App::Meta::Role::Attribute::Option> for detailed
documentation.

=head1 METADATA

MooseX::App will use your class metadata and POD to construct the commands and
helpful error- or usage-messages. These bits of information are utilised
and should be provided if possible:

=over

=item * Package names

=item * L<required> options for Moose attributes

=item * L<documentation> options for Moose attributes

=item * Moose type constraints (Bool, ArrayRef, HashRef, Int, Num, and Enum)

=item * Documentation set via app_description, app_usage,
command_short_description, command_long_description and command_usage

=item * POD (NAME, ABSTRACT, DESCRIPTION, USAGE, SYNOPSIS, OVERVIEW,
COPYRIGHT, LICENSE, COPYRIGHT AND LICENSE, AUTHOR and AUTHORS sections)

=item * Dzil ABSTRACT tag if no POD is available yet

=back

=head1 PLUGINS

The behaviour of MooseX-App can be customised with plugins. To load a
plugin just pass a list of plugin names after the C<use MooseX-App> statement.
(Attention: order sometimes matters)

 use MooseX::App qw(PluginA PluginB);

Currently the following plugins are shipped with MooseX::App

=over

=item * L<MooseX::App::Plugin::BashCompletion>

Adds a command that generates a bash completion script for your application.
See third party L<MooseX::App::Plugin::ZshCompletion> for Z shell completion.

=item * L<MooseX::App::Plugin::Color>

Colorful output for your MooseX::App applications.

=item * L<MooseX::App::Plugin::Config>

Config files for MooseX::App applications.

=item * L<MooseX::App::Plugin::ConfigHome>

Try to find config files in users home directory.

=item * L<MooseX::App::Plugin::Term>

Prompt user for options and parameters that were not provided via options or
params. Prompt offers basic editing capabilities and non-persistent history.

=item * L<MooseX::App::Plugin::Typo>

Handle typos in command names and provide suggestions.

=item * L<MooseX::App::Plugin::Version>

Adds a command to display the version and license of your application.

=item * L<MooseX::App::Plugin::Man>

Display full manpage of application and commands.

=item * L<MooseX::App::Plugin::MutexGroup>

Allow for mutally exclusive options.

=item * L<MooseX::App::Plugin::Depends>

Adds dependent options.

=back

Refer to L<Writing MooseX-App Plugins|MooseX::App::WritingPlugins>
for documentation on how to create your own plugins.

=head1 CAVEATS & KNOWN BUGS

Startup time may be an issue - escpecially if you load many plugins. If you do
not require the functionality of plugins and ability for fine grained
customisation (or Moose for that matter) then you should probably
use L<MooX::Options> or L<MooX::Cmd>.

In some cases - especially when using non-standard class inheritance - you may
end up with command classes lacking the help attribute. In this case you need
to include the following line in your base class or command classes.

 with qw(MooseX::App::Role::Common);

When manually registering command classes (eg. via app_command_register) in
multiple base classes with different sets of plugins (why would you ever want
to do that?), then meta attributes may lack some attribute metaclasses. In
this case you need to load the missing attribute traits explicitly:

 option 'argument' => (
    depends => 'otherargument',
    trait   => ['MooseX::App::Plugin::Depends::Meta::Attribute'], # load trait
 );

=head1 SEE ALSO

Read the L<Tutorial|MooseX::App::Tutorial> for getting started with a simple
MooseX::App command line application.

For alternatives you can check out

L<MooseX::App::Cmd>, L<MooseX::Getopt>, L<MooX::Options>, L<MooX::Cmd>and L<App::Cmd>

=head1 SUPPORT

Please report any bugs or feature requests via
L<https://github.com/maros/MooseX-App/issues/new>. I will be notified, and
then you'll automatically be notified of progress on your report as I make
changes.

=head1 AUTHOR

    Maroš Kollár
    CPAN ID: MAROS
    maros [at] k-1.com
    
    http://www.k-1.com

=head1 CONTRIBUTORS

Special thanks to all contributors.

In no particular order: Andrew Jones, George Hartzell, Steve Nolte,
Michael G, Thomas Klausner, Yanick Champoux, Edward Baudrez, David Golden,
J.R. Mash, Thilo Fester, Gregor Herrmann, Sergey Romanov, Sawyer X, Roman F.,
Hunter McMillen, Maik Hentsche, Alexander Stoddard, Marc Logghe, Tina Müller,
Lisa Hare

You are more than welcome to contribute to MooseX-App. Please have a look
at the L<https://github.com/maros/MooseX-App/issues?q=is%3Aissue+is%3Aopen+label%3AWishlist>
list of open wishlist issues for ideas.

=head1 COPYRIGHT

MooseX::App is Copyright (c) 2012-17 Maroš Kollár.

This library is free software and may be distributed under the same terms as
perl itself. The full text of the licence can be found in the LICENCE file
included with this module.

=cut
