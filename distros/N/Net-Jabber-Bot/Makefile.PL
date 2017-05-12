use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Net::Jabber::Bot',
    AUTHOR              => 'Todd E Rinaldo <perl-net-jabber-bot@googlegroups.com>',
    VERSION_FROM        => 'lib/Net/Jabber/Bot.pm',
    ABSTRACT_FROM       => 'lib/Net/Jabber/Bot.pm',
    PL_FILES            => {},
    ($ExtUtils::MakeMaker::VERSION >= 6.3002 ? ('LICENSE'        => 'perl', ) : ()),
    PREREQ_PM => {
        'Moose' => 0.82,  # Object Base
        'MooseX::Types' => 0.12, # New variable types
        'Time::HiRes' => 0, # Partial second sleeping
        'Net::Jabber' => 2.0,  # The whole thing is based on Net::Jabber. 
        'Log::Log4perl' => 0,  # We use log4perl. not sure how bad this'll screw people over... should consider removal later or make it optional
        'version' => 0, # It comes with most dists, but might as well be explicit
        'Test::More' => 0,  # For testing
        'Test::NoWarnings' => 0,  # For testing
        'Sys::Hostname' => 0, # For unique resource name per connection 
        'FindBin' => 0, # Find mock module
        'lib' => 0,  # add lib for Mock jabber module
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Net-Jabber-Bot-*' },
    META_MERGE  => {
        recommends => {
            'Test::Pod::Coverage' => 1.04,
            'Test::Pod' => 1.14,
        },
        build_requires => {
            'Test::More' => 0,  # For testing
            'Test::NoWarnings' => 0,  # For testing
            'FindBin' => 0, # Find mock module
            'lib' => 0,  # add lib for Mock jabber module
        },
        resources => {
            license => 'http://dev.perl.org/licenses/',
            homepage => 'http://wiki.github.com/toddr/perl-net-jabber-bot',
            bugtracker => 'http://code.google.com/p/perl-net-jabber-bot/issues/list',
            repository => 'http://github.com/toddr/perl-net-jabber-bot/tree/master',
            MailingList => 'http://groups.google.com/group/perl-net-jabber-bot',
        },
    },
);
