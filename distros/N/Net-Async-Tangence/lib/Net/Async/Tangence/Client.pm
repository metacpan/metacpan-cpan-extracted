#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2010-2015 -- leonerd@leonerd.org.uk

package Net::Async::Tangence::Client;

use strict;
use warnings;

use base qw( Net::Async::Tangence::Protocol Tangence::Client );

our $VERSION = '0.14';

use Carp;

use Future;

use URI::Split qw( uri_split );

=head1 NAME

C<Net::Async::Tangence::Client> - connect to a C<Tangence> server using
C<IO::Async>

=head1 DESCRIPTION

This subclass of L<Net::Async::Tangence::Protocol> connects to a L<Tangence>
server, allowing the client program to access exposed objects in the server.
It is a concrete implementation of the C<Tangence::Client> mixin.

The following documentation concerns this specific implementation of the
client; for more general information on the C<Tangence>-specific parts of this
class, see instead the documentation for L<Tangence::Client>.

=cut

sub new
{
   my $class = shift;
   my %args = @_;

   my $self = $class->SUPER::new( %args );

   # It's possible a handle was passed in the constructor.
   $self->tangence_connected( %args ) if defined $self->read_handle;

   return $self;
}

=head1 PARAMETERS

The following named parameters may be passed to C<new> or C<configure>:

=over 8

=item identity => STRING

The identity string to send to the server.

=item on_error => STRING or CODE

Default error-handling policy for method calls. If set to either of the
strings C<carp> or C<croak> then a CODE ref will be created that invokes the
given function from C<Carp>; otherwise must be a CODE ref.

=back

=cut

sub _init
{
   my $self = shift;
   my ( $params ) = @_;

   $self->identity( delete $params->{identity} );

   $self->SUPER::_init( $params );

   $params->{on_error} ||= "croak";
}

sub configure
{
   my $self = shift;
   my %params = @_;

   if( my $on_error = delete $params{on_error} ) {
      if( ref $on_error eq "CODE" ) {
         # OK
      }
      elsif( $on_error eq "croak" ) {
         $on_error = sub { croak "Received MSG_ERROR: $_[0]" };
      }
      elsif( $on_error eq "carp" ) {
         $on_error = sub { carp "Received MSG_ERROR: $_[0]" };
      }
      else {
         croak "Expected 'on_error' to be CODE reference or strings 'croak' or 'carp'";
      }

      $self->on_error( $on_error );
   }

   $self->SUPER::configure( %params );
}

=head1 METHODS

The following methods documented with a trailing call to C<< ->get >> return
L<Future> instances.

=cut

sub new_future
{
   my $self = shift;
   return $self->loop->new_future;
}

=head2 connect_url

   $rootobj = $client->connect_url( $url, %args )->get

Connects to a C<Tangence> server at the given URL. The returned L<Future> will
yield the root object proxy once it has been obtained.

Takes the following named arguments:

=over 8

=item on_registry => CODE

=item on_root => CODE

Invoked once the registry and root object proxies have been obtained from the
server. See the documentation the L<Tangence::Client> C<tangence_connected>
method.

=back

The following URL schemes are recognised:

=over 4

=cut

sub connect_url
{
   my $self = shift;
   my ( $url, %args ) = @_;

   my ( $scheme, $authority, $path, $query, $fragment ) = uri_split( $url );

   defined $scheme or croak "Invalid URL '$url'";

   if( $scheme =~ m/\+/ ) {
      $scheme =~ s/^circle\+// or croak "Found a + within URL scheme that is not 'circle+'";
   }

   # Legacy name
   $scheme = "sshexec" if $scheme eq "ssh";

   my $f;

   if( $scheme eq "exec" ) {
      # Path will start with a leading /; we need to trim that
      $path =~ s{^/}{};
      # $query will contain args to exec - split them on +
      my @argv = split( m/\+/, $query );
      $f = $self->connect_exec( [ $path, @argv ], %args );
   }
   elsif( $scheme eq "sshexec" ) {
      # Path will start with a leading /; we need to trim that
      $path =~ s{^/}{};
      # $query will contain args to exec - split them on +
      my @argv = split( m/\+/, $query );
      $f = $self->connect_sshexec( $authority, [ $path, @argv ], %args );
   }
   elsif( $scheme eq "tcp" ) {
      $f = $self->connect_tcp( $authority, %args );
   }
   elsif( $scheme eq "unix" ) {
      # Path will start with a leading /; we need to trim that
      $path =~ s{^/}{};
      $f = $self->connect_unix( $path, %args );
   }
   elsif( $scheme eq "sshunix" ) {
      # Path will start with a leading /; we need to trim that
      $path =~ s{^/}{};
      $f = $self->connect_sshunix( $authority, $path, %args );
   }
   else {
      croak "Unrecognised URL scheme name '$scheme'";
   }

   return $f->then( sub {
      my $on_root = $args{on_root};

      my $root_f = $self->new_future;

      $self->tangence_connected( %args,
         on_root => sub {
            my ( $root ) = @_;

            $on_root->( $root ) if $on_root;
            $root_f->done( $root );
         },
      );

      $root_f;
   });
}

=item * exec

Directly executes the server as a child process. This is largely provided for
testing purposes, as the server will only run for this one client; it will
exit when the client disconnects.

 exec:///path/to/command?with+arguments

The URL's path should point to the required command, and the query string will
be split on C<+> signs and used as the arguments. The authority section of the
URL will be ignored, so may be left empty.

=cut

sub connect_exec
{
   my $self = shift;
   my ( $command, %args ) = @_;

   my $loop = $self->get_loop;

   pipe( my $myread, my $childwrite ) or croak "Cannot pipe - $!";
   pipe( my $childread, my $mywrite ) or croak "Cannoe pipe - $!";

   $loop->spawn_child(
      command => $command,

      setup => [
         stdin  => $childread,
         stdout => $childwrite,
      ],

      on_exit => sub {
         print STDERR "Child exited unexpectedly\n";
      },
   );

   $self->configure(
      read_handle  => $myread,
      write_handle => $mywrite,
   );

   Future->done;
}

=item * sshexec

A convenient wrapper around the C<exec> scheme, to connect to a server running
remotely via F<ssh>.

 sshexec://host/path/to/command?with+arguments

The URL's authority section will give the SSH server (and optionally
username), and the path and query sections will be used as for C<exec>.

(This scheme is also available as C<ssh>, though this name is now deprecated)

=cut

sub connect_sshexec
{
   my $self = shift;
   my ( $host, $argv, %args ) = @_;

   $self->connect_exec( [ "ssh", $host, @$argv ], %args );
}

=item * tcp

Connects to a server via a TCP socket.

 tcp://host:port/

The URL's authority section will be used to give the server's hostname and
port number. The other sections of the URL will be ignored.

=cut

sub connect_tcp
{
   my $self = shift;
   my ( $authority, %args ) = @_;

   my ( $host, $port ) = $authority =~ m/^(.*):(.*)$/;

   $self->connect(
      host     => $host,
      service  => $port,
   );
}

=item * unix

Connects to a server via a UNIX local socket.

 unix:///path/to/socket

The URL's path section will give the path to the local socket. The other
sections of the URL will be ignored.

=cut

sub connect_unix
{
   my $self = shift;
   my ( $path, %args ) = @_;

   $self->connect(
      addr => {
         family   => 'unix',
         socktype => 'stream',
         path     => $path,
      },
   );
}

=item * sshunix

Connects to a server running remotely via a UNIX socket over F<ssh>.

 sshunix://host/path/to/socket

(This is implemented by running F<perl> remotely and sending it a tiny
self-contained program that connects STDIN/STDOUT to the given UNIX socket
path. It requires that the server has F<perl> at least version 5.6 available
in the path simply as C<perl>)

=cut

# A tiny program we can run remotely to connect STDIN/STDOUT to a UNIX socket
# given as $ARGV[0]
use constant _NC_MICRO => <<'EOPERL';
use Socket qw( AF_UNIX SOCK_STREAM pack_sockaddr_un );
use IO::Handle;
socket(my $socket, AF_UNIX, SOCK_STREAM, 0) or die "socket(AF_UNIX): $!\n";
connect($socket, pack_sockaddr_un($ARGV[0])) or die "connect $ARGV[0]: $!\n";
my $fd = fileno($socket);
$socket->blocking(0); $socket->autoflush(1);
STDIN->blocking(0); STDOUT->autoflush(1);
my $rin = "";
vec($rin, 0, 1) = 1;
vec($rin, $fd, 1) = 1;
print "READY";
while(1) {
   select(my $rout = $rin, undef, undef, undef);
   if(vec($rout, 0, 1)) {
      sysread STDIN, my $buffer, 8192 or last;
      print $socket $buffer;
   }
   if(vec($rout, $fd, 1)) {
      sysread $socket, my $buffer, 8192 or last;
      print $buffer;
   }
}
EOPERL

sub connect_sshunix
{
   my $self = shift;
   my ( $host, $path, %args ) = @_;

   # Tell perl we're going to send it a program on STDIN
   $self->connect_sshexec( $host, [ 'perl', '-', $path ], %args )
   ->then( sub {
      $self->write( _NC_MICRO . "\n__END__\n" );
      my $f = $self->new_future;

      $self->configure( on_read => sub {
         my ( $self, $buffref, $eof ) = @_;
         return 0 unless $$buffref =~ s/READY//;
         $self->configure( on_read => undef );
         $f->done;
         return 0;
      } );

      return $f;
   });
}

=back

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
