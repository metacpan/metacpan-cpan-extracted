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

my $songs;
lives_ok {
    $songs = $bach->parse;
} 'lives through parse';

is keys %$songs, 60, 'parse progression';

my $x = '000106b_'; # F_M
my $y = '002806b_'; # A_m
my $z = '001207b_'; # BbM

ok exists $songs->{$x}, "$x exists";
my $song = $songs->{$x};

is $song->{key}, 'F_M', 'key';
is $song->{bwv}, '1.6', 'bwv';
ok $song->{title}, 'title';
is scalar( @{ $song->{events} } ), 162, 'events';
is $song->{events}[0]{notes}, '100001000100', 'notes';
is $song->{events}[0]{bass}, 'F', 'bass';
is $song->{events}[0]{chord}, 'F_M', 'chord';
is $song->{events}[0]{accent}, 3, 'accent';

is_deeply $bach->data->{$x}, $song, 'data';
is_deeply $bach->search( id => $x ), { $x => $song }, 'id search';
is_deeply $bach->search, {}, 'no args search';
is_deeply $bach->search( id => undef ), {}, 'undef id search';
is_deeply $bach->search( key => undef ), {}, 'undef key search';
is_deeply $bach->search( bass => undef ), {}, 'undef bass search';
is_deeply $bach->search( chord => undef ), {}, 'undef chord search';
is_deeply $bach->search( notes => undef ), {}, 'undef notes search';

is scalar( keys %{ $bach->search( id => "$x $y" ) } ), 2, 'multiple id search';
is scalar( keys %{ $bach->search( key => 'X_M' ) } ), 0, 'X_M key search';
is scalar( keys %{ $bach->search( key => 'C_M' ) } ), 6, 'C key search';
is scalar( keys %{ $bach->search( key => 'C_m' ) } ), 1, 'C_m key search';
is scalar( keys %{ $bach->search( key => 'X_M C_M' ) } ), 6, 'X_M or C_M key search';
my $i = scalar( keys %{ $bach->search( key => 'C_M C#M DbM D_M D#M EbM E_M F_M F#M GbM G_M G#M AbM A_M A#M BbM B_M' ) } );
my $j = scalar( keys %{ $bach->search( key => 'C_m C#m Dbm D_m D#m Ebm E_m F_m F#m Gbm G_m G#m Abm A_m A#m Bbm B_m' ) } );
is $i, 35, 'major keys search';
is $j, 25, 'minor keys search';
is $i + $j, 60, 'major + minor = total songs';
is scalar( keys %{ $bach->search( key => 'C_M C_m' ) } ), 7, 'C_M or C_m key search';
is scalar( keys %{ $bach->search( bass => 'X' ) } ), 0, 'X bass search';
is scalar( keys %{ $bach->search( bass => 'C' ) } ), 47, 'C bass search';
is scalar( keys %{ $bach->search( bass => 'X C' ) } ), 47, 'X or C bass search';
is scalar( keys %{ $bach->search( bass => 'X & C' ) } ), 0, 'X and C bass search';
is scalar( keys %{ $bach->search( chord => 'X' ) } ), 0, 'X chord search';
is scalar( keys %{ $bach->search( chord => 'C_M' ) } ), 37, 'C chord search';
is scalar( keys %{ $bach->search( chord => 'X C_M' ) } ), 37, 'X or C_M chord search';
is scalar( keys %{ $bach->search( chord => 'X & C_M' ) } ), 0, 'X and C_M chord search';
is scalar( keys %{ $bach->search( notes => 'X' ) } ), 0, 'X notes search';
is scalar( keys %{ $bach->search( notes => 'C#' ) } ), 46, 'C# notes search';
is scalar( keys %{ $bach->search( notes => 'Db' ) } ), 46, 'Db notes search';
is scalar( keys %{ $bach->search( notes => 'C' ) } ), 50, 'C notes search';
is scalar( keys %{ $bach->search( notes => 'E' ) } ), 58, 'E notes search';
is scalar( keys %{ $bach->search( notes => 'G' ) } ), 55, 'G notes search';
is scalar( keys %{ $bach->search( notes => 'X C' ) } ), 50, 'X or C notes search';
is scalar( keys %{ $bach->search( notes => 'C E' ) } ), 60, 'C or E notes search';
is scalar( keys %{ $bach->search( notes => 'C G' ) } ), 57, 'C or G notes search';
is scalar( keys %{ $bach->search( notes => 'E G' ) } ), 60, 'E or G notes search';
is scalar( keys %{ $bach->search( notes => 'C E G' ) } ), 60, 'C or E or G notes search';
is scalar( keys %{ $bach->search( notes => 'X & C' ) } ), 0, 'X and C notes search';
is scalar( keys %{ $bach->search( notes => 'C & E' ) } ), 48, 'C and E notes search';
is scalar( keys %{ $bach->search( notes => 'C & G' ) } ), 48, 'C and G notes search';
is scalar( keys %{ $bach->search( notes => 'E & G' ) } ), 53, 'E and G notes search';
is scalar( keys %{ $bach->search( notes => 'C & E & G' ) } ), 46, 'C and E and G notes search';

is scalar( keys %{ $bach->search( id => "$x $y", key => 'F_M' ) } ), 1, 'ids and key search';
is scalar( keys %{ $bach->search( id => "$x $y", key => 'F_M A_m' ) } ), 2, 'ids and keys search';
is scalar( keys %{ $bach->search( id => $x, key => 'F_M' ) } ), 1, 'id and key search';
is scalar( keys %{ $bach->search( id => $x, key => 'X_M' ) } ), 0, 'id and !key search';
is scalar( keys %{ $bach->search( id => $x, key => 'X_M F_M' ) } ), 1, 'id and keys search';
is scalar( keys %{ $bach->search( id => $x, bass => 'F' ) } ), 1, 'id and bass search';
is scalar( keys %{ $bach->search( id => $x, bass => 'X' ) } ), 0, 'id and !bass search';
is scalar( keys %{ $bach->search( id => $x, bass => 'X F' ) } ), 1, 'id and basses search';
is scalar( keys %{ $bach->search( id => $x, bass => 'X & F' ) } ), 0, 'id and !basses search';
is scalar( keys %{ $bach->search( id => $x, chord => 'F_M' ) } ), 1, 'id and chord search';
is scalar( keys %{ $bach->search( id => $x, chord => 'X_M' ) } ), 0, 'id and !chord search';
is scalar( keys %{ $bach->search( id => $x, chord => 'X_M F_M' ) } ), 1, 'id and chords search';
is scalar( keys %{ $bach->search( id => $x, chord => 'X_M & F_M' ) } ), 0, 'id and !chords search';
is scalar( keys %{ $bach->search( id => $x, notes => 'F' ) } ), 1, 'id and note search';
is scalar( keys %{ $bach->search( id => $x, notes => 'X' ) } ), 0, 'id and !note search';
is scalar( keys %{ $bach->search( id => $x, notes => 'X F' ) } ), 1, 'id and notes search';
is scalar( keys %{ $bach->search( id => $x, notes => 'F C' ) } ), 1, 'id and notes search';
is scalar( keys %{ $bach->search( id => $x, notes => 'C & F' ) } ), 1, 'id and notes search';
is scalar( keys %{ $bach->search( id => $x, notes => 'X & F' ) } ), 0, 'id and !notes search';
is scalar( keys %{ $bach->search( id => "$x $y", notes => 'F & A' ) } ), 2, 'id and notes search';
is scalar( keys %{ $bach->search( id => $z, notes => 'Bb' ) } ), 1, 'id and note search';
is scalar( keys %{ $bach->search( id => $z, notes => 'B' ) } ), 0, 'id and !note search';
is scalar( keys %{ $bach->search( id => $z, notes => 'Bb B' ) } ), 1, 'id and notes search';
is scalar( keys %{ $bach->search( id => $z, notes => 'Bb & B' ) } ), 0, 'id and !notes search';

is_deeply $bach->bits2notes('000000000000'), [], 'empty bits2notes';
is_deeply $bach->bits2notes('100000000000'), [ 'C' ], '1 natural bits2notes';
is_deeply $bach->bits2notes('010000000000'), [ 'Db' ], '1 flat bits2notes';
is_deeply $bach->bits2notes('010000000000', '#' ), [ 'C#' ], '1 sharp bits2notes';
is_deeply $bach->bits2notes('001000000000'), [ 'D' ], '1 natural bits2notes';
is_deeply $bach->bits2notes('000100000000'), [ 'Eb' ], '1 flat bits2notes';
is_deeply $bach->bits2notes('000100000000', '#' ), [ 'D#' ], '1 sharp bits2notes';
is_deeply $bach->bits2notes('000010000000'), [ 'E' ], '1 natural bits2notes';
is_deeply $bach->bits2notes('000001000000'), [ 'F' ], '1 natural bits2notes';
is_deeply $bach->bits2notes('000000100000'), [ 'Gb' ], '1 flat bits2notes';
is_deeply $bach->bits2notes('000000100000', '#' ), [ 'F#' ], '1 sharp bits2notes';
is_deeply $bach->bits2notes('000000010000'), [ 'G' ], '1 natural bits2notes';
is_deeply $bach->bits2notes('000000001000'), [ 'Ab' ], '1 flat bits2notes';
is_deeply $bach->bits2notes('000000001000', '#' ), [ 'G#' ], '1 sharp bits2notes';
is_deeply $bach->bits2notes('000000000100'), [ 'A' ], '1 natural bits2notes';
is_deeply $bach->bits2notes('000000000010'), [ 'Bb' ], '1 flat bits2notes';
is_deeply $bach->bits2notes('000000000010', '#' ), [ 'A#' ], '1 sharp bits2notes';
is_deeply $bach->bits2notes('000000000001'), [ 'B' ], '1 natural bits2notes';
is_deeply $bach->bits2notes('100000000010'), [ 'C', 'Bb' ], '2 flat bits2notes';
is_deeply $bach->bits2notes( '100000000010', '#' ), [ 'C', 'A#' ], '2 sharp bits2notes';

done_testing();
