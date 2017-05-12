package Server::Control;
BEGIN {
  $Server::Control::VERSION = '0.20';
}
use Capture::Tiny;
use File::Basename;
use File::Slurp qw(read_file);
use File::Spec::Functions qw(catdir);
use File::Which;
use Getopt::Long;
use Hash::MoreUtils qw(slice_def);
use IPC::System::Simple qw();
use Log::Any qw($log);
use Log::Dispatch::Screen;
use Moose;
use MooseX::StrictConstructor;
use Moose::Util::TypeConstraints;
use Pod::Usage;
use Time::HiRes qw(usleep);
use Server::Control::Util
  qw(is_port_active kill_children something_is_listening_msg process_table);
use YAML::Any;
use strict;
use warnings;

# Gives us new_with_traits - only if MooseX::Traits is installed
#
eval {
    with 'MooseX::Traits';
    has '+_trait_namespace' => ( default => 'Server::Control::Plugin' );
};
if ( my $moosex_traits_error = $@ ) {
    __PACKAGE__->meta->add_method(
        new_with_traits => sub {
            die "MooseX::Traits could not be loaded - $moosex_traits_error";
        }
    );
}

#
# ATTRIBUTES
#

# Note: In some cases we use lazy_build rather than specifying required or a
# default, to make life easier for subclasses.
#
has 'binary_name'          => ( is => 'ro', isa => 'Str' );
has 'binary_path'          => ( is => 'ro', isa => 'Str', lazy_build => 1 );
has 'bind_addr'            => ( is => 'ro', isa => 'Str', lazy_build => 1 );
has 'description'          => ( is => 'ro', isa => 'Str', lazy_build => 1, init_arg => undef );
has 'error_log'            => ( is => 'ro', isa => 'Str', lazy_build => 1 );
has 'log_dir'              => ( is => 'ro', isa => 'Str', lazy_build => 1 );
has 'name'                 => ( is => 'ro', isa => 'Str', lazy_build => 1 );
has 'pid_file'             => ( is => 'ro', isa => 'Str', lazy_build => 1 );
has 'poll_for_status_secs' => ( is => 'ro', isa => 'Num', default => 0.2 );
has 'port'                 => ( is => 'ro', isa => 'Int', lazy_build => 1 );
has 'restart_method'       => ( is => 'ro', isa => enum( [qw(hup stopstart)] ), default => 'stopstart' );
has 'server_root'          => ( is => 'ro', isa => 'Str' );
has 'use_sudo'             => ( is => 'ro', isa => 'Bool', lazy_build => 1 );
has 'validate_regex'       => ( is => 'ro', isa => 'RegexpRef' );
has 'validate_url'         => ( is => 'ro' );
has 'wait_for_hup_secs'    => ( is => 'ro', isa => 'Num', default => 0.5 );
has 'wait_for_status_secs' => ( is => 'ro', isa => 'Int', default => 10 );

# These are only for command-line. Would like to prevent their use from regular new()...
#
has 'action' => ( is => 'ro', isa => 'Str' );

foreach my $method (qw(successful_start successful_stop)) {
    __PACKAGE__->meta->add_method( $method => sub { } );
}

__PACKAGE__->meta->make_immutable();

use constant {
    INACTIVE  => 0,
    RUNNING   => 1,
    LISTENING => 2,
    ACTIVE    => 3,
};

#
# CONSTRUCTION
#

sub BUILDARGS {
    my $class  = shift;
    my %params = @_;

    $class->_handle_serverctlrc( \%params );
    $class->_log_constructor_params( \%params );

    return $class->SUPER::BUILDARGS(%params);
}

# See if there is an rc_file, in serverctlrc parameter or in
# server_root/serverctl.yml; if so, read from it and merge with parameters
# passed to constructor.
#
sub _handle_serverctlrc {
    my ( $class, $params ) = @_;

    my $rc_file;
    if ( $rc_file = delete( $params->{serverctlrc} ) ) {
        die sprintf( "no such rc file '%s'", $rc_file ) if !-f $rc_file;
    }
    else {
        if ( defined( $params->{server_root} ) ) {
            my $default_rc_file =
              join( "/", $params->{server_root}, "serverctl.yml" );
            $rc_file = $default_rc_file if -f $default_rc_file;
        }
    }
    if ( defined $rc_file ) {
        if ( defined( my $rc_params = YAML::Any::LoadFile($rc_file) ) ) {
            die "expected hashref from rc_file '$rc_file', got '$rc_params'"
              unless ref($rc_params) eq 'HASH';
            %$rc_params =
              map { my $val = $rc_params->{$_}; s/\-/_/g; ( $_, $val ) }
              keys(%$rc_params);
            %$params = ( %$rc_params, %$params );
            $log->debugf( "found rc file '%s' with these parameters: %s",
                $rc_file, $rc_params )
              if $log->is_debug;
        }
    }
}

sub _log_constructor_params {
    my ( $class, $params ) = @_;

    $log->debugf( "constructing Server::Control with these params: %s",
        $params )
      if $log->is_debug;
}

#
# ATTRIBUTE BUILDERS
#

sub _build_bind_addr {
    return "localhost";
}

sub _build_binary_path {
    my $self = shift;
    if ( my $binary_name = $self->binary_name ) {
        my $binary_path = ( File::Which::which($binary_name) )[0]
          or die
          "no binary_path specified and cannot find '$binary_name' in path";
        return $binary_path;
    }
    return undef;
}

sub _build_error_log {
    my $self = shift;
    return
      defined( $self->log_dir ) ? catdir( $self->log_dir, "error_log" ) : undef;
}

sub _build_description {
    my $self = shift;
    my $name = $self->name;
    return "server '$name'";
}

sub _build_log_dir {
    my $self = shift;
    return defined( $self->server_root )
      ? catdir( $self->server_root, "logs" )
      : undef;
}

sub _build_name {
    my $self = shift;
    my $name;
    if ( defined( my $server_root = $self->server_root ) ) {
        $name = basename($server_root);
    }
    else {
        ( $name = ref($self) ) =~ s/^Server::Control:://;
    }
    return $name;
}

sub _build_pid_file {
    die "cannot determine pid_file";
}

sub _build_port {
    die "cannot determine port";
}

sub _build_use_sudo {
    my $self = shift;
    return $self->port < 1024;
}

#
# PUBLIC METHODS
#

sub start {
    my $self = shift;

    if ( !$self->_running_before_start() && !$self->_listening_before_start() )
    {
        my $error_size_start = $self->_start_error_log_watch();

        eval { $self->do_start() };
        if ( my $err = $@ ) {
            $log->errorf( "error while trying to start %s: %s",
                $self->description(), $err );
            $self->_report_error_log_output($error_size_start);
        }
        else {
            if (
                $self->_wait_for_status( ACTIVE, 'start', \$error_size_start ) )
            {
                ( my $status = $self->status_as_string() ) =~
                  s/running/now running/;
                $log->info($status);
                if ( $self->validate_server() ) {
                    $self->successful_start();
                    return 1;
                }
                else {
                    $self->_report_error_log_output($error_size_start);
                }
            }
        }
    }
    return 0;
}

sub _running_before_start {
    my $self = shift;

    if ( my $proc = $self->is_running() ) {
        ( my $status = $self->status_as_string() ) =~
          s/running/already running/;
        $log->warnf($status);
        return 1;
    }
    return 0;
}

sub _listening_before_start {
    my $self = shift;

    if ( $self->is_listening() ) {
        $log->warnf(
            "cannot start %s - pid file '%s' does not exist, but %s",
            $self->description(),
            $self->pid_file(),
            something_is_listening_msg( $self->port, $self->bind_addr )
        );
        return 1;
    }
    return 0;
}

sub stop {
    my ($self) = @_;

    my $error_size_start = $self->_start_error_log_watch();

    my $proc = $self->_ensure_is_running() or return 0;
    $self->_warn_if_different_user($proc);

    eval { $self->do_stop($proc) };
    if ( my $err = $@ ) {
        $log->errorf( "error while trying to stop %s: %s",
            $self->description(), $err );
        $self->_report_error_log_output($error_size_start);
    }
    elsif ( $self->_wait_for_status( INACTIVE, 'stop', $error_size_start ) ) {
        $log->infof( "%s has stopped", $self->description() );
        $self->successful_stop();
        return 1;
    }
    return 0;
}

sub restart {
    my ($self) = @_;

    if ( !$self->is_running() ) {
        return $self->start();
    }
    else {
        my $restart_method = $self->restart_method;
        $self->$restart_method();
    }
}

sub hup {
    my ($self) = @_;

    my $proc = $self->_ensure_is_running() or return 0;
    my $error_size_start = $self->_start_error_log_watch();
    unless ( kill( 1, $proc->pid ) ) {
        $log->errorf( "could not signal process %d", $proc->pid );
        return 0;
    }
    $log->infof( "sent HUP to process %d", $proc->pid );
    usleep( $self->wait_for_hup_secs() * 1_000_000 );
    if ( $self->_wait_for_status( ACTIVE, 'restart', \$error_size_start ) ) {
        $log->info( $self->status_as_string() );
        if ( $self->validate_server() ) {
            $self->successful_start();
            return 1;
        }
        else {
            $self->_report_error_log_output($error_size_start);
        }
    }
    return 0;
}

sub stopstart {
    my ($self) = @_;

    if ( $self->is_running() ) {
        unless ( $self->stop() ) {
            $log->infof( "could not stop %s, will not attempt start",
                $self->description() );
            return 0;
        }
    }
    return $self->start();
}

sub refork {
    my ($self) = @_;

    my $proc = $self->_ensure_is_running() or return;
    my @child_pids = kill_children( $proc->pid );
    $log->debugf( "sent TERM to children of pid %d (%s)",
        $proc->pid, join( ", ", @child_pids ) )
      if $log->is_debug;
    $log->infof( "reforked %s", $self->description() );
    return @child_pids;
}

sub ping {
    my ($self) = @_;

    $log->info( $self->status_as_string() );
}

sub do_start {
    die "must be provided by subclass";
}

sub do_stop {
    my ( $self, $proc ) = @_;

    kill 15, $proc->pid;
}

sub status {
    my $self = shift;

    # Can pass in is_running() result, else we'll do it here
    my $is_running = (@_) ? shift(@_) : $self->is_running();
    return ( $is_running    ? RUNNING   : 0 ) |
      ( $self->is_listening ? LISTENING : 0 );
}

sub status_as_string {
    my ($self) = @_;

    my $port   = $self->port;
    my $proc   = $self->is_running();
    my $status = $self->status($proc);
    my $msg =
        ( $status == INACTIVE ) ? "is not running"
      : ( $status == RUNNING )
      ? sprintf( "appears to be running (pid %d), but not listening to port %d",
        $proc->pid, $port )
      : ( $status == LISTENING )
      ? sprintf( "pid file '%s' does not exist, but %s",
        $self->pid_file,
        something_is_listening_msg( $self->port, $self->bind_addr ) )
      : ( $status == ACTIVE )
      ? sprintf( "is running (pid %d) and listening to port %d",
        $proc->pid, $port )
      : die "invalid status: $status";
    return join( " ", $self->description(), $msg );
}

sub is_running {
    my ($self) = @_;

    my $pid_file = $self->pid_file();
    my $pid      = $self->_read_pid_file($pid_file);
    return undef unless $pid;

    if ( my $proc = $self->_find_process($pid) ) {
        $log->debugf( "pid file '%s' exists and has valid pid %d",
            $pid_file, $pid )
          if $log->is_debug && !$self->{_suppress_logs};
        return $proc;
    }
    else {
        if ( -f $pid_file ) {
            $log->infof(
                "pid file '%s' contains a non-existing process id '%d'!",
                $pid_file, $pid );
            $self->_handle_corrupt_pid_file();
        }
    }
    return undef;
}

sub is_listening {
    my ($self) = @_;

    my $is_listening = is_port_active( $self->port(), $self->bind_addr() );
    if ( $log->is_debug ) {
        $log->debugf(
            "%s is listening to %s:%d",
            $is_listening ? "something" : "nothing",
            $self->bind_addr(), $self->port()
        ) if $log->is_debug && !$self->{_suppress_logs};
    }
    return $is_listening;
}

sub validate_server {
    my ($self) = @_;

    if ( defined( my $url = $self->validate_url ) ) {
        require LWP;
        $url = sprintf( "http://%s%s%s",
            $self->bind_addr,
            ( $self->port == 80 ? '' : ( ":" . $self->port ) ), $url )
          if substr( $url, 0, 1 ) eq '/';
        $log->infof( "validating url '%s'", $url );
        my $ua  = LWP::UserAgent->new;
        my $res = $ua->get($url);
        if ( $res->is_success ) {
            if ( my $regex = $self->validate_regex ) {
                if ( $res->content !~ $regex ) {
                    $log->errorf(
                        "content of '%s' (%d bytes) did not match regex '%s'",
                        $url, length( $res->content ), $regex );
                    return 0;
                }
            }
            $log->debugf("validation successful") if $log->is_debug;
            return 1;
        }
        else {
            $log->errorf( "error getting '%s': %s", $url, $res->status_line );
            return 0;
        }
    }
    else {
        return 1;
    }
}

sub run_system_command {
    my ( $self, $cmd ) = @_;

    if ( $self->use_sudo() ) {
        $cmd = "sudo $cmd";
    }
    $log->debug("running '$cmd'") if $log->is_debug;
    IPC::System::Simple::run($cmd);
}

sub valid_cli_actions {
    return qw(start stop restart ping hup stopstart refork);
}

my @save_argv;

sub handle_cli {
    my $class = shift;
    @save_argv = @ARGV if !@save_argv;

    # Allow caller to specify subclass with -c|--class and include paths with -I
    #
    my ( $subclass, @includes );
    $class->_cli_get_options(
        [ 'c|class=s' => \$subclass, 'I=s' => \@includes ],
        [ 'pass_through', 'no_ignore_case' ] );
    unshift( @INC, @includes );
    if ( defined $subclass ) {
        my $full_subclass =
            substr( $subclass, 0, 1 ) eq '+'
          ? substr( $subclass, 1 )
          : "Server::Control::$subclass";
        Class::MOP::load_class($full_subclass);
        return $full_subclass->handle_cli();
    }

    # Create object based on @ARGV options. Restore @ARGV afterwards, as
    # some subclasses need it, e.g. Net::Server needs @ARGV intact for HUP.
    #
    my $self = $class->new_with_options(@_);
    @ARGV = @save_argv;

    # Validate and perform specified action
    #
    $self->_perform_cli_action();
}

# This method and its helpers are modelled after MooseX::Getopt, which
# unfortunately I found both too flaky and not completely suited to my needs.
# If and when things improve, we can hopefully drop it in as a replacement.
#
sub new_with_options {
    my ( $class, %passed_params ) = @_;

    # Get params from command-line
    #
    my %option_pairs = $class->_cli_option_pairs();
    my %cli_params   = $class->_cli_parse_argv( \%option_pairs );

    # Start logging to stdout with appropriate log level
    #
    $class->_setup_cli_logging( \%cli_params );
    delete( @cli_params{qw(quiet verbose)} );

    # Combine passed and command-line params, pass to constructor
    #
    my %params = ( %passed_params, %cli_params );
    return $class->new_from_cli(%params);
}

# This method gives subclasses an opportunity to examine the full set
# of parameters (both specified on the cli passed to handle_cli) and issue
# a cli-specific error, before moving onto the regular constructor.
#
sub new_from_cli {
    my $class = shift;

    return $class->new(@_);
}

#
# PRIVATE METHODS
#

sub _start_error_log_watch {
    my ($self) = @_;

    return defined( $self->error_log ) ? ( -s $self->error_log() || 0 ) : 0;
}

sub _wait_for_status {
    my ( $self, $status, $action, $error_size_start ) = @_;

    # $error_size_start can be undef, a number, or a reference to a number.
    # In the last case we are expected to update it.
    my $error_size_start_ref =
      ( ref($error_size_start) ? $error_size_start : \$error_size_start );

    $log->infof("waiting for server $action");
    my $wait_until = time() + $self->wait_for_status_secs();
    my $poll_delay = $self->poll_for_status_secs() * 1_000_000;
    local $self->{_suppress_logs} = 1;    # Suppress logs during this loop
    while ( time() < $wait_until ) {
        if ( defined($$error_size_start_ref) ) {
            if ( $self->_report_error_log_output($$error_size_start_ref) ) {
                $$error_size_start_ref = $self->_start_error_log_watch();
            }
        }
        if ( $self->status == $status ) {
            return 1;
        }
        else {
            usleep($poll_delay);
        }
    }

    $log->warnf(
        "after %d secs, %s",
        $self->wait_for_status_secs(),
        $self->status_as_string()
    );
    return 0;
}

sub _report_error_log_output {
    my ( $self, $error_size_start ) = @_;

    if ( defined( my $error_log = $self->error_log() ) ) {
        if ( -f $error_log ) {
            my ( $fh, $buf );
            my $error_size_end = ( -s $error_log );
            if ( $error_size_end > $error_size_start ) {
                open( $fh, $error_log );
                seek( $fh, $error_size_start, 0 );
                read( $fh, $buf, $error_size_end - $error_size_start );
                my @lines = grep { /\S/ } split( "\n", $buf );
                foreach my $line (@lines) {
                    $log->infof( "error log: %s", $line );
                }
                return 1;
            }
        }
    }
    return 0;
}

sub _handle_corrupt_pid_file {
    my ($self) = @_;

    my $pid_file = $self->pid_file();
    $log->infof( "deleting bogus pid file '%s'", $pid_file );
    unlink $pid_file or die "cannot remove '$pid_file': $!";
}

sub _cli_parse_argv {
    my ( $class, $option_pairs ) = @_;

    my %cli_params;
    my @spec =
      map { $_ => \$cli_params{ $option_pairs->{$_} } } keys(%$option_pairs);
    $class->_cli_get_options( \@spec, ['no_ignore_case'] );
    %cli_params = slice_def( \%cli_params, keys(%cli_params) );

    $class->_cli_usage( "", 0 ) if !%cli_params;
    $class->_cli_usage( "", 1 ) if $cli_params{help};
    $class->_cli_usage("must specify -c|--class") if $class eq __PACKAGE__;

    return %cli_params;
}

sub _cli_get_options {
    my ( $class, $spec, $config ) = @_;

    my $parser = new Getopt::Long::Parser( config => $config );
    if ( !$parser->getoptions(@$spec) ) {
        $class->_cli_usage("");
    }
}

sub _cli_option_pairs {
    return (
        'bind-addr=s'            => 'bind_addr',
        'b|binary=s'             => 'binary_path',
        'd|server-root=s'        => 'server_root',
        'error-log=s'            => 'error_log',
        'h|help'                 => 'help',
        'k|action=s'             => 'action',
        'log-dir=s'              => 'log_dir',
        'name=s'                 => 'name',
        'pid-file=s'             => 'pid_file',
        'port=s'                 => 'port',
        'q|quiet'                => 'quiet',
        'serverctlrc=s'          => 'serverctlrc',
        'use-sudo=s'             => 'use_sudo',
        'v|verbose'              => 'verbose',
        'wait-for-status-secs=s' => 'wait_for_status_secs',
    );
}

sub _setup_cli_logging {
    my ( $self, $cli_params ) = @_;

    my $log_level =
        $cli_params->{verbose} ? 'debug'
      : $cli_params->{quiet}   ? 'warning'
      :                          'info';
    my $dispatcher =
      Log::Dispatch->new( outputs =>
          [ [ 'Screen', stderr => 0, min_level => $log_level, newline => 1 ] ]
      );
    Log::Any->set_adapter( { category => qr/^Server::Control/ },
        'Dispatch', dispatcher => $dispatcher );
}

sub _perform_cli_action {
    my ($self) = @_;
    my $action = $self->action;

    if ( !defined $action ) {
        $self->_cli_usage("must specify -k");
    }
    elsif ( !grep { $_ eq $action } $self->valid_cli_actions ) {
        $self->_cli_usage(
            sprintf(
                "invalid action '%s' - valid actions are %s",
                $action,
                join( ", ",
                    ( map { "'$_'" } sort( $self->valid_cli_actions ) ) )
            )
        );
    }
    else {
        ( my $action_method = $action ) =~ s/\-/_/g;
        $self->$action_method();
    }
}

sub _cli_usage {
    my ( $class, $msg, $verbose ) = @_;

    $msg     ||= "";
    $verbose ||= 0;
    my $usage = Capture::Tiny::capture_merged {
        pod2usage( -msg => $msg, -verbose => $verbose, -exitval => "NOEXIT" );
    };
    if ( $usage !~ /\S/ ) {
        die "could not get usage from pod2usage for $0";
    }
    else {
        print STDERR $usage;
        exit(2);
    }
}

sub _ensure_is_running {
    my ($self) = @_;

    my $proc = $self->is_running();
    unless ($proc) {
        $log->warn( $self->status_as_string() );
    }
    return $proc;
}

sub _warn_if_different_user {
    my ( $self, $proc ) = @_;

    my ( $uid, $eid ) = ( $<, $> );
    if ( ( $eid || $uid ) && $proc->uid != $uid && !$self->use_sudo() ) {
        $log->warnf(
            "warning: process %d is owned by uid %d ('%s'), different than current user %d ('%s'); may not be able to stop server",
            $proc->pid,
            $proc->uid,
            scalar( getpwuid( $proc->uid ) ),
            $uid,
            scalar( getpwuid($uid) )
        );
    }
}

sub _find_process {
    my ( $self, $pid ) = @_;

    my $ptable = process_table();
    my ($proc) = grep { $_->pid == $pid } @{ $ptable->table };
    return $proc;
}

sub _read_pid_file {
    my ( $self, $pid_file ) = @_;

    my $pid_contents = eval { read_file($pid_file) };
    if ($@) {
        $log->debugf( "pid file '%s' does not exist", $pid_file )
          if $log->is_debug && !$self->{_suppress_logs};
        return undef;
    }
    else {
        my ($pid) = ( $pid_contents =~ /^\s*(\d+)\s*$/ );
        unless ( defined($pid) ) {
            $log->infof( "pid file '%s' does not contain a valid process id!",
                $pid_file );
            $self->_handle_corrupt_pid_file();
            return undef;
        }
        return $pid;
    }
}

1;



=pod

=head1 NAME

Server::Control -- Flexible apachectl style control for servers

=head1 VERSION

version 0.20

=head1 SYNOPSIS

    use Server::Control::Apache;

    my $apache = Server::Control::Apache->new(
        conf_file => '/my/apache/dir/conf/httpd.conf'
    );
    if ( !$apache->is_running() ) {
        $apache->start();
    }

=head1 DESCRIPTION

C<Server::Control> allows you to control servers in the spirit of apachectl,
where a server is any background process which listens to a port and has a pid
file. It is designed to be subclassed for different types of servers.

The original motivation was to eliminate all those little annoyances that can
occur when starting and stopping a server doesn't quite go right.

=head1 FEATURES

=over

=item *

Checks server status in multiple ways (looking for an active process,
contacting the server's port)

=item *

Detects and handles corrupt or out-of-date pid files

=item *

Tails the error log when server fails to start

=item *

Uses sudo by default when using restricted (< 1024) port

=item *

Reports what is listening to a port when it is busy (with Unix::Lsof)

=back

=head1 AVAILABLE SUBCLASSES

The following subclasses are currently available as part of this distribution:

=over

=item *

L<Server::Control::Apache> - For L<Apache httpd|http://httpd.apache.org/>

=item *

L<Server::Control::Nginx> - For L<Nginx|http://nginx.org/>

=item *

L<Server::Control::Starman> - For L<Starman|Starman>

=item *

L<Server::Control::HTTPServerSimple> - For
L<HTTP::Server::Simple|HTTP::Server::Simple>

=item *

L<Server::Control::NetServer> - For L<Net::Server|Net::Server>

=back

There may be other subclasses L<available on
CPAN|http://search.cpan.org/search?query=Server%3A%3AControl&mode=all>.

=for readme stop

=head1 CONSTRUCTOR PARAMETERS

You can pass the following common parameters to the constructor, or include
them in an L<rc file|serverctlrc>.

Some subclasses can deduce some of these parameters without needing an explicit
value passed in.  For example,
L<Server::Control::Apache|Server::Control::Apache> can deduce many of these
from the Apache conf file.

=over

=item binary_path

The absolute path to the server binary, e.g. /usr/sbin/httpd or
/usr/local/bin/nginx. By default, searches for the appropriate command in the
user's PATH and uses the first one found, or throws an error if one cannot be
found.

=item bind_addr

At least one address that the server binds to, so that C<Server::Control> can
check it on start/stop. Defaults to C<localhost>. See also L</port>.

=item error_log

Location of error log. Defaults to I<log_dir>/error_log if I<log_dir> is
defined, otherwise undef. When a server fails to start, Server::Control
attempts to show recent messages in the error log.

=item log_dir

Location of logs. Defaults to I<server_root>/logs if I<server_root> is defined,
otherwise undef.

=item name

Name of the server to be used in output and logs. A generic default will be
chosen if none is provided, based on either L</server_root> or the classname.

=item pid_file

Path to pid file. Will throw an error if this cannot be determined.

=item poll_for_status_secs

Number of seconds (can be fractional) between status checks when waiting for
server start or stop.  Defaults to 0.2.

=item port

At least one port that server will listen to, so that C<Server::Control> can
check it on start/stop. Will throw an error if this cannot be determined. See
also L</bind_addr>.

=item restart_method

Method to use for the L</restart> action - one of L</hup> or L</stopstart>,
defaults to L</stopstart>.

=item server_root

Root directory of server, for conf files, log files, etc. This will affect
defaults of other parameters like I<log_dir>. You must create this directory,
it will not be created for you.

=item serverctlrc

Path to an rc file containing, in YAML form, one or parameters to pass to the
constructor. If not specified, will look for L</server_root>/serverctl.yml.
e.g.

    # This is my serverctl.yml
    use_sudo: 1
    wait_for_status-secs: 5

Parameters passed explicitly to the constructor take precedence over parameters
in an rc file.

=item use_sudo

Whether to use 'sudo' when attempting to start and stop server. Defaults to
true if I<port> < 1024, false otherwise.

=item validate_url

A URL to visit after the server has been started or HUP'd, in order to validate
the state of the server. The URL just needs to return an OK result to be
considered valid, unless L</validate_regex> is also specified.

=item validate_regex

A regex to match against the content returned by L</validate_url>. The content
must match the regex for the server to be considered valid.

=item wait_for_status_secs

Number of seconds to wait for server start or stop before reporting error.
Defaults to 10.

=back

=head1 METHODS

=head2 Action methods

=over

=item start

Start the server. Calls L</do_start> internally. Returns 1 if the server
started successfully, 0 if not (e.g. it was already running, or there was an
error starting it).

=item stop

Stop the server. Calls L</do_stop> internally. Returns 1 if the server stopped
successfully, 0 if not (e.g. it was already stopped, or there was an error
stopping it).

=item restart

If the server is not running, start it. Otherwise, restart the server using the
L</restart_method> - one of L</hup> or L</stopstart>, defaults to
L</stopstart>.

=item hup

Sends the server parent process a HUP signal, which is a standard way of
restarting it. Returns 1 if the server was successfully signalled and is still
running afterwards, 0 if not.

Note: HUP is not yet fully supported for NetServer and HTTPServerSimple,
because it depends on a valid command-line that can be re-exec'd.

=item stopstart

Stops the server (if it is running), then starting it. Returns 1 if the server
restarted succesfully, 0 if not.

=item refork

Send a C<TERM> signal to the child processes of the server's main process. This
will force forking servers, such as C<Apache> and C<Net::Server::Prefork>, to
fork new children. This can serve as a cheap restart in a development
environment, if the resources you want to refresh are being loaded in the child
rather than the parent.

Returns the list of child pids that were sent a C<TERM>.

=item ping

Log the server's status.

=back

=head2 Command-line processing

=over

=item handle_cli (constructor_params)

Helper method to implement a CLI (command-line interface) like apachectl. This
is used by two scripts that come with this distribution, L<apachectlp> and
L<serverctlp>. In general the usage looks like this:

   #!/usr/bin/perl -w
   use strict;
   use Server::Control::Foo;

   Server::Control::Foo->handle_cli();

C<handle_cli> will process the following options from C<@ARGV>:

=over

=item *

-v|--verbose - set log level to C<debug>

=item *

-q|--quiet - set log level to C<warning> respectively

=item *

-c|--class - forwards the call to the specified classname. The classname is
prefixed with "Server::Control::" unless it begins with a "+".

=item *

-h|--help - prints a help message using L<Pod::Usage|Pod::Usage>

=item *

-k|--action - calls this on the C<Server::Control::MyServer> object (required)

=item *

Any constructor parameter accepted by C<Server::Control> or the specific
subclass, with underscores replaced by dashes - e.g. --bind-addr,
--wait-for-status-secs

=back

Any parameters passed to C<handle_cli> will be passed to the C<Server::Control>
constructor, but may be overriden by C<@ARGV> options.

In general, any customization to the default command-line handling is best done
in your C<Server::Control> subclass rather than the script itself. For example,
see L<Server::Control::Apache|Server::Control::Apache> and its overriding of
C<_cli_option_pairs>.

Log output is automatically diverted to STDOUT, as would be expected for a CLI.

=back

=head2 Status methods

=over

=item is_running

If the server appears running (the pid file exists and contains a valid
process), returns a L<Proc::ProcessTable::Process|Proc::ProcessTable::Process>
object representing the process. Otherwise returns undef.

=item is_listening

Returns a boolean indicating whether the server is listening to the address and
port specified in I<bind_addr> and I<port>. This is checked to determine
whether a server start or stop has been successful.

=item status

Returns status of server as an integer. Use the following constants to
interpret status:

=over

=item *

C<Server::Control::RUNNING> - Pid file exists and contains a valid process

=item *

C<Server::Control::LISTENING> - Something is listening to the specified bind
address and port

=item *

C<Server::Control::ACTIVE> - Equal to RUNNING & LISTENING

=item *

C<Server::Control::INACTIVE> - Equal to 0 (neither RUNNING nor LISTENING)

=back

=item status_as_string

Returns status as a human-readable string, e.g. "server 'foo' is not running"

=back

=head1 LOGGING

C<Server::Control> uses L<Log::Any|Log::Any> for logging events. See
L<Log::Any|Log::Any> documentation for how to control where logs get sent, if
anywhere.

The exception is L</handle_cli>, which will tell C<Log::Any> to send logs to
STDOUT.

=head1 IMPLEMENTING SUBCLASSES

C<Server::Control> uses L<Moose|Moose>, so ideally subclasses will as well. See
L<Server::Control::Apache|Server::Control::Apache> for an example.

=head2 Subclass methods

=over

=item do_start ()

This actually starts the server - it is called by L</start> and must be defined
by the subclass. Any parameters to L</start> are passed here. If your server is
started via the command-line, you may want to use L</run_system_command>.

=item do_stop ($proc)

This actually stops the server - it is called by L</stop> and may be defined by
the subclass. By default, it will send a SIGTERM to the process. I<$proc> is a
L<Proc::ProcessTable::Process|Proc::ProcessTable::Process> object representing
the current process, as returned by L</is_running>.

=item run_system_command ($cmd)

Runs the specified I<$cmd> on the command line. Adds sudo if necessary (see
L</use_sudo>), logs the command, and throws runtime errors appropriately.

=item validate_server ()

This method is called after the server starts or is HUP'd. It gives the
subclass a chance to validate the server in a particular way. It should return
a boolean indicating whether the server is in a valid state.

The default C<validate_server> uses L</validate_url> and L</validate_regex> to
make a test web request against the server. If these are not provided then it
simply returns true.

=back

=head1 PLUGINS

Because C<Server::Control> uses C<Moose>, it is easy to define plugins that
modify its methods. If a plugin is meant for public consumption, we recommend
that it be implemented as a role and named C<Server::Control::Plugin::*>.

In addition to the methods documented above, the following empty hook methods
are called for plugin convenience:

=over

=item *

successful_start - called when a start() succeeds

=item *

successful_stop - called when a stop() succeeds

=back

C<Server::Control> uses the L<MooseX::Traits|MooseX::Traits> role if it is
installed, so you can call it with C<new_with_traits()>. The default
trait_namespace is C<Server::Control::Plugin>.

For example, here is a role that sends an email whenever a server is
successfully started or stopped:

   package Server::Control::Plugin::EmailOnStatusChange;
   use Moose::Role;
   
   has 'email_status_to' => ( is => 'ro', isa => 'Str', required => 1 );
   
   after 'successful_start' => sub {
       shift->send_email("server started");
   };
   after 'successful_stop' => sub {
       shift->send_email("server stopped");
   };
   
   __PACKAGE__->meta->make_immutable();
   
   sub send_email {
       my ( $self, $subject ) = @_;
   
       ...;
   }
   
   1;

and here's how you'd use it:

   my $apache = Server::Control::Apache->new_with_traits(
       traits          => ['EmailOnStatusChange'],
       email_status_to => 'joe@domain.org',
       conf_file       => '/my/apache/dir/conf/httpd.conf'
   );

=for readme continue

=head1 RELATED MODULES

=over

=item *

L<App::Control|App::Control> - Same basic idea for any application with a pid
file. No features specific to a server listening on a port, and not easily
subclassable, as all commands are handled in a single case statement.

=item *

L<MooseX::Control|MooseX::Control> - A Moose role for controlling applications
with a pid file. Nice extendability. No features specific to a server listening
on a port, and assumes server starts via a command-line (unlike pure-Perl
servers, say). May end up using this role.

=item *

L<Nginx::Control|Nginx::Control>, L<Sphinx::Control|Sphinx::Control>,
L<Lighttpd::Control|Lighttpd::Control> - Modules which use
L<MooseX::Control|MooseX::Control>

=back

=head1 ACKNOWLEDGMENTS

This module was developed for the Digital Media group of the Hearst
Corporation, a diversified media company based in New York City.  Many thanks
to Hearst management for agreeing to this open source release.

=head1 SEE ALSO

L<serverctlp|serverctlp>, L<Server::Control::Apache|Server::Control::Apache>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jonathan Swartz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

