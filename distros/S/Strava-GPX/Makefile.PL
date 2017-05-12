#/usr/bin/perl

use strict;
use warnings;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Strava-GPX',
    VERSION_FROM      => 'lib/Strava/GPX.pm',
    PREREQ_PM         => {'URI' => 0, 'LWP::UserAgent' => 0, 'Geo::Gpx' => 0},
    ABSTRACT_FROM  => 'lib/Strava/GPX.pm', 
    AUTHOR         => 'Fred Moyer <fred@redhotpenguin.com>',
);
