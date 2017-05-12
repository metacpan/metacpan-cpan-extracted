package MooseX::Role::Cmd;

use strict;
use warnings;

use Carp ();
use IPC::Cmd ();
use Moose::Role;
use MooseX::Role::Cmd::Meta::Attribute::Trait;

our $VERSION = '0.10';

=head1 NAME

MooseX::Role::Cmd - Wrap system command binaries the Moose way

=head1 SYNOPSIS

Create your command wrapper:

    package Cmd::Perl;

    use Moose;

    with 'MooseX::Role::Cmd';

    has 'e' => (isa => 'Str', is => 'rw');

    # other perl switches here...

    1;

Use it somewhere else:

    use Cmd::Perl;

    my $perl = Cmd::Perl->new(e => q{'print join ", ", @ARGV'});

    print $perl->run(qw/foo bar baz/);

    # prints the STDOUT captured from running:
    # perl -e 'print join ", ", @ARGV' foo bar baz

=head1 DESCRIPTION

MooseX::Role::Cmd is a L<Moose> role intended to ease the task of building
command-line wrapper modules. It automatically maps L<Moose> objects into
command strings which are passed to L<IPC::Cmd>.

=head1 ATTRIBUTES

=head2 $cmd->bin_name

Sets the binary executable name for the command you want to run. Defaults
the to last part of the class name.

=cut

has 'bin_name' => (
    isa     => 'Str',
    is      => 'rw',
    lazy    => 1,
    default => sub { shift->build_bin_name },
);

=head2 $cmd->stdout

Returns the STDOUT buffer captured after running the command.

=cut

has 'stdout' => ( isa => 'ArrayRef', is => 'rw' );

=head2 $cmd->stderr

Returns the STDERR buffer captured after running the command.

=cut

has 'stderr' => ( isa => 'ArrayRef', is => 'rw' );

no Moose;

=head1 METHODS

=head2 $bin_name = $cmd->build_bin_name

Builds the default string for the command name based on the class name.

=cut

# done this way to be overrideable
sub build_bin_name {
    my ($self) = @_;
    my $class = ref $self;
    if ( !$class ) {
        $class = $self;
    }
    return lc( ( split '::', $class )[-1] );    ## no critic
}

=head2 @stdout = $cmd->run(@args);

Builds the command string and runs it based on the objects current attribute
settings. This will treat all the attributes defined in your class as flags
to be passed to the command.

B<NOTE:> All quoting issues are left to be solved by the user.

=cut

sub run {
    my ( $self, @args ) = @_;

    my $cmd = $self->bin_name;
    my $full_path;
    if ( !( $full_path = IPC::Cmd::can_run($cmd) ) ) {
        Carp::confess(qq{couldn't find command '$cmd'});
    }

    # build full list of cmd args from attrs
    @args = $self->cmd_args( @args );

    #warn "CMD: " . $full_path . " " . join (" ", map { "'$_'"  } @args );
    my ( $success, $error_code, $full_buf, $stdout_buf, $stderr_buf ) =
      IPC::Cmd::run( command => [ $full_path, @args ] );

    if ( !$success ) {
        Carp::confess("error running '$full_path': " . $error_code);
    }

    $self->stdout($stdout_buf);
    $self->stderr($stderr_buf);
    return 1;
}

=head2 cmd_args

Returns a list of the computed arguments that will be added to the command

=cut

sub cmd_args {
    my ( $self, @extra_args ) = @_;

    # exclude this role's attributes from the flag list
    # could use custom metaclasses and introspection, but this will do for now
    my %non_flag   = map    { $_ => 1 } __PACKAGE__->meta->get_attribute_list;

    my @flag_attrs = grep   { !$non_flag{$_->name} }
                     grep   { substr($_->name, 0, 1) ne '_' }
                     map    { $self->meta->get_attribute($_) }
                     $self->meta->get_attribute_list;

    #####
    # IS: 2008/10/15
    # Changed the following to make a start on the suggestion above...
    #####
    #my @flags = map { ( "-$_" => $self->$_ ) } @flag_attrs;
    my @flags = map { ( $self->_attr_to_cmd_options( $_ ) ) } @flag_attrs;

    my @args = ( @flags, @extra_args );

    return wantarray ? @args : \@args;
}

=head1 ADDITIONAL INFORMATION

=head2 Setting the Executable

By default the name of the binary executable is taken from the last part of the class name
(in lower case). The path is set during the L<run> method by scanning through your current
PATH for the given executable (see also the 'can_run' function from L<IPC::Cmd>)

    package MyApp::Commands::Scanner;
    use Moose;
    with 'MooseX::Role::Cmd';

    $cmd = MyApp::Commands::Scanner->new();
    $cmd->bin_name
    # /path/to/scanner

If this default behaviour doesn't suit your application then you can override the L<build_bin_name>
subroutine to explicitly set the executable name

    sub build_bin_name { 'scanner.exe' }
    # /path/to/scanner.exe

Or you could explicitly set the path with

    sub build_bin_name { '/only/use/this/path/scanner.exe' }
    # /only/use/this/path/scanner.exe

=head2 How attributes are mapped to parameters

The attributes of the consuming package map directly to the parameters passed
to the executable. There are a few things to note about the default behaviour
governing the way these attributes are mapped.

    Attribute           Default Behaviour (@ARGV)
    ---------           -------------------------
    single char         prefix attr name with '-'
    multiple char       prefix attr name with '--'
    boolean             treat attr as flag (no value)
    non-boolean         treat attr as parameter (with value)
    value=undef         ignore attr
    name=_name          ignore attr

These points are illustrated in the following example:

    package MyApp::Commands::Scanner;
    use Moose;
    with 'MooseX::Role::Cmd';

    has 'i'       => ( is => 'rw', isa => 'Str',  default => 'input.txt' );
    has 'out'     => ( is => 'rw', isa => 'Str' );
    has 'verbose' => ( is => 'rw', isa => 'Bool', default => 1 );
    has 'level'   => ( is => 'rw', isa => 'Int' );
    has 'option'  => ( is => 'rw', isa => 'Str' );

    has '_internal' => ( is => 'ro', isa => Str, reader => internal, default => 'foo' );
    # attribute names starting with '_' are not included

    $scanner = MyApp::Commands::Scanner->new( output => '/tmp/scanner.log', level => 5 );

    $scanner->run;
    # /path/to/scanner -i input.txt --out /tmp/scanner.log --verbose --level 5

=head2 Changing names of parameters

It's possible that the parameters your system command expects do not adhere to this
naming scheme. In this case you can use the 'CmdOpt' trait which allows you to
specify exactly how you want the parameter to appear on the command line.

    has 'option' => ( isa           => 'Bool' );
    # --option

=head3 cmdopt_prefix

This lets you override the prefix used for the option (for example to use the short
form of multi-character options).

    has 'option' => ( traits        => [ 'CmdOpt' ],
                      isa           => 'Bool',
                      cmdopt_prefix => '-'
                    );
    # -option

=head3 cmdopt_name

This lets you completely override the option name with whatever string you want

    has 'option' => ( traits        => [ 'CmdOpt' ],
                      isa           => 'Bool',
                      cmdopt_name   => '+foo'
                    );
    # +foo

=head3 cmdopt_env

This will set an environment variable with the attribute name/value rather than pass
it along as a command line param

    has 'home_dir' => ( traits      => [ 'CmdOpt' ],
                        isa         => 'Str',
                        cmdopt_env  => 'APP_HOME'
                        default     => '/my/app/home'
                    );

    # ENV{APP_HOME} = /my/app/home

See L<MooseX::Role::Cmd::Meta::Attribute::Trait>

=head1 PRIVATE METHODS

=head2 _attr_to_cmd_options

Returns an array (or array reference) of command options that correspond
to the given attribute name.

=cut

sub _attr_to_cmd_options {
    my ( $self, $attr ) = @_;

    my $attr_name = $attr->name;

    # decide the default settings
    my $opt_prefix = length( $attr_name ) == 1 ? '-' : '--';
    my $opt_name   = $attr_name;

    my $attr_value = $attr->get_value( $self );

    # override defaults with Traits
    if ( $attr->does('MooseX::Role::Cmd::Meta::Attribute::Trait') ) {

        # deal with $ENV
        if ($attr->has_cmdopt_env) {
            my $env_key   = $attr->cmdopt_env;
            if ( defined $attr_value ) {
                $ENV{$env_key} = $attr_value;
            }
            # environment vars not used as params
            return;
        }

        if ($attr->has_cmdopt_prefix) {
            $opt_prefix = $attr->cmdopt_prefix;
        }

        if ($attr->has_cmdopt_name) {
            $opt_prefix = '';                   # name overrides prefix
            $opt_name   = $attr->cmdopt_name;
        }
    }

    # create the full option name
    my $opt_fullname = $opt_prefix . $opt_name;

    my @options = ();
    if ( $attr->type_constraint->is_a_type_of( 'Bool' ) ) {
        push @options, ( $opt_fullname )
            if $attr_value;                             # only add if attr is true
    }
    else {
        if ( defined $attr_value ) {                    # only add if attr value is defined
            push @options, ( $opt_fullname, $attr_value )
        }
    }

    return wantarray ? @options : \@options;
}

=head1 AUTHOR

Eden Cardim <edencardim@gmail.com>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
