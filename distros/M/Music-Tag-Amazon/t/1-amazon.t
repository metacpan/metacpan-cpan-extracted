#!/usr/bin/perl -w
use strict;

use Test::More tests => 8;
use 5.006;

BEGIN { use_ok('Music::Tag') }
BEGIN { use_ok('Net::Amazon') }

################################################################
# Setup:  TAKEN FROM Net::Amazon by Mike Schilli
################################################################
  my($TESTDIR) = map { -d $_ ? $_ : () } qw(t ../t .);
  require "$TESTDIR/init.pl";
  my $CANNED = "$TESTDIR/canned";
################################################################
  canned($CANNED, "artist.xml");
################################################################

my $ua = Net::Amazon->new(
    token         => 'YOUR_AMZN_TOKEN',
    secret_key  => 'YOUR_AMZN_SECRET_KEY',
    # response_dump => 1,
);

my $tag = Music::Tag->new( undef,
                           {  artist    => "Zwan",
                              album     => "Mary Star of the Sea",
                              title     => "Heartsong",
                              ANSIColor => 0,
                              quiet     => 1,
                              locale    => "ca"
                           },
                           "Option"
                         );


ok( $tag,                       'Object created' );
ok( $tag->add_plugin("Amazon"), "Plugin Added" );
$tag->plugin('Amazon')->amazon_ua($ua);
ok( $tag->get_tag,              'get_tag called' );
is( $tag->asin,  "B00007M84Q", 'ASIN Set' );
ok( $tag->upc,  'UPC Set' );
is( $tag->track, 8,            'Track Set' );

