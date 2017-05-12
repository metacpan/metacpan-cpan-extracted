package Supervisord::Client;
$Supervisord::Client::VERSION = '0.22';
use strict;
use warnings;
use LWP::Protocol::http::SocketUnixAlt;
use RPC::XML::Client qw[ $RPC::XML::ERROR ];
use Moo::Lax;
use Carp;
use Safe::Isa;
use Config::INI::Reader;
use URI;

LWP::Protocol::implementor(
    supervisorsocketunix => 'LWP::Protocol::http::SocketUnixAlt' );

has path_to_supervisor_config => (
    is       => 'ro',
    required => 0,
);

has serverurl => (
    is       => 'lazy',
);

has rpc => (
    is      => 'lazy',
    handles => { ua => 'useragent' },
);

has username => (
    is => 'ro',
    required => 0,
);

has password => (
    is => 'ro',
    required => 0,
);


sub _build_serverurl {
    my $self = shift;
    my $hash =
      Config::INI::Reader->read_file( $self->path_to_supervisor_config );
    return $hash->{supervisorctl}{serverurl}
      || croak "couldnt find serverurl in supervisorctl section of "
      . $self->path_to_supervisor_config;
}

sub _build_rpc {
    my $self = shift;
    my $url  = $self->serverurl;
    my $uri = URI->new( $url );
    if( lc($uri->scheme) eq 'unix' ) {
        my $socket_uri = URI->new("supervisorsocketunix:");
        $socket_uri->path_segments( $uri->path_segments, "", "RPC2" );
        $uri = $socket_uri;
    } else {
        $uri->path_segments( $uri->path_segments, "RPC2" );
    }
    my $cli =
      RPC::XML::Client->new( $uri, error_handler => sub { confess @_ } );
    my $ua = $cli->useragent;
    if( $self->username ) {
        $ua->credentials( $uri->host_port, 'default', $self->username, $self->password );
    }
    return $cli;
}

sub BUILD {
    my $self = shift;
    $self->path_to_supervisor_config
      || $self->serverurl
      || croak "path_to_supervisor_config or serverurl required.";
}

our $AUTOLOAD;

sub AUTOLOAD {
    my $remote_method = $AUTOLOAD;
    $remote_method =~ s/.*:://;
    my ( $self, @args ) = @_;
    $self->send_rpc_request("supervisor.$remote_method", @args );
}
sub send_rpc_request {
    my( $self, @params ) = @_;
    my $ret = $self->rpc->send_request( @params );
    return $ret->value if $ret->$_can("value");
    return $ret;
}

1;

=head1 NAME

Supervisord::Client - a perl client for Supervisord's XMLRPC.

=head1 SYNOPSIS

    my $client = Supervisord::Client->new( serverurl => "unix:///tmp/socky.sock" );
    #or
    my $client = Supervisord::Client->new( serverurl => "http://foo.bar:25123" );
    #or
    my $client = Supervisord::Client->new( path_to_supervisor_config => "/etc/supervisor/supervisor.conf" );
    warn $_->{description} for(@{ $client->getAllProcessInfo });
    #or
    warn $_->{description} for(@{ $client->send_rpc_request("supervisor.getAllProcessInfo") });

=head1 DESCRIPTION

This module is for people who are using supervisord (  L<http://supervisord.org/> ) to manage their daemons,
and ran into problems with the http over Unix socket part.

See L<http://supervisord.org/api.html> for the API docs of what the supervisord XMLRPC supports.

=head1 METHODS

=head2 new

Constructor, provided by Moo.

=head2 rpc

Access to the RPC::XML::Client object.

=head2 ua

Access to the LWP::UserAgent object from the RPC::XML::Client

=head2 send_rpc_request( remote_method, @params )


=head2 AUTOLOAD

This module uses AUTOLOAD to proxy calls to send_rpc_request. See synopsis for examples.

=head1 CONSTRUCTOR PARAMETERS

path_to_supervisor_config or serverurl is required.

=over

=item path_to_supervisor_config

optional - ex: /tmp/super.sock

=item serverurl

    optional - in supervisor format, ex: unix:///tmp.super.sock | http://myserver.local:8080



=back

=head1 LICENSE

This library is free software and may be distributed under the same terms as perl itself.

=head1 AUTHOR

Samuel Kaufman L<skaufman@cpan.org>

