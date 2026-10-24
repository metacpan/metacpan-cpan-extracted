#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use SkilletorTest;

use Path::Tiny qw( path );
use Skilletor::JSON qw( js_parse );
use Skilletor::URL qw( parse_url punycode_encode );

# t/data/url-oracle.json: Node's new URL() for each input (maint/oracle-url.mjs).
my $oracle = js_parse( path( $FindBin::Bin, 'data', 'url-oracle.json' )->slurp_utf8 );

for my $case (@$oracle) {
  my $u = parse_url( $case->{input} );
  if ( exists $case->{error} ) {
    ok( !defined $u, 'throws: '.$case->{input} );
    next;
  }
  ok( $u, 'parses: '.$case->{input} ) or next;
  is_deeply(
    { map { $_ => $u->{$_} } qw( protocol hostname port pathname ) },
    { map { $_ => $case->{$_} } qw( protocol hostname port pathname ) },
    'parts of '.$case->{input},
  );
}

is( punycode_encode("b\x{fc}cher"), 'bcher-kva', 'RFC 3492 sample' );
is( punycode_encode("\x{65e5}\x{672c}"), 'wgv71a', 'CJK label' );

done_testing;
