#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use Test::Exception;

use_ok 'Music::BachChoralHarmony';

my $data_file = 'share/jsbach_chorals_harmony.data';
my $key_title = 'share/jsbach_BWV_keys_titles.txt';

ok -e $data_file, 'data_file exists';
ok -e $key_title, 'key_title exists';

my $bach = Music::BachChoralHarmony->new(
    data_file => $data_file,
    key_title => $key_title,
);
isa_ok $bach, 'Music::BachChoralHarmony';

my $song;
lives_ok {
    $song = $bach->parse;
} 'lives through parse';

is keys %$song, 60, 'parse progression';

my $x = '000106b_';
ok exists $song->{$x}, $x;
$song = $song->{$x};

is $song->{key}, 'F_M', 'key';
is $song->{bwv}, '1.6', 'bwv';
ok $song->{title}, 'title';
is scalar( @{ $song->{events} } ), 162, 'events';
is $song->{events}[0]{notes}, '100001000100', 'notes';
is $song->{events}[0]{bass}, 'F', 'bass';
is $song->{events}[0]{chord}, 'F_M', 'chord';
is $song->{events}[0]{accent}, 3, 'accent';

done_testing();
