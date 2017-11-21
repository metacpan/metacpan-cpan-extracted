#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::LongString;
use File::Basename;

use OTRS::OPM::Maker::Utils::Git;

my $git =  dirname(__FILE__) . '/../bin/git';

$OTRS::OPM::Maker::Utils::Git::GIT = 'perl ' . $git;

my $new = OTRS::OPM::Maker::Utils::Git->commits(
    dir     => '.',
    version => '17.0.98',
);

my $check = '17.1.1    2017-11-14T10:35:07+01:00

    noch ein Test
        
        Fuer den Text des Commits

    prepare release

    prepare release


17.1.0    2017-09-29T14:41:14+02:00

    noch ein Test
        
        Fuer den Text des Commits

    prepare release

    prepare release


17.0.99    2017-09-29T13:37:57+02:00

    noch ein Test
        
        Fuer den Text des Commits

    prepare release

    prepare release


';

is_string $new, $check;

done_testing();
