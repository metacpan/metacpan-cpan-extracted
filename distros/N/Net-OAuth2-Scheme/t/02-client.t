#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 29;

use Net::OAuth2::Scheme;
use HTTP::Request::Common;

my ($s, $e, $t, %p);

$s = Net::OAuth2::Scheme->new(transport => 'bearer',context=>'client');

($e,$t,%p) = $s->token_accept(foo => '12345',token_type=>'Bearer');
is( $e, 'no_access_token');

($e,$t,%p) = $s->token_accept(access_token => '12345',token_type=>'WTF');
is( $e, 'wrong_token_type');

($e,$t,%p) = $s->token_accept('12345',token_type=>'WTF');
is( $e, 'wrong_token_type');

($e,$t,%p) = $s->token_accept(access_token => '12345',token_type=>'Bearer');
ok( !defined($e) );
is( $t, '12345');
is_deeply( \%p, { token_type => 'Bearer' } );

($e,$t,%p) = $s->token_accept('12345',token_type=>'Bearer',scope=>'the scope');
ok( !defined($e) );
is( $t, '12345');
is_deeply( \%p, { token_type => 'Bearer' } );

my $r;
$r = GET 'https://example.com/stuff?x=1';
($e,$r) = $s->http_insert($r,$t,%p);
ok(!defined($e));
is( $r->authorization, 'Bearer 12345' );

$r = POST 'https://example.com/stuff', { x => 1 };
($e,$r) = $s->http_insert($r,$t,%p);
ok(!defined($e));
is( $r->authorization, 'Bearer 12345' );

sub mkbearer {
    my $s = Net::OAuth2::Scheme->new
      (
       context => 'client',
       accept_remove => [], 
       transport => ['bearer', @_],
      );
    ok (defined $s);
    return $s;
}

$s = mkbearer(scheme => 'OAuth');
($e,$t,%p) = $s->token_accept('12345',token_type=>'Bearer',scope=>'the scope');
ok( !defined($e) );
is( $t, '12345');
is_deeply( \%p, { token_type => 'Bearer', scope => 'the scope' } );

$r = GET 'https://example.com/stuff?x=1';
($e,$r) = $s->http_insert($r,$t,%p);
ok(!defined($e));
is( $r->authorization, 'OAuth 12345' );

$s = mkbearer(client_uses_param => 1);
$r = POST 'https://example.com/stuff', { x => 1 };
($e,$r) = $s->http_insert($r,$t,%p);
ok(!defined($e));
is( $r->content, 'x=1&access_token=12345');

$r = GET 'https://example.com/stuff?x=1';
($e,$r) = $s->http_insert($r,$t,%p);
is($e, 'bad_method');

$s = mkbearer(param => 'oauth_token', client_uses_param => 1);
$r = POST 'https://example.com/stuff', { x => 1 };
($e,$r) = $s->http_insert($r,$t,%p);
ok(!defined($e));
is( $r->content, 'x=1&oauth_token=12345');

$s = mkbearer(client_uses_param => 1, allow_body => 0, allow_uri => 1);
$r = GET 'https://example.com/stuff?x=1';
($e,$r) = $s->http_insert($r,$t,%p);
ok(!defined($e));
is( $r->uri->query, 'x=1&access_token=12345');

1;
