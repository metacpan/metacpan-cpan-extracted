package Plack::Middleware::Session::Simple;

use 5.008005;
use strict;
use warnings;
use parent qw/Plack::Middleware/;
use Digest::SHA1 qw//;
use Cookie::Baker;
use Plack::Util;
use Scalar::Util qw/blessed/;
use Plack::Util::Accessor qw/
    store
    cookie_name
    sid_generator
    sid_validator
    keep_empty
    path
    domain
    expires
    secure
    httponly
    serializer
/;

our $VERSION = "0.03";

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

}

sub call {
    my ($self,$env) = @_;

    my($id, $session) = $self->get_session($env);

    my $tied;
    if ($id && $session) {
        $tied = tie my %session, 
            'Plack::Middleware::Session::Simple::Session', %$session;
        $env->{'psgix.session'} = \%session;
        $env->{'psgix.session.options'} = {
            id => $id,
        };
    } else {
        my $id = $self->{sid_generator}->();
        $tied = tie my %session, 
            'Plack::Middleware::Session::Simple::Session';
        $env->{'psgix.session'} = \%session;
        $env->{'psgix.session.options'} = {
            id => $id,
            new_session => 1,
        };
    }

    my $res = $self->app->($env);

    $self->response_cb(
        $res, sub {
            $self->finalize($env, $_[0], $tied)
        }
    );
}

sub get_session {
    my ($self, $env) = @_;
    my $cookie = crush_cookie($env->{HTTP_COOKIE} || '')->{$self->{cookie_name}};
    return unless defined $cookie;
    return unless $cookie =~ $self->{sid_validator};

    my $session = $self->{store}->get($cookie) or return;
    $session = $self->{serializer}->[1]->($session) if $self->{serializer};
    return ($cookie, $session);
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
        if ($options->{expire}) {
            $self->_set_cookie(
                $options->{id}, $res, %$options, expires => 'now'); 
        } else {
            $self->_set_cookie(
                $options->{id}, $res, %$options); 
        }
    }
}

sub _set_cookie {
    my($self, $id, $res, %options) = @_;

    delete $options{id};

    $options{path}     = $self->{path} || '/' if !exists $options{path};
    $options{domain}   = $self->{domain}      if !exists $options{domain} && defined $self->{domain};
    $options{secure}   = $self->{secure}      if !exists $options{secure} && defined $self->{secure};
    $options{httponly} = $self->{httponly}    if !exists $options{httponly} && defined $self->{httponly};

    if (!exists $options{expires} && defined $self->{expires}) {
        $options{expires} = $self->{expires};
    }

    my $cookie = bake_cookie( 
        $self->{cookie_name}, {
            value => $id,
            %options,
        }
    );
    Plack::Util::header_push($res->[1], 'Set-Cookie', $cookie);
}

1;

package Plack::Middleware::Session::Simple::Session;

use strict;
use warnings;
use Tie::Hash;
use base qw/Tie::ExtraHash/;

sub TIEHASH {
    my $class = shift;
    bless [{@_},0, scalar @_], $class;
}

sub STORE {
    $_[0]->[1]++;
    $_[0]->[0]{$_[1]} = $_[2]
}

sub DELETE {
    $_[0]->[1]++;
    delete $_[0]->[0]->{$_[1]}
}

sub CLEAR {
    $_[0]->[1]++;
    %{$_[0]->[0]} = ()
}

sub has_key {
    scalar keys %{$_[0]->[0]}
}

1;

__END__

=encoding utf-8

=head1 NAME

Plack::Middleware::Session::Simple - Make Session Simple

=head1 SYNOPSIS

    use Plack::Builder;
    use Cache::Memcached::Fast;

    my $app = sub {
        my $env = shift;
        my $counter = $env->{'psgix.session'}->{counter}++;
        [200,[], ["counter => $counter"]];
    };
    
    builder {
        enable 'Session::Simple',
            store => Cache::Memcached::Fast->new({servers=>[..]}),
            cookie_name => 'myapp_session';
        $app
    };


=head1 DESCRIPTION

Plack::Middleware::Session::Simple is a yet another session management module.
This middleware has compatibility with Plack::Middleware::Session by
supporting psgix.session and psgi.session.options. 
You can reduce unnecessary accessing to store and Set-Cookie header.

This module uses Cookie to keep session state. does not support URI based session state.

=head1 OPTIONS

=over 4

=item store

object instance that has get, set, and remove methods.

=item cookie_name

This is the name of the session key, it defaults to 'simple_session'.

=item keep_empty

If disabled, Plack::Middleware::Session::Simple does not output Set-Cookie header and store session until session are used. You can reduce Set-Cookie header and access to session store that is not required. (default: true/enabled)

    builder {
        enable 'Session::Simple',
            cache => Cache::Memcached::Fast->new({servers=>[..]}),
            session_key => 'myapp_session',
            keep_empty => 0;
        mount '/' => sub {
            my $env = shift;
            [200,[], ["ok"]];
        },
        mount '/login' => sub {
            my $env = shift;
            $env->{'psgix.session'}->{user} = 'session user'
            [200,[], ["login"]];
        },
    };
    
    my $res = $app->(req_to_psgi(GET "/")); #res does not have Set-Cookie    
    my $res = $app->(req_to_psgi(GET "/login")); #res has Set-Cookie

If you have a plan to use session_id as csrf token, you must not disable keep_empty.

=item path

Path of the cookie, this defaults to "/";

=item domain

Domain of the cookie, if nothing is supplied then it will not be included in the cookie.

=item expires

Cookie's expires date time. several formats are supported. see L<Cookie::Baker> for details.
if nothing is supplied then it will not be included in the cookie, which means the session expires per browser session.

=item secure

Secure flag for the cookie, if nothing is supplied then it will not be included in the cookie.

=item httponly

HttpOnly flag for the cookie, if nothing is supplied then it will not be included in the cookie.

=item sid_generator

CodeRef that used to generate unique session ids, by default it uses SHA1

=item sid_validator

Regexp that used to validate session id in Cookie

=item serializer

serialize,deserialize method. Optional. This is useful with Cache::FastMmap

  my $cfm = Cache::FastMmap->new(raw_values => 1);
  my $decoder = Sereal::Decoder->new();
  my $encoder = Sereal::Encoder->new();
  builder {
    enable 'Session::Simple',
        store => $fm,
        serializer => [ sub { $encoder->encode($_[0]) }, sub { $decoder->decode($_[0]) } ],
    $app;
  };

=back 

=head1 LICENSE

Copyright (C) Masahiro Nagano.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Masahiro Nagano E<lt>kazeburo@gmail.comE<gt>

=cut

