#!perl -T

use strict;
use warnings;
use utf8;

use 5.006;

use English qw(-no_match_vars);
use File::Temp qw(tempfile);
use Test::More tests => 2;

use Music::Lyrics::LRC;

our $VERSION = '0.11';

my $lrc = Music::Lyrics::LRC->new();
$lrc->set_tag( 'foo', 'bar' );
$lrc->add_lyric( 0,  'lalala' );
$lrc->add_lyric( 10, 'doremi' );

my ( $fh, $fn ) = tempfile();
ok( $lrc->save($fh), 'save' );
close $fh
  or die "$ERRNO\n";
ok( -s $fn == 44, 'length' );    ## no critic (ProhibitMagicNumbers)
