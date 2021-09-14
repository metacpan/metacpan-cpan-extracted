use strict;
package Net::ClamAV::Client;
# ABSTRACT: A client class for the ClamAV C<clamd> virus scanner daemon
$Net::ClamAV::Client::VERSION = '0.1';
use warnings;
use Moose;
use IO::Socket;
use IO::Handle;
use IO::File;
use Net::ClamAV::Exception::Connect;
use Net::ClamAV::Exception::Command;
use Net::ClamAV::Exception::Result;
use Net::ClamAV::Exception::Other;
use Net::ClamAV::Exception::Unsupported;


has 'socket'  => (is => 'rw');
has 'url'     => (is => 'rw', required => 1);
has 'runningIDsession' => (is => 'rw', isa=>'Int', default=>0);
has 'streamBlockSize' => (is => 'rw', isa=>'Int', default=>4096);

sub _connect
{
  my $self = shift;

  if ($self->url() =~/:/)
  {
    my @url = split /\:/, $self->url();

    $self->socket(IO::Socket->new(
                                  Domain => IO::Socket::AF_INET,
                                  Type   => SOCK_STREAM,
                                  Proto  => "tcp",
                                  PeerHost => $url[0],
                                  PeerPort => $url[1]
                                ))
    || throw  Net::ClamAV::Exception::Connect("Can't open socket: $@");
  }
  else
  {
    $self->socket(IO::Socket->new(
                                  Domain => IO::Socket::AF_UNIX,
                                  Type   => SOCK_STREAM,
                                  Peer => $self->url(),
                                 ))
    || throw  Net::ClamAV::Exception::Connect("Can't open socket: $@");
  }

  $self->socket()->autoflush(1);
}


sub _basicCommand
{
  my $self      = shift;
  my $command   = shift;

  $self->_connect() unless $self->runningIDsession();

  $self->socket()->send($command);
  my $reply = $self->socket()->getline();
  chomp($reply);

  if (length($reply) < 3)
  {
    throw Net::ClamAV::Exception::Command("unknown reply to command \"$reply\"");
  }

  $self->socket()->close() unless $self->runningIDsession();
  return $reply;
}

sub _multiCommand
{
  my $self      = shift;
  my $command   = shift;
  my @reply;

  $self->_connect() unless $self->runningIDsession();
  $self->socket()->send($command);

  while(defined(my $line = $self->socket()->getline()))
  {
    chomp($line);
    if (length($line) < 3)
    {
      throw Net::ClamAV::Exception::Command("unknown reply to command \"$line\"");
    }

    push(@reply,$line);
  }

  $self->socket()->close() unless $self->runningIDsession();
  return @reply;
}

sub _parse_multi_result {
  my ($self,@reply)  = @_;
  my @status;

  for my $r (@reply)
  {
    if (  $r !~ /^(.*):\s+(OK|(\S+)\s+FOUND)$/ )
    {
      throw Net::ClamAV::Exception::Result("Invalid server scanning result \"$r\"");
    }

    my $file = $1;
    my $res = $2;

    if ($res !~ /OK/)
    {
      $res = $3;
    }

    my $stat = {
      file   => $file,
      result => $res
    };

    push (@status,$stat);
  }

  return @status;
}

sub _parse_result {
  my $self    = shift;
  my $result  = shift;

  if (  $result !~ /^(.*):\s+(OK|(\S+)\s+FOUND)$/ )
  {
    throw Net::ClamAV::Exception::Result("Invalid server scanning result \"$result\"");
  }

  my $file = $1;
  my $res = $2;

  if ($res !~ /OK/)
  {
    $res = $3;
  }

  return ($file, $res);
}


sub ping
{
  my $self = shift;

  my $reply = $self->_basicCommand("PING");

  throw Net::ClamAV::Exception::Result("No PONG reply") unless $reply eq "PONG";

  return $reply;
}

sub version
{
  my $self = shift;

  return $self->_basicCommand("VERSION");
}

sub reload
{
  my $self = shift;

  return $self->_basicCommand("RELOAD");
}

sub shutdown
{
  my $self = shift;

  return $self->_basicCommand("SHUTDOWN");
}

sub quit
{
  my $self = shift;

  return $self->shutdown();
}

sub scanLocalPath
{
  my $self = shift;
  my $file = shift;

  throw Net::ClamAV::Exception::Other("file \"$file\" not found") unless ( -e $file );

  my @reply = $self->_multiCommand("nSCAN $file\n");
  my @result= $self->_parse_multi_result(@reply);

  return $result[0];
}

sub scanLocalPathContinous
{
  my $self = shift;
  my $file = shift;

  throw Net::ClamAV::Exception::Other("file \"$file\" not found") unless ( -e $file );

  my @reply = $self->_multiCommand("nCONTSCAN $file\n");
  return $self->_parse_multi_result(@reply);
}

sub scanLocalPathMulti
{
  my $self = shift;
  my $file = shift;

  throw Net::ClamAV::Exception::Other("file \"$file\" not found") unless ( -e $file );

  my @reply = $self->_multiCommand("nMULTISCAN $file\n");
  return $self->_parse_multi_result(@reply);
}

sub scanLocalFile
{
  my $self = shift;
  my $file = shift;

  return $self->scanLocalPath($file);
}

sub stats
{
  throw Net::ClamAV::Exception::Unsupported("stats command not supported");
}

sub scanFileDescriptor
{
  throw Net::ClamAV::Exception::Unsupported("FILDES command not supported");
}

sub startSession
{
  my $self = shift;

  $self->_connect();
  $self->socket()->send("nIDSESSION\n");
  $self->runningIDsession(1);

}

sub runningSession
{
  my $self = shift;

  return $self->runningIDsession();
}

sub endSession
{
  my $self = shift;

  $self->socket()->send("nEND\n");
  $self->socket()->close();
  $self->runningIDsession(0);
}

sub scanStreamFH
{
  my $self   = shift;
  my $handle = shift;

  throw Net::ClamAV::Exception::Other("no file handle given") unless $handle;
  throw Net::ClamAV::Exception::Other("handle is not a IO::Handle") unless ref($handle) eq "IO::Handle";

  $self->_connect() unless $self->runningIDsession();
  $self->socket()->send("nINSTREAM\n");

  my $block;
  while (my $nr=$handle->read($block, $self->streamBlockSize()))
  {
    my $size = pack("N",$nr);
    $self->socket()->send($size);
    $self->socket()->send($block);
  }
  my $size = pack("N",0);
  $self->socket()->send($size);

  my $status=$self->socket()->getline() . "\n";


  if ($status!~/^stream:\s*(.*)\s+FOUND/)
  {
    return;
  }
  my $ret=$1;

  $self->socket()->close() unless $self->runningIDsession();


  return $ret;
}

sub scanStreamFile
{
  my $self = shift;
  my $file = shift;

  my $fh = IO::File->new($file, "r");
  my $handle = IO::Handle->new_from_fd($fh, "r");

  my $status = $self->scanStreamFH($handle);

  $handle->close();

  return $status;
}

sub scanScalar
{
  my $self = shift;
  my $data = shift;

  my $fh = IO::File->new($data, "r");
  my $handle = IO::Handle->new_from_fd($fh, "r");

  return $self->scanStreamFH($handle);
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::ClamAV::Client - A client class for the ClamAV C<clamd> virus scanner daemon

=head1 VERSION

version 0.1

=head1 SYNOPSIS

=head2 Creating a scanner client

    use Net::ClamAV::Client;

    # Use a TCP inet domain socket
    my $scanner = Net::ClamAV::Client->new(url => "localhost:3310");

    # Use a local Unix domain socket:
    $scanner = Net::ClamAV::Client->new(url => "/var/run/clamav/clamd.ctl");

    die("ClamAV daemon not alive")
        if not defined($scanner) or not $scanner->ping();

=head2 Daemon maintenance

    my $scanner = Net::ClamAV::Client->new(url => "localhost:3310");

    my $version = $scanner->version;
                            # Retrieve the ClamAV version string.

    $scanner->reload();     # Reload the malware pattern database.

    $scanner->quit();       # Terminates the ClamAV daemon.
    $scanner->shutdown();   # Likewise.

=head2 Path scanning

    # Scan a single file or a whole directory structure,
    # and stop at the first infected file. For this to work
    # the clamd has to run on the local host:

    my $scanner = Net::ClamAV::Client->new(url => "localhost:3310");
    my @results = $scanner->scanLocalPath("/etc/groups");

=head2 Path scanning (complete)

    # Scan a single file or a whole directory structure,
    # and scan all files without stopping at the first infected one:
    my $scanner = Net::ClamAV::Client->new(url => "localhost:3310");
    my @results2 = $scanner->scanLocalPathContinous("/etc/");

=head2 Other scanning methods

    my $handle;
    my $scanner = Net::ClamAV::Client->new(url => "localhost:3310");
    # Scan a stream, i.e. read from an I/O handle:
    my $result = $scanner->scanStream($handle);

    # Scan a scalar value:
    my $value; # some file in a scalar
    my $result2 = $scanner->scanScalar(\$value);

=head1 DESCRIPTION

B<Net::ClamAV::Client> is a class acting as a client for a ClamAV C<clamd> virus
scanner daemon.  The daemon may run locally or on a remote system as
B<Net::ClamAV::Client> can use both Unix domain sockets and TCP/IP sockets.  The
full functionality of the C<clamd> client/server protocol is supported.

This Module is based on the B<ClamAV::Client> class written by Julian Mehnle <julian@mehnle.net>
which is not developed anymore but everything has been written from scratch.

=head1 Methods

=head2 Constructor

The following constructor is provided:

=over

=item B<new(%options)>: RETURNS Net::ClamAV::Client

Creates a new C<Net::ClamAV::Client> object.

C<%options> is a list of key/value pairs representing any of the following
options:

=over

=item B<url>

A scalar containing the url to the clamd server (e.g. localhost:3310 or /var/run/clamav/clamd.ctl)

=back

=back

=head2 Public Instance Methods

The following public methods are provided:

=head3 B<ping> :  RETURNS SCALAR

Returns B<true> ('PONG') if the ClamAV daemon is alive.  Throws a
Net::ClamAV::Exception otherwise.

=head3 B<version> : RETURNS SCALAR

Returns the Version String of the clamd server. Throws a
Net::ClamAV::Exception otherwise.

=head3 B<reload> : RETURNS SCALAR

Reloads the clamd virus databases and returns B<true> ('RELOADING') when successfull.
Throws a Net::ClamAV::Exception otherwise.

=head3 B<shutdown> : RETURNS SCALAR

Shutdowns the clamd server. Throws a Net::ClamAV::Exception
when unseccessfull.

=head3 B<quit> : RETURNS SCALAR

śame as B<shutdown>

=head3 B<scanLocalPath> : RETURNS HASH

Scan a file or directory given as path. B<Important:> The used clamd
has to run on the local host for this method to work. Clamd will
directly access the given path. Make sure the user running clamd
has access rights to it. Scanning stops when the first virus is
found or all files within path has been scanned.

The Method returns a Hash with attributes B<file> and B<result>.

my $hash = {
  file   => "the filename a virus was found in",
  result => "the result of file"
};

Throws a Net::ClamAV::Exception on error.

=head3 B<scanLocalPathContinous> : RETURNS HASH

Scan a file or directory given as path and do B<not> stop on first virus found.
B<Important:> The used clamd has to run on the local host for this method to work.
Clamd will directly access the given path. Make sure the user running clamd
has access rights to it. Scanning stops when the first virus is
found or all files within path has been scanned.

The Method returns an array of hashes with attributes B<file> and B<result>.

my $hash = {
  file   => "the filename a virus was found in",
  result => "the result of file"
};

Throws a Net::ClamAV::Exception on error.

=head3 B<scanLocalPathMulti> : RETURNS HASH

Scan a file or directory given as path concurrently. B<Important:> The used clamd
has to run on the local host for this method to work. Clamd will
directly access the given path. Make sure the user running clamd
has access rights to it. Scanning stops when the first virus is
found or all files within path has been scanned.

The Method returns an array of hashes with attributes B<file> and B<result>.

my $hash = {
  file   => "the filename a virus was found in",
  result => "the result of file"
};

Throws a Net::ClamAV::Exception on error.

=head3 B<scanLocalFile> : RETURNS HASH

Scan B<one> file. B<Important:> The used clamd
has to run on the local host for this method to work. Clamd will
directly access the given path. Make sure the user running clamd
has access rights to it. Scanning stops when the first virus is
found or all files within path has been scanned.

The Method returns a hashe with attributes B<file> and B<result>.
s
my $hash = {
  file   => "the filename a virus was found in",
  result => "the result of file"
};

Throws a Net::ClamAV::Exception on error.

=head3 B<stats> : RETURNS HASH

Return the stats of the clamd. B<NOT SUPPORTED YET>

Throws a Net::ClamAV::Exception on error.

=head3 B<scanFileDescriptor> : RETURNS HASH

Scans a file given by a file descriptor. B<NOT SUPPORTED YET>

Throws a Net::ClamAV::Exception on error.

=head3 B<startSession>

Starts a session with the clamd server within multiple scan commands can
be issued.

Throws a Net::ClamAV::Exception on error.

=head3 B<runningSession> : RETURNS SCALAR

Checks if a session is running with the clamd server.

Returns 1 if yes, else 0.

=head3 B<endSession>

Ends a session with the clamd server within multiple scan commands can
be issued.

Throws a Net::ClamAV::Exception on error.

=head3 B<scanStreamFH> : RETURNS SCALAR

Scans a file by transmitting it as a stream to the clamd server.
The file is given as a IO::Handle.

The Method returns a SCALAR with attributes B<undef> or B<virusname>.

Throws a Net::ClamAV::Exception on error.

=head3 B<scanStreamFile> : RETURNS SCALAR

Scans a file by transmitting it as a stream to the clamd server.
The file is given as a path.

The Method returns a SCALAR with attributes B<undef> or B<virusname>.

Throws a Net::ClamAV::Exception on error.

=head3 B<scanScalar> : RETURNS SCALAR

Scans a SCALAR by transmitting it as a stream to the clamd server.
The file is given as a path.

The Method returns a SCALAR with attributes B<undef> or B<virusname>.

Throws a Net::ClamAV::Exception on error.

=head1 AUTHOR

Domink Meyer <dmeyer@federationhq.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Dominik Meyer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/Net::ClamAV::Client/>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Dominik Meyer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
