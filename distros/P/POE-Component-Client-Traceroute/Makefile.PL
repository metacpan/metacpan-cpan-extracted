#!/usr/bin/perl

use ExtUtils::MakeMaker;

# Touch CHANGES so it exists.
open(CHANGES, ">>CHANGES") and close(CHANGES);

WriteMakefile(
    NAME         => 'POE::Component::Client::Traceroute',
    AUTHOR       => 'Andrew Hoying <ahoying@cpan.org>',
    ABSTRACT     => 'POE component for non-blocking/concurrent traceroutes.',
#    LICENSE      => 'perl', # Not yet supported under main MakeMaker
    VERSION_FROM => 'Traceroute.pm',

    PREREQ_PM    => {
        'POE'         	=> 0.11,
        'Time::HiRes'	=> 1.20,
    },
    dist         => {
        'COMPRESS'   	=> 'gzip',
        'SUFFIX'      	=> 'gz'
    },
);


