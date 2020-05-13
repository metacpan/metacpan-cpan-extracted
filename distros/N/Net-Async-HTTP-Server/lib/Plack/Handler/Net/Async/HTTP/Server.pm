#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2013-2014 -- leonerd@leonerd.org.uk

package Plack::Handler::Net::Async::HTTP::Server;

use strict;
use warnings;

use Net::Async::HTTP::Server::PSGI;
use IO::Async::Loop;

our $VERSION = '0.13';

=head1 NAME

C<Plack::Handler::Net::Async::HTTP::Server> - HTTP handler for Plack using L<Net::Async::HTTP::Server>

=head1 SYNOPSIS

 use Plack::Handler::Net::Async::HTTP::Server;

 my $handler = Plack::Handler::Net::Async::HTTP::Server->new(
    listen => [ ":8080" ],
 );

 sub psgi_app { ... }

 $handler->run( \&psgi_app );

=head1 DESCRIPTION

This module allows L<Plack> to run a L<PSGI> application as a standalone
HTTP daemon under L<IO::Async>, by using L<Net::Async::HTTP::Server>.

 plackup -s Net::Async::HTTP::Server --listen ":8080" application.psgi

This is internally implemented using L<Net::Async::HTTP::Server::PSGI>;
further information on environment etc.. is documented there.

If L<IO::Async::SSL> is available, this handler supports accepting connections
via C<https>

 plackup -s Net::Async::HTTP::Server --ssl ...

Or per-listen argument by appending C<:SSL>, as

 plackup -s Net::Async::HTTP::Server --listen ":8443:SSL" ...

Any other options whose names start C<ssl_> will be passed on to the SSL
listen method.

=cut

=head1 METHODS

=cut

=head2 $handler = Plack::Handler::Net::Async::HTTP::Server->new( %args )

Returns a new instance of a C<Plack::Handler::Net::Async::HTTP::Server>
object. Takes the following named arguments:

=over 4

=item listen => ARRAY of STRING

Reference to an array containing listen string specifications. Each string
gives a port number and optional hostname, given as C<:port> or C<host:port>.

=item server_ready => CODE

Reference to code to invoke when the server is set up and listening, ready to
accept connections. It is invoked with a HASH reference containing the
following details:

 $server_ready->( {
    host            => HOST,
    port            => SERVICE,
    server_software => NAME,
 } )

=item socket => STRING

Gives a UNIX socket path to listen on, instead of a TCP socket.

=item queuesize => INT

Optional. If provided, sets the C<listen()> queue size for creating listening
sockets. If missing, a default of 10 is used.

=back

=cut

sub new
{
   my $class = shift;
   my %opts = @_;

   delete $opts{host};
   delete $opts{port};
   delete $opts{socket};

   my $self = bless {
      map { $_ => delete $opts{$_} } qw( listen server_ready queuesize ),
   }, $class;

   # Grab all of the SSL options
   $self->{ssl} = 1 if exists $opts{ssl}; delete $opts{ssl};
   $self->{$_} = delete $opts{$_} for grep m/^ssl_/, keys %opts;

   keys %opts and die "Unrecognised keys " . join( ", ", sort keys %opts );

   return $self;
}

=head2 $handler->run( $psgi_app )

Creates the HTTP-listening socket or sockets, and runs the given PSGI
application for received requests.

=cut

sub run
{
   my $self = shift;
   my ( $app ) = @_;

   my $loop = IO::Async::Loop->new;
   my $queuesize = $self->{queuesize} || 10;

   foreach my $listen ( @{ $self->{listen} } ) {
      my $httpserver = Net::Async::HTTP::Server::PSGI->new(
         app => $app,
      );

      $loop->add( $httpserver );

      # IPv6 addresses contain colons. They'll be wrapped in [] brackets
      my $host;
      my $path;

      if( $listen =~ s/^\[([0-9a-f:]+)\]://i ) {
         $host = $1;
      }
      elsif( $listen =~ s/^([^:]+?):// ) {
         $host = $1;
      }
      elsif( $listen =~ s/^:// ) {
         # OK
      }
      else {
         $path = $listen;
      }

      if( defined $path ) {
         require IO::Socket::UNIX;

         unlink $path if -e $path;

         my $socket = IO::Socket::UNIX->new(
            Local  => $path,
            Listen => $queuesize,
         ) or die "Cannot listen on $path - $!";

         $httpserver->configure( handle => $socket );
      }
      else {
         my ( $service, $ssl ) = split m/:/, $listen;
         $ssl ||= $self->{ssl};

         my %SSL_args;
         if( $ssl ) {
            require IO::Async::SSL;
            %SSL_args = (
               extensions => [qw( SSL )],
            );

            foreach my $key ( grep m/^ssl_/, keys %$self ) {
               my $val = $self->{$key};
               # IO::Async::Listener extension wants uppercase "SSL"
               $key =~ s/^ssl/SSL/;

               $SSL_args{$key} = $val;
            };
         }

         $httpserver->listen(
            host     => $host,
            service  => $service,
            socktype => "stream",
            queuesize => $queuesize,

            %SSL_args,

            on_notifier => sub {
               $self->{server_ready}->( {
                  host            => $host,
                  port            => $service,
                  proto           => $ssl ? "https" : "http",
                  server_software => ref $self,
               } ) if $self->{server_ready};
            },
         )->get;
      }
   }

   $loop->run;
}

=head1 SEE ALSO

=over 4

=item *

L<Net::Async::HTTP::Server> - serve HTTP with L<IO::Async>

=item *

L<Plack> - Perl Superglue for Web frameworks and Web Servers (PSGI toolkit)

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
