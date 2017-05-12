package P2P::Transmission::Remote;

use strict;
use 5.8.1;
our $VERSION = '0.02';

use Carp;
use JSON::XS;
use LWP::UserAgent;
use URI;

use Moose;
use Moose::Util::TypeConstraints;

subtype 'Uri'
    => as 'Object'
    => where { $_->isa('URI') };

coerce 'Uri'
    => from 'Object'
        => via { $_->isa('URI')
                     ? $_ : Params::Coerce::coerce( 'URI', $_ ) }
    => from 'Str'
        => via { URI->new( $_, 'http' ) };

has url => (
    is => 'rw',
    isa => 'Uri',
    default => sub { URI->new("http://localhost:9091/") },
    lazy => 1,
    coerce => 1,
);

has user_agent => (
    is => 'rw',
    isa => 'LWP::UserAgent',
    default => sub { LWP::UserAgent->new },
    lazy => 1,
);

has username => (
    is => 'rw',
    isa => 'Str',
);

has password => (
    is => 'rw',
    isa => 'Str',
);

sub _prepare_auth {
    my $self = shift;
    if ( $self->username && $self->password ) {
        # set Digest auth credentials
        $self->user_agent->credentials( $self->url->host_port, "Transmission RPC Server", $self->username, $self->password );
    }
}

sub _request {
    my($self, $method, $args) = @_;

    my $url = $self->url . "transmission/rpc";

    my $req = HTTP::Request->new( POST => $url );
    $req->header( Accept => "application/json, text/javascript, */*" );
    $req->header( "Content-Type" => "application/json" );

    $self->_prepare_auth;

    my $body = JSON::XS::encode_json({
        method => $method,
        arguments => $args,
    });

    $req->header( "Content-Length" => length($body) );
    $req->content($body);

    my $ua  = $self->user_agent;
    my $res = $ua->request( $req );

    my $result = JSON::XS::decode_json( $res->content );

    if ($result->{result} ne 'success') {
        croak $result->{result};
    }

    return $result->{arguments};
}

sub _cmd_torrents {
    my($self, $methods, @torrents) = @_;
    $self->_request($methods, { ids => [ map $_->{id}, @torrents ] });
}

sub torrents {
    my $self = shift;

    my $res = $self->_request("torrent-get", {
        fields => [ "addedDate","announceURL","comment","creator","dateCreated",
                    "downloadedEver","error","errorString","eta","hashString","haveUnchecked","haveValid",
                    "id","isPrivate","leechers","leftUntilDone","name","peersGettingFromUs","peersKnown",
                    "peersSendingToUs","rateDownload","rateUpload","seeders","sizeWhenDone","status","swarmSpeed",
                    "totalSize","uploadedEver" ],
    });

    return @{ $res->{torrents} };
}

sub start {
    my $self = shift;
    $self->_cmd_torrents("torrent-start", @_);
}

sub stop {
    my $self = shift;
    $self->_cmd_torrents("torrent-stop", @_);
}

sub remove {
    my $self = shift;
    $self->_cmd_torrents("torrent-remove", @_);
}

1;
__END__

=encoding utf-8

=for stopwords API url

=head1 NAME

P2P::Transmission::Remote - Control Transmission using its Remote API

=head1 SYNOPSIS

  use P2P::Transmission::Remote;

  my $client = P2P::Transmission::Remote->new;
  for my $torrent ($client->torrents) {
      print $torrent->{name};
      $client->stop($torrent);
  }

=head1 DESCRIPTION

P2P::Transmission::Remote is a client module to control torrent
software Transmission using its Remote API. You need to enable its
Remote and allows access from your client machine (usually localhost).

=head1 METHODS

=over 4

=item url

Gets and sets the URL of Transmission Remote API. Defaults to I<http://localhost:9091/>.

=item user_agent

Gets and sets the User Agent object to make API calls.

=item torrents

  my @torrents = $client->torrents;

Gets the list of Torrent data.

=item start, stop, remove

  $client->start(@torrents);
  $client->stop(@torrents);
  $client->remove(@torrents);

Starts, stops and removes the torrent transfer.

=item upload

  $client->upload($torrent_path);

Adds a new torrent by uploading the file.

=back

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<P2P::Transmission>

=cut
