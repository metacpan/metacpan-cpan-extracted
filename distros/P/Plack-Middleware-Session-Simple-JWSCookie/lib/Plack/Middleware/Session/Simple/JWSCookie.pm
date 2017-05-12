package Plack::Middleware::Session::Simple::JWSCookie;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.01";

use parent qw(Plack::Middleware::Session::Simple);
use Digest::SHA1 qw//;
use Cookie::Baker;
use Plack::Util;
use Scalar::Util qw/blessed/;
use JSON::WebToken qw/encode_jwt decode_jwt/;
use Plack::Util::Accessor qw/
    alg
    secret
/;

sub prepare_app {
    my $self = shift;

    my $store = $self->store;
    die('store require get, set and remove method.')
        unless blessed $store
            && $store->can('get')
            && $store->can('set')
            && $store->can('remove');

    $self->cookie_name('simple_session') unless $self->cookie_name;
    $self->path('/') unless defined $self->path;
    $self->keep_empty(1) unless defined $self->keep_empty;

    if ( !$self->sid_generator ) {
        $self->sid_generator(sub{
            Digest::SHA1::sha1_hex(rand() . $$ . {} . time)
        });
    }
    if ( !$self->sid_validator ) {
        $self->sid_validator(
            qr/\A[0-9a-f]{40}\Z/
        );
    }

    # secret & alg
    unless ($self->secret && $self->alg) {
        $self->alg('none');
        $self->secret(undef);
    } else {
        # support only HMAC Signature
        die "Plack::Middleware::Session::Cookie::JWS supports only HMAC Signatures"
            unless ($self->alg eq 'HS256' || $self->alg eq 'HS384' || $self->alg eq 'HS512');
    }
}

sub get_session {
    my ($self, $env) = @_;
    my $cookie = crush_cookie($env->{HTTP_COOKIE} || '')->{$self->{cookie_name}};
    return unless defined $cookie;
    my $payload;
    eval {
        $payload = decode_jwt($cookie, $self->secret, 0);
    };
    return if ($@ || !$payload->{id});

    my $id = $payload->{id};
    return unless $id =~ $self->{sid_validator};

    my $session = $self->{store}->get($id) or return;
    $session = $self->{serializer}->[1]->($session) if $self->{serializer};
    return ($id, $session);
}

sub finalize {
    my ($self, $env, $res, $session) = @_;
    my $options = $env->{'psgix.session.options'};
    my $new_session = delete $options->{new_session};

    my $need_store;
    if ( ($new_session && $self->{keep_empty} && ! $session->has_key )
             || $session->[1] || $options->{expire} || $options->{change_id}) {
        $need_store = 1;
    }
    $need_store = 0 if $options->{no_store};

    my $set_cookie;
    if ( ($new_session && $self->{keep_empty} && ! $session->has_key )
             || ($new_session && $session->[1] )
             || $options->{expire} || $options->{change_id}) {
        $set_cookie = 1;
    }

    if ( $need_store ) {
        if ($options->{expire}) {
            $self->{store}->remove($options->{id});
        } elsif ($options->{change_id}) {
            $self->{store}->remove($options->{id});
            $options->{id} = $self->{sid_generator}->();
            my $val = $session->[0];
            $val = $self->{serializer}->[0]->($val) if $self->{serializer};
            $self->{store}->set($options->{id}, $val);            
        } else {
            my $val = $session->[0];
            $val = $self->{serializer}->[0]->($val) if $self->{serializer};
            $self->{store}->set($options->{id}, $val);
        }
    }

    if ( $set_cookie ) {
        my $jws = encode_jwt({ id => $options->{id} }, $self->secret, $self->alg);
        if ($options->{expire}) {
            $self->_set_cookie(
                $jws, $res, %$options, expires => 'now'); 
        } else {
            $self->_set_cookie(
                $jws, $res, %$options); 
        }
    }
}

1;

__END__

=encoding utf-8

=head1 NAME

Plack::Middleware::Session::Simple::JWSCookie - Session::Simple with JWS(JSON Web Sigmature) Cookie

=head1 SYNOPSIS

    use Plack::Middleware::Session::Simple::JWSCookie;

    use Plack::Builder;
    use Cache::Memcached::Fast;

    my $app = sub {
        my $env = shift;
        my $counter = $env->{'psgix.session'}->{counter}++;
        [200,[], ["counter => $counter"]];
    };

    # no signature
    builder {
        enable 'Session::Simple::JWSCookie',
            store => Cache::Memcached::Fast->new({servers=>[..]}),
            cookie_name => 'myapp_session';
        $app
    };

    # using HMAC Signature
    builder {
        enable 'Session::Simple::JWSCookie',
            store => Cache::Memcached::Fast->new({servers=>[..]}),
            cookie_name => 'myapp_session'
            secret => $hmac_secret,
            alg = 'HS256';
        $app
    };

=head1 DESCRIPTION

Plack::Middleware::Session::Simple::JWSCookie is session management module
which has compatibility with Plack::Middleware::Session::Simple.

Session cookie include session metadata with signature using JSON Web Signature.
The session cookie prevents manipulation of the session ID,
and can detect the invalid session cookie without accessing storage.

=head1 LICENSE

Copyright (C) ritou.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

ritou E<lt>ritou.06@gmail.comE<gt>

=cut

