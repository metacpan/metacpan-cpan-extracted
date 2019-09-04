#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use Test::Exception;

use_ok 'Music::ToRoman';

throws_ok {
    Music::ToRoman->new( scale_note => 'X' )
} qr/Invalid note/, 'invalid note';

throws_ok {
    Music::ToRoman->new( major_tonic => 'X' )
} qr/Invalid note/, 'invalid note';

throws_ok {
    Music::ToRoman->new( scale_name => 'foo' )
} qr/Invalid scale/, 'invalid scale';

throws_ok {
    Music::ToRoman->new( chords => 123 )
} qr/Invalid boolean/, 'invalid boolean';

my $mtr = Music::ToRoman->new;
isa_ok $mtr, 'Music::ToRoman';

throws_ok {
    $mtr->parse
} qr/No chord/, 'no chord to parse';

done_testing();
