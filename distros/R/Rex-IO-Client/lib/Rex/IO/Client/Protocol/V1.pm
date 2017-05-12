#
# (c) Jan Gehring <jan.gehring@gmail.com>
#
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:

package Rex::IO::Client::Protocol::V1;

use strict;
use warnings;

our $VERSION = '0.6'; # VERSION

use attributes;

use JSON::XS;
use Mojo::UserAgent;
use Data::Dumper;
use Mojo::JSON;

sub new {
    my $that  = shift;
    my $proto = ref($that) || $that;
    my $self  = {@_};

    bless( $self, $proto );

    $self->{endpoint} ||= "http://127.0.0.1:3000";

    return $self;
}

sub endpoint : lvalue {
    my ($self) = @_;
    $self->{endpoint};
}

sub get_plugins {
    my ($self) = @_;
    $self->_get("/plugins")->res->json;
}

sub auth {
    my ( $self, $user, $pass ) = @_;
    my ( $proto, $endpoint ) =
      ( $self->{endpoint} =~ m/^(https?:\/\/).*\@(.*)$/ );

    my $ref = $self->_ua->post( "$proto$user:$pass\@$endpoint/1.0/user/login",
        json => {} )->res->json;

    if ( $ref->{ok} == Mojo::JSON->true ) {
        return $ref->{data};
    }

    return 0;
}

sub _ua {
    my ($self) = @_;
    if ( $self->{ua} ) {
        return $self->{ua};
    }

    my $ua = Mojo::UserAgent->new;

    if ( $self->{ssl} ) {
        $ua->ca( $self->{ssl}->{ca} );
        $ua->cert( $self->{ssl}->{cert} );
        $ua->key( $self->{ssl}->{key} );
    }

    $self->{ua} = $ua;
    return $self->{ua};
}

sub _get {
    my ( $self, $url, $qry_string_ref ) = @_;

    if ( ref $qry_string_ref ) {
        $url .= "?";
        for my $key ( keys %{$qry_string_ref} ) {
            $url .= "\&$key=$qry_string_ref->{$key}";
        }
    }
    elsif ($qry_string_ref) {
        $url .= "?$qry_string_ref";
    }

    $self->_ua->get( $self->endpoint . $url );
}

sub _post {
    my ( $self, $url, $post ) = @_;
    $self->_ua->post( $self->endpoint . $url, json => $post );
}

sub _put {
    my ( $self, $url, $put ) = @_;
    $self->_ua->put( $self->endpoint . $url, $self->_json->encode($put) );
}

sub _list {
    my ( $self, $url ) = @_;
    my $tx = $self->_ua->build_tx( LIST => $self->endpoint . $url );
    $self->_ua->start($tx);
}

sub _info {
    my ( $self, $url ) = @_;
    my $tx = $self->_ua->build_tx( INFO => $self->endpoint . $url );
    $self->_ua->start($tx);
}

sub _run {
    my ( $self, $url, $obj ) = @_;
    $obj ||= {};

    my $tx =
      $self->_ua->build_tx( RUN => $self->endpoint . $url, json => $obj );
    $self->_ua->start($tx);
}

sub _delete {
    my ( $self, $url ) = @_;
    my $tx = $self->_ua->build_tx( DELETE => $self->endpoint . $url );
    $self->_ua->start($tx);
}

sub _count {
    my ( $self, $url ) = @_;
    my $tx = $self->_ua->build_tx( COUNT => $self->endpoint . $url );
    $self->_ua->start($tx);
}

sub _json {
    my ($self) = @_;
    return Mojo::JSON->new;
}

## new urls
# $VERB /1.0/plugin/resource/subres/id
# GET /1.0/hardware/server/5   -> get hardware id 5
# GET /1.0/hardware/server    -> get hardware list

sub call {
    my ( $self, $verb, $version, $plugin, @param ) = @_;

    my $url = "/$version/$plugin";
    my $ref;

    #for my $key (@param) {
    while ( my $key = shift @param ) {
        my $value = shift @param;
        if ( $key eq "ref" ) {
            $ref = $value;
            next;
        }

        $url .= "/$key";

        if ( defined $value ) {
            $url .= "/$value";
        }
    }

    my $meth = "_\L$verb";

    my $ret;

    if ( ref $ref ) {
        $ret = $self->$meth( $url, $ref );
    }
    elsif ($ref) {
        $ret = $self->$meth( $url, $ref );
    }
    else {
        $ret = $self->$meth($url);
    }

    return decode_json( $ret->res->body );
}

1;
