package Proc::Application::Daemon;

=head1 NAME

Proc::Application::Daemon - daemon class based on Proc::Application;

=head1 SYNOPSIS

 package Program;
 use Proc::Application::Daemon;
 use base qw(Proc::Application::Daemon);
 sub handler 
 {
     my ( $his, $clientSocket ) = @_;
     $this->socket->print ( 'Done' );
     $this->log->warning ( 'warning' );
     die "Error";
 }
 package main;
 Program->new->run();


=head1 DESCRIPTION

daemon class based on Proc::Application;

=cut

use strict;
use Proc::Application;
use base qw(Proc::Application);
use POSIX;
use Errno;

use constant FORK_COUNT => 10;

=head2 new

A construtror, setup childs and childCount

=cut

sub new
{
    my $class = shift;
    my $this  = $class->SUPER::new ( @_ );
    $this->{childs} ||= {};
    $this->{childCount} ||= 0;
    $this;
}

=head2 options

Add mode (fork|single|prefork=[count]) and socket (domain=unix|inet|ssl:all_io::socket:: parameter) options

=cut

sub options
{
    my $this = shift;
    my $options = $this->SUPER::options();
    $options->{mode}   = { template     => 'mode=s', #fork|prefork|single | =count
			   description  => 'fork|single|prefork=count',
			   default      => 'fork',
			   action       => sub { $this->processModeParameter ( @_ ) } };
    $options->{socket} = { template     => 'socket=s',
			   description  => 'parameters for init socket',
			   priority     => 8,
			   action       => sub { $this->processSocketCreate ( @_ ) } };
    $options;
}

=head2 processSocketCreate

Handler for socket option. Create new socket and store it to $object->{socket}

=cut

sub processSocketCreate
{
    my ( $this, $option, $params ) = @_;
    my %params       = $this->_decodeOption ( $params );
    my $socketDomain = delete $params{domain} || die "Your must setup domain parameter for socket";
    my $socketClass  = 'IO::Socket::' .
	( { inet => 'INET', unix => 'UNIX', ssl => 'SSL' }->{ $socketDomain } || die "Error socket domain: $socketDomain" );
    eval "use $socketClass;"; die $@ if $@;
    $this->{mainSocket} = $socketClass->new ( %params ) || die "Can't create socket: $!";
}

=head2 processModeParameter

Child for 'prefork=count' mode and setup preforkCount option

=cut

sub processModeParameter
{
    my ( $this, $option, $value ) = @_;
    my ( $mode, $count ) = split /=/, $value;
    $mode eq 'prefork' || return;
    $this->{options}->{mode} = $mode;
    $count ||= FORK_COUNT;
    $count =~ /^\d+$/ || die "Your must setup numeric value for prefork childs count";
    $this->{options}->{preforkcount} = $count;
}

=head2 socket

Return a client socket from $object->{socket}

=cut

sub socket
{
    my $this = shift;
    $this->{socket};
}

=head2 mainSocket

Return a main daemon socket from $object->{socket}

=cut

sub mainSocket
{
    my $this = shift;
    $this->{mainSocket};
}

=head2 done

You must return 'true' for end main loop

=cut

sub done
{
    0;
}

=head2 mainHandler

Call handler() method with $cliendSocket atrument, log the errors of execution and close client socket at exit

=cut

sub mainHandler
{
    my ( $this, $childSocket ) = @_;
    eval { $this->handler () };
    $this->log->warning ( $@ ) if $@;
    $childSocket && $childSocket->close();
}

=head2 handler

Real work method, get $this and $clientSocket argumentds.

=cut

sub handler
{
    my $this = shift;
    1;
}

=head2 childs

Return a hash reference of childs with keys with pids

=cut

sub childs
{
    my $this = shift;
    $this->{childs};
}

=head2 processSigChild

SIGCHLD processor. Get a child pid by waitpid() and delete it from childs()

=cut

sub processSigChild
{
    my $this = shift || return;

    while ( my $pid = waitpid ( -1, WNOHANG ) )
    {
	if ( $pid == -1 ) # process errors
	{
	    next if $! == Errno::EINTR;
	    last if $! == Errno::ECHILD;
	    $this->log->error ( "waitpid() error: $!" );
	    last;
	}

	#$this->done && last;
	$this->{childCount}-- if $this->{childCount};
	delete $this->{childs}->{ $pid } || $this->log->warning ( "Unknown child $pid" );
    }

    $SIG{CHLD} = sub { $this || return; $this->processSigChild };
}

=head2 forkFunction

Get three code refs ( for run at parent, child and error fork sitiations ), fork process and
execute parameters functions. Store pid of new process at childs(), exit(0) at child after 
execute of child function, log fork error and sleep(1) after fork error.
funtions

=cut

sub forkFunction
{
    my ( $this, $parentFunction, $childFunction, $errorFunction ) = @_;
    if  ( my $pid = fork() )
    {
	$this->{childs}->{ $pid } = 1;
	&$parentFunction() if $parentFunction;
    }
    elsif ( defined $pid )
    {
	&$childFunction()  if $childFunction;
	exit ( 0 );
    }
    else
    {
	$this->log->error ( "fock failed(): $!" );
	&$errorFunction() if &$errorFunction();
	sleep ( 1 );
    }
}

=head2 threadFunction

=cut

sub threadFunction
{
    my ( $this, $parentFunction, $childFunction, $errorFunction ) = @_;
    if  ( my $pid = fork() )
    {
	$this->{childs}->{ $pid } = 1;
	&$parentFunction() if $parentFunction;
    }
    elsif ( defined $pid )
    {
	&$childFunction()  if $childFunction;
	exit ( 0 );
    }
    else
    {
	$this->log->error ( "fock failed(): $!" );
	&$errorFunction() if &$errorFunction();
	sleep ( 1 );
    }
}

=head2 realMain

Main loop. accept() the new connection, and fork (if fork more) and pass execution to mainHandler

=cut

sub realMain
{
    my $this = shift;
    my $mode = $this->{options}->{mode};
    while ( ! $this->done() )
    {
	my $mainSocket  = $this->mainSocket();

	my $childSocket = $this->{socket} = $mainSocket->accept;

	unless ( $childSocket )
	{
	    $this->log->error ( "accept() failed: $!" );
	    next;
	}

	if ( $mode eq 'fork' )
	{
	    $this->forkFunction ( sub { $childSocket->close() }, sub { $mainSocket->close(); $this->mainHandler (); } );
	}
	elsif ( $mode eq 'thread' )
	{
	    $this->threadFunction ( sub { $childSocket->close() }, sub { $mainSocket->close(); $this->mainHandler (); } );
	}
	elsif ( $mode eq 'single' || $mode eq 'prefork' || $mode eq 'threadpool' )
	{
	    $this->mainHandler ( $childSocket );
	}
    }
}

=head2 main

Prefork processes if prefork mode, loop up for preforked childs count and call realMain()

=cut

sub main
{
    my $this = shift || return;
    my $mode = $this->{options}->{mode};
    $SIG{CHLD} = sub { $this || return; $this->processSigChild } if $mode =~ /fork/;
    $this->mainSocket || die "You must setup socket parameter";
    $this->realMain () unless $mode eq 'prefork' || $mode eq 'threadpool';
    if ( $mode eq 'prefork' )
    {
	while ( ! $this->done )
	{
	    while ( $this->{childCount} < $this->{options}->{preforkcount} )
	    {
		$this->forkFunction ( sub { $this->{childCount}++ }, sub { $this->realMain(); } );
	    }
	    sleep ( 1 );
	}
    }
    else # threadpool
    {
	while ( ! $this->done )
	{
	    while ( $this->{threadCount} < $this->{options}->{threadpoolcount} )
	    {
		$this->threadFunction ( sub { $this->{threadCount}++ }, sub { $this->realMain(); } );
	    }
	    sleep ( 1 );
	}
	
    }
}

=head2 DESTROY

Send TERM signal to all childs and call parent DESTROY()

=cut

sub DESTROY
{
    my $this = shift;
    foreach my $pid ( keys %{ $this->{childs} } )
    {
	kill TERM => $pid;
    }
    $this->SUPER::DESTROY();
}

=head2 Log Debug Error Fatal Run Options

for compatibility with Net::Daemon

=cut

sub Log
{
    my ( $this, $level, $message, @args ) = @_;
#    warn "depricated call Log() from " . ( join ' ', caller() ) . "\n";
    $message = sprintf ( $message, @args ) if @args;
    $this->log->$level ( $message );
}

sub Debug
{
    my ( $this, $message, @args ) = @_;
#    warn "depricated call Log() from " . ( join ' ', caller() ) . "\n";
    $message = sprintf ( $message, @args ) if @args;
    $this->log->error ( $message );
}

sub Fatal
{
    my ( $this, $message, @args ) = @_;
#    warn "depricated call Log() from " . ( join ' ', caller() ) . "\n";
    $message = sprintf ( $message, @args ) if @args;
    $this->log->error ( $message );
    die $message;
}

sub Run
{
    my $this = shift;
#    warn "depricated call Log() from " . ( join ' ', caller() );
    $this->handler ();
}

sub Options
{
    my $this = shift;
#    warn "depricated call Log() from " . ( join ' ', caller() );
    $this->options ( @_ );
}

sub Bind
{
    my $this = shift;
#    warn "depricated call Log() from " . ( join ' ', caller() );
    $this->run ( @_ );
}

1;
