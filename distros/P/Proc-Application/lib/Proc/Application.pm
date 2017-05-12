package Proc::Application;

=head1 NAME

Proc::Application - base class for all applications

=head1 SYNOPSIS

 package Program;
 @Program::ISA = qw(Proc::Application);
 sub main { print "Done\n"; }
 package main;
 Program->new->run();

=head1 DESCRIPTION

This is a application code base

=cut

use strict;
use Getopt::ArgvFile;
use Getopt::Long;
use Proc::PID_File;

use constant MAX_CLOSED_DESCRIPTOR => 1;

=head2 new

=cut

sub new
{
    my $class = shift;
    my $this = bless {}, $class;
    $this;
}

=head2 main

=cut

sub main
{
    my $this = shift;
}

=head2 run

=cut

sub run
{
    my $this = shift;
    $this->processCommandOptions;
    $SIG{INT} = $SIG{TERM} = sub { $this || return; $this->DESTROY; exit ( 0 ) };
    $this->log->log ( level => 'notice', message => "start\n" );
    eval { $this->main(); };
    if ( $@ )
    {
	$this->log->error ( $@ );
	warn $@;
    }
    $this->log->log ( level => 'notice', message => "stop\n"  );
}

=head2 DESTROY

=cut

sub DESTROY
{
    my $this = shift;
    foreach my $lock ( values %{ $this->{locks} } )
    {
	next unless $lock;
	$lock->DESTROY();
    }
}

=head2 processCommandOptions

Process options from command line by Getopt::Long && Getopt::ArgvFile

=cut

sub processCommandOptions
{
    my $this = shift;
    Getopt::ArgvFile::argvFile ( default => 1, home => 1 );
    my $optionsDescription = $this->options;
    my $options = ( $this->{options} ||= {} );
    my %getoptOptions = ();
    while ( my ( $optionName, $optionDescription) = each %$optionsDescription )
    {
	my $multiplicity = $optionDescription->{multiplicity};
	$options->{ $optionName } = $optionDescription->{default} || ( $multiplicity ? [] : '' );
	$getoptOptions{ $optionDescription->{template} } = $multiplicity ? $options->{ $optionName } : \ $options->{ $optionName };
	    #$optionDescription->{action} ? $optionDescription->{action} : \ $options->{ $optionName };
    }
    Getopt::Long::GetOptions ( %getoptOptions );
    foreach my $optionName ( map  { $_->{name} } sort { $b->{priority} <=> $a->{priority} }
			     map  { my $result = { priority => $optionsDescription->{ $_ }->{priority} || 0,
						   name     => $_ }; $result } keys %$optionsDescription )
    {
	my $optionDescription = $optionsDescription->{ $optionName };
	my $action = $optionDescription->{action} || next;
	my $optionValue = $options->{ $optionName };
	next unless ( ref ( $optionValue ) ? @$optionValue : $optionValue );
	eval { &$action ( $optionName => $optionValue ); };
	if ( $@ )
	{
	    $this->log->error ( $@ );
	    die $@;
	}
    }
}

=head2 log

Create and return log object ( the Log::Dispatch )

=cut

sub log
{
    my $this = shift;
    use Log::Dispatch;
    $this->{log} ||= new Log::Dispatch;
    $this->{logCounter} ||= 0;
    $this->{log};
}

=head2 options

=cut

sub options
{
    my $this = shift;
    return
    { 'filelog'   => { template     => 'filelog=s',
		       description  => 'setup file name for logging, paramaters format --logfile "filename,minlevel,maxlevel"',
		       multiplicity => 1,
		       priority     => 10,
		       action       => sub { $this->_processFileLog ( @_ ) } },
      'syslog'    => { template     => 'syslog=s',
		       description  => 'setup syslog logging, parameters format "facility,ident,logoptions,minlevel,maxlevel"',
		       multiplicity => 1,
		       priority     => 10,
		       action       => sub { $this->_processSysLog  ( @_ ) } },
      'screenlog' => { template     => 'screenlog=s',
		       description  => 'setup screen logging"',
		       multiplicity => 1,
		       priority     => 1,
		       action       => sub { $this->_processScreenLog  ( @_ ) } },
      'filelock'  => { template     => 'filelock=s',
		       description  => 'setup syslog logging, parameters format "facility,ident,logoptions,minlevel,maxlevel"',
		       multiplicity => 1,
		       priority     => 1,
		       action       => sub { $this->_processFileLock ( @_ ) } },
      'help'      => { template     => 'help',
		       description  => 'this screen',
		       priority     => 100,
		       action       => sub { $this->usage } },
      'detach'    => { template     => 'detach!',
		       description  => 'detach from terminal',
		       priority     => 9,
		       action       => sub { $this->detach  ( @_ ) } },
      'chroot'    => { template     => 'chroot=s',
		       description  => 'chroot to specified path',
		       priority     => 9,
		       action       => sub { $this->chroot  ( @_ ) } },
      'user'      => { template     => 'user=s',
		       description  => 'change uid (euid) to specified user',
		       priority     => 7,
		       action       => sub { $this->changeUser  ( @_ ) } },
      'group'     => { template     => 'group=s',
		       description  => 'change gid (egid) to specified group',
		       priority     => 8,
		       action       => sub { $this->changeGroup  ( @_ ) } },
      'pidfile'   => { template     => 'pidfile=s',
		       description  => 'write pid of process to specified file',
		       priority     => 1,
		       action       => sub { $this->pidfile  ( @_ ) } },
      'debug'     => { template     => 'debug!',
		       description  => 'inc. debug messages of process',
		       priority     => 1 },
    }
}

=head2 description

=cut

sub description
{
    my $this = shift;
    "$0 - description";
}

=head2 usage

=cut

sub usage
{
    my $this = shift;
    my $options = $this->options;
    print STDERR $this->description . "\n\n";
    while ( my ( $key, $value ) = each ( %$options ) )
    {
	print STDERR "$key - " . $value->{description} . "\n"; 
    }
    exit ( 1 );
}

sub _decodeOption
{
    my ( $this, $option ) = @_;
    my @params = map { my @result = split /=/, $_;
		       $result[0] = '' unless defined $result[0];
		       $result[1] = '' if ( ( m/=/ ) && ( ! defined $result[1] ) );
		       @result; } split /:/, $option;
    @params;
}

=head2 _processFileLog

=cut

sub _processFileLog
{
    my ( $this, $option, $params ) = @_;
    use Log::Dispatch::File;
    $params = [ $params ] unless ref $params;
    foreach my $param ( @$params )
    {
	my %params = $this->_decodeOption ( $param || '' );
	my $ident = delete $params{ident};
	$this->log->add
	    ( new Log::Dispatch::File
	      ( name      => 'log' . $this->{logCounter}++,
		callbacks => sub { stFormatLogLine ( $ident, @_ ) },
		%params ) );
    }
}

=head2 _processSysLog

=cut

sub _processSysLog
{
    my ( $this, $option, $params ) = @_;
    use Log::Dispatch::Syslog;
    $params = [ $params ] unless ref $params;
    foreach my $param ( @$params )
    {
	$this->log->add
	    ( new Log::Dispatch::Syslog
	      ( name => 'log' . $this->{logCounter}++,
		$this->_decodeOption ( $param || '' ) ) );
    }
}

=head2 _processScreenLog

=cut

sub _processScreenLog
{
    my ( $this, $option, $params ) = @_;
    use Log::Dispatch::Screen;
    $params = [ $params ] unless ref $params;
    foreach my $param ( @$params )
    {
	$this->log->add
	    ( new Log::Dispatch::Screen
	      ( name => 'log' . $this->{logCounter}++,
		$this->_decodeOption ( $param || '' ) ) );
    }
}

=head2 _processFileLock

=cut

sub _processFileLock
{
    my ( $this, $option, $params ) = @_;
    use Proc::Lock::File;
    $params = [ $params ] unless ref $params;
    foreach my $param ( @$params )
    {
	$this->{logCount} ||= 0;
	$this->{locks}    ||= {};
	$this->{locks}->{ ++$this->{logCount} } = new Proc::Lock::File ( $this->_decodeOption ( $param || '' ),
								         log => $this->log );
	$this->{locks}->{ $this->{logCount} }->set() || die "Can't set lock!\n";
    }
}

=head2 stFormatLogLine

=cut

sub stFormatLogLine
{
    my ( $ident, %params ) = @_;
    $ident = $ident ? " $ident:" : '';
    my $line = $params{message} || '';
    my ( $s, $m, $h, $d, $mon, $y) = localtime(); $mon++; $y += 1900;
    my $time = sprintf ( "%.2d/%.2d/%.4d %.2d:%.2d:%.2d", $d, $mon, $y, $h, $m, $s );
    "$time$ident $line\n";
}

=head2 detach

=cut

sub detach
{
    my $this = shift;
    use IO::Handle;
    use POSIX;
    my $pid = fork;
    defined $pid || die "Can't for for detach: $!\n";
    exit ( 0 ) if $pid;
    for ( 0 .. MAX_CLOSED_DESCRIPTOR )
    {
	$this->log->log ( level => 'debug', message => "*** close fd $_" );
	my IO::Handle $fh = new IO::Handle;
	$fh->fdopen ( $_, 'r' );
	$fh->close;
    }
    chdir '/';
    POSIX::setsid ();
    $this->log->log ( level => 'notice', message => 'detach from terminal' );
}

=head2 chroot

=cut

sub chroot
{
    my ( $this, $option, $params ) = @_;
    $this->log ( level => 'notice', message => "chroot to $params" );
    chroot $params || die "Can't chroot";
    chdir '/';
}

=head2 changeUser

=cut

sub changeUser
{
    my ( $this, $option, $user ) = @_;
    $this->log->log ( level => 'notice', message => "change uid (euid) to $user" );
    ( $user = getpwnam ( $user ) || die "Can't get uid for user $user: $!" )
	unless ( $user =~ /^\d+$/ );
    $< = ( $> = $user );
}

=head2 changeGroup

=cut

sub changeGroup
{
    my ( $this, $option, $group ) = @_;
    $this->log->log ( level => 'notice', message => "change gid (egid) to $group" );
    ( $group = getgrnam ( $group ) || die "Can't get gid for group $group: $!" )
	unless ( $group =~ /^\d+$/ );
    $( = ( $) = $group );
}

=head2 pidfile

=cut

sub pidfile
{
    my ( $this, $option, $pidFileName ) = @_;
    use Proc::PID_File;
    my Proc::PID_File $pidFile = new Proc::PID_File ( path => $pidFileName ) || die "Can't create pidfile $pidFileName: $!";
    $pidFile->init || die "Can't open/create pid file $pidFileName: $!";
    $pidFile->active();
    $this->{options}->{pidfile} = $pidFile;
}

1;
