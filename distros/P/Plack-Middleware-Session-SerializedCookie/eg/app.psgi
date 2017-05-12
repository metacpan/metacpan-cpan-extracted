#!/usr/bin/perl

use lib qw(../lib);
use JSON;
use MIME::Base64;
use Plack::Middleware::Session::SerializedCookie;

Plack::Middleware::Session::SerializedCookie->new(
    serialize => sub {
	encode_base64(encode_json($_[0]))
    },
    deserialize => sub {
	decode_json(decode_base64($_[0]))
    },
    serialize_exception => sub {
	warn "serialize_exception: $@"
    },
    deserialize_exception => sub {
	warn "deserialize_exception: $@"
    },
)->wrap( sub {
    my $env = shift;
    my $session = $env->{'psgix.session'} ||= {};
    my $req = Plack::Request->new($env);

    $session->{name} ||= 'Guest';
    my $new_name = $req->param('name');

    if( defined($new_name) && $new_name ne $session->{name} ) {
	$session->{name} = $new_name;
	$session->{visit} = 0;
    }
    ++$session->{visit};

    return [200, ['content-type'=>'text/html;charset=UTF-8'], ["Hi $session->{name}!<br>You've visited here $session->{visit} time(s)."]];
} )
