#!perl -T

use strict;
use warnings;
use utf8;

use 5.006;

use English qw(-no_match_vars);
use Test::More tests => 11;

use Music::Lyrics::LRC;

our $VERSION = '0.17';

my $lrc = Music::Lyrics::LRC->new();

open my $fh, '<', 't/japh.lrc' or die "$ERRNO\n";
ok( $lrc->load($fh), 'loaded' );
close $fh or die "$ERRNO\n";

my %tags = %{ $lrc->tags };
ok( keys %tags == 2, 'tags_count' );

my @lyrics = @{ $lrc->lyrics };
ok( @lyrics == 4, 'lines_count' );

ok( $lyrics[0]{text} eq q{I'm just another Perl hacker,},       'line_text_1' );
ok( $lyrics[1]{text} eq q{Matchin' up the world.},              'line_text_2' );
ok( $lyrics[2]{text} eq q{And you know the world's my oyster,}, 'line_text_3' );
ok( $lyrics[3]{text} eq q{And my language is its pearl.},       'line_text_4' );

## no critic (ProhibitMagicNumbers)
ok( $lyrics[0]{time} == 113_530, 'line_time_1' );
ok( $lyrics[1]{time} == 116_560, 'line_time_2' );
ok( $lyrics[2]{time} == 119_000, 'line_time_3' );
ok( $lyrics[3]{time} == 122_400, 'line_time_4' );
