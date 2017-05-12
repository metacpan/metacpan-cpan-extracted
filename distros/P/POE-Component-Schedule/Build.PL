#!/usr/bin/env perl
use utf8;  # vim:set ts=4 sw=4:

use strict;
use warnings;

use Module::Build;

my $build_module = 'Module::Build';

# Use the extended build only in author environment
if (-d '.svn' || ! -e 'Changes.rss') {
	print "Building in author mode for extended distmeta (to build Changes.rss)\n";
	$build_module = 'inc::MY::Build';
	require inc::MY::Build;
}



my $builder = $build_module->new(
    module_name         => 'POE::Component::Schedule',
    dist_author         => 'Olivier Mengué <dolmen@cpan.org>',
    license             => 'perl',
    meta_add            => {
        resources => {
            homepage => 'http://code.google.com/p/poe-component-schedule/',
            repository => 'http://poe-component-schedule.googlecode.com/svn/trunk/',
            bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=POE-Component-Schedule',
        },
    },
    requires            => {
        # PoCoSchedule is known to work on 1.006
        # But requiring lastest should fix most problems.
        # And we don't have anymore the constraint that the last POE available
        # on ActivePerl was 1.006.
        'POE' => '1.287',
        'DateTime' => '0.48', # Major fixes in this release
        'DateTime::Set' => '0.25',
        'DateTime::TimeZone' => '1.13', # Latest
        # HP-UX requires a plugin for local TZ detection
        ($^O eq 'hpux' ? ('DateTime::TimeZone::HPUX' => '1.04') : () ),
    },
    build_requires => {
        'Test::More' => 0,
    },
);

$builder->create_build_script();
