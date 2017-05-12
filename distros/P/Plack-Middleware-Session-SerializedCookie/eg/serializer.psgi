#!/usr/bin/perl

############################
# NOTE:
#  In order to run this example correctly, be sure that you have installed modules
#  that used by Data::Serializer in this case, such as:
#   Data::Serializer
#   JSON
#   Crypt::CBC
#   Crypt::Rijndael
#   Compress::Zlib
#   ...
#  Or, you can change the parameters when creating the Data::Serializer object.

use lib qw(../lib);
use Data::Serializer;
use Plack::Middleware::Session::SerializedCookie;

Plack::Middleware::Session::SerializedCookie->new(
    serializer => Data::Serializer->new(
	serializer => 'JSON',
	cipher => 'Rijndael',
	secret => 'ooxx',
	compress => 1,
    ),
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
