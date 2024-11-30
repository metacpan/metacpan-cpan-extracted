#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use Test::Exception;

use_ok 'Music::ToRoman';

subtest throws => sub {
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
};

subtest degree_type => sub {
    my $mtr = Music::ToRoman->new;

    my $expect = 'major';
    my ($degree, $type) = $mtr->get_scale_degree('I');
    is $degree, 1, 'degree';
    is $type, $expect, 'type';
    ($degree, $type) = $mtr->get_scale_degree('II');
    is $degree, 2, 'degree';
    is $type, $expect, 'type';
    ($degree, $type) = $mtr->get_scale_degree('III');
    is $degree, 3, 'degree';
    is $type, $expect, 'type';
    ($degree, $type) = $mtr->get_scale_degree('IV');
    is $degree, 4, 'degree';
    is $type, $expect, 'type';
    ($degree, $type) = $mtr->get_scale_degree('V');
    is $degree, 5, 'degree';
    is $type, $expect, 'type';
    ($degree, $type) = $mtr->get_scale_degree('VI');
    is $degree, 6, 'degree';
    is $type, $expect, 'type';
    ($degree, $type) = $mtr->get_scale_degree('VII');
    is $degree, 7, 'degree';
    is $type, $expect, 'type';

    $expect = 'minor';
    ($degree, $type) = $mtr->get_scale_degree('i');
    is $degree, 1, 'degree';
    is $type, $expect, 'type';
    ($degree, $type) = $mtr->get_scale_degree('ii');
    is $degree, 2, 'degree';
    is $type, $expect, 'type';
    ($degree, $type) = $mtr->get_scale_degree('iii');
    is $degree, 3, 'degree';
    is $type, $expect, 'type';
    ($degree, $type) = $mtr->get_scale_degree('iv');
    is $degree, 4, 'degree';
    is $type, $expect, 'type';
    ($degree, $type) = $mtr->get_scale_degree('v');
    is $degree, 5, 'degree';
    is $type, $expect, 'type';
    ($degree, $type) = $mtr->get_scale_degree('vi');
    is $degree, 6, 'degree';
    is $type, $expect, 'type';
    ($degree, $type) = $mtr->get_scale_degree('vii');
    is $degree, 7, 'degree';
    is $type, $expect, 'type';

    $expect = 'diminished';
    ($degree, $type) = $mtr->get_scale_degree('io');
    is $degree, 1, 'degree';
    is $type, $expect, 'type';
    ($degree, $type) = $mtr->get_scale_degree('iio');
    is $degree, 2, 'degree';
    is $type, $expect, 'type';
    ($degree, $type) = $mtr->get_scale_degree('iiio');
    is $degree, 3, 'degree';
    is $type, $expect, 'type';
    ($degree, $type) = $mtr->get_scale_degree('ivo');
    is $degree, 4, 'degree';
    is $type, $expect, 'type';
    ($degree, $type) = $mtr->get_scale_degree('vo');
    is $degree, 5, 'degree';
    is $type, $expect, 'type';
    ($degree, $type) = $mtr->get_scale_degree('vio');
    is $degree, 6, 'degree';
    is $type, $expect, 'type';
    ($degree, $type) = $mtr->get_scale_degree('viio');
    is $degree, 7, 'degree';
    is $type, $expect, 'type';
};

done_testing();
