package RPC::ExtDirect::Server::Util;

use strict;
use warnings;
no  warnings 'uninitialized';   ## no critic

use Carp;
use Socket;
use Getopt::Std;
use Exporter;

use RPC::ExtDirect::Server;

use base 'Exporter';

our @EXPORT = qw/
    maybe_start_server
    start_server
    stop_server
/;

### PRIVATE PACKAGE SUBROUTINES ###
#
# Internal use only.
#

{
    my ($server_pid, $server_host, $server_port, $dont_stop);
    
    sub get_server_pid { $server_pid };
    sub set_server_pid { $server_pid = shift; };
    
    sub get_server_host { $server_host };
    sub set_server_host { $server_host = shift };
    
    sub get_server_port { $server_port };
    sub set_server_port { $server_port = shift; };
    
    sub get_no_shutdown { $dont_stop };
    sub no_shutdown     { $dont_stop = shift; };
}

### EXPORTED PUBLIC PACKAGE SUBROUTINE ###
#
# See if a host and port were given in the @ARGV, and start a new
# server instance if not.
#

sub maybe_start_server {
    if ( @ARGV ) {
        my %opt;
        
        getopts('h:p:fes:t:l:', \%opt);
        
        if ( $opt{p} ) {
        
            # If a port is given but not the host name,
            # we assume localhost
            my $host = $opt{h} || '127.0.0.1';
            my $port = $opt{p};
            
            return wantarray ? ($host, $port) : "$host:$port";
        }
        
        # Not quoting $opt{s} makes my text editor lose its mind ;)
        push @_, static_dir     => $opt{'s'} if $opt{'s'};
        push @_, foreground     => 1         if $opt{f};
        push @_, enbugger       => 1         if $opt{e};
        push @_, enbugger_timer => $opt{t}   if defined $opt{t};    
        push @_, host           => $opt{h}   if defined $opt{h};
        push @_, port           => $opt{l}   if defined $opt{l};
    }
    
    return start_server( @_ );
}

### EXPORTED PUBLIC PACKAGE SUBROUTINE ###
#
# Start an RPC::ExtDirect::Server instance, wait for it to bind
# to a port and return the host and port number.
# If an instance has already been started, return its parameters
# instead of starting a new one.
#

sub start_server {
    my (%arg) = @_;
    
    {
        my $host = get_server_host;
        my $port = get_server_port;
        
        if ( $port ) {
            return wantarray ? ($host, $port) : "$host:$port";
        }
    }
    
    # This parameter is used for internal testing
    my $sleep          = delete $arg{sleep};
    my $foreground     = delete $arg{foreground};
    my $enbugger       = delete $arg{enbugger};
    my $enbugger_timer = delete $arg{set_timer};
    my $timeout        = delete $arg{timeout} || 30;
    
    # Debug flag is checked below to avoid printing the banner
    my $server_debug = $arg{config} ? $arg{config}->debug : $arg{debug};
    
    # We default to verbose exceptions, which is against Ext.Direct spec
    # but feels somewhat saner and is better for testing
    $arg{verbose_exceptions} = 1 unless defined $arg{verbose_exceptions};
    
    if ( $enbugger ) {
        local $@;
        eval "require Enbugger";
    }
    
    # Interactive start means we're not forking but running the server
    # in the current process. Useful for Enbugging.
    if ( $foreground ) {
        if ( $enbugger_timer ) {
            my $old_alarm = $SIG{ALRM};
            
            $SIG{ALRM} = sub {
                alarm 0;
                $SIG{ALRM} = $old_alarm;
                Enbugger->stop;
            };
            
            alarm $enbugger_timer;
        }
        
        do_start_server(
            %arg,
            
            after_listener => sub {
                my ($self) = @_;
                
                my $host = $self->host;
                my $port = $self->port;
                
                print ref($self)." is listening on $host:$port\n"
                    unless $server_debug;
            }
        );
        
        # This should be unreachable, but just in case
        exit 0;
    }

    my ($pid, $pipe_rd, $pipe_wr);
    pipe($pipe_rd, $pipe_wr) or die "Can't open pipe: $!";

    if ( $pid = fork ) {
        close $pipe_wr;
        local $SIG{CHLD} = sub { waitpid $pid, 0 };

        # Wait until the kid starts up, but don't block forever either
        my ($host, $port) = eval {
            local $SIG{ALRM} = sub { die "alarm\n" };
            alarm $timeout;
            
            my ($host, $port) = split /:/, <$pipe_rd>;
            close $pipe_rd;
            
            alarm 0;
            
            ($host, $port + 0); # Easier than chomp
        };
        
        if ( my $err = $@ ) {
            # If timed out, try to clean up the kid anyway
            eval { kill 2, $pid };
            
            croak $err eq "alarm\n" ? "Timed out waiting for " .
                                      "the server instance to start " .
                                      "after $timeout seconds"
                :                     $err
                ;
        }
        
        set_server_pid($pid);
        set_server_host($host);
        set_server_port($port);

        return wantarray ? ($host, $port)
             :             "$host:$port"
             ;
    }
    elsif ( defined $pid && $pid == 0 ) {
        close $pipe_rd;

        srand;
        
        sleep $sleep if $sleep;
        
        do_start_server(
            %arg,
            
            after_listener => sub {
                my $self = shift;
        
                my $host = inet_ntoa inet_aton $self->host;
                my $port = $self->port;

                print $pipe_wr "$host:$port\n";
                close $pipe_wr;
                
                my $after_setup_listener
                    = $self->{_old_after_setup_listener};
        
                $after_setup_listener->($self, @_)
                    if $after_setup_listener;
            }
        );

        # Should be unreachable, just in case
        exit 0;
    }
    else {
        croak "Can't fork: $!";
    };

    return;
}

### EXPORTED PUBLIC PACKAGE SUBROUTINE ###
#
# Stop previously started server instance
#

sub stop_server {
    my ($pid) = @_;

    $pid = get_server_pid unless defined $pid;

    kill 2, $pid if defined $pid;

    set_server_port(undef);
    set_server_pid(undef);
}

############## PRIVATE METHODS BELOW ##############

### PRIVATE PACKAGE SUBROUTINE ###
#
# Try to start the server, re-rolling port randomizer
# if the old port is taken
#

sub do_start_server {
    my (%arg) = @_;
    
    my $forced_port    = defined $arg{port};
    my $after_listener = delete $arg{after_listener};
    my $server_class   = delete $arg{server_class} ||
                                'RPC::ExtDirect::Server';

    if ( !$forced_port ) {
       $arg{port} = random_port();
    }

    my $server = $server_class->new(%arg);
    
    # TODO This is a dirty hack - find a better way of
    # injecting after_setup_listener. Maybe send a patch
    # to HTTP::Server::Simple maintainer to make this easier?
    if ( $after_listener ) {
        $server->{_old_after_setup_listener}
            = $server_class->can('after_setup_listener');

        no strict 'refs';
        *{$server_class.'::after_setup_listener'} = $after_listener;
    }

    # If the port is taken, reroll the random generator and try again
    do {
        eval { $server->run() };

        # If the port was forced by the caller, punt
        croak "$@\n" if $forced_port && $@;

        $server->port( random_port() );
    }
    while ( $@ );
    
    return 1; # This should be unreachable
}

### PRIVATE PACKAGE SUBROUTINE ###
#
# Generate a random port for the server to listen on
#

sub random_port { 30000 + int rand 10000 };

# Ensure that the server is stopped cleanly at exit
END { stop_server unless get_no_shutdown }

1;
