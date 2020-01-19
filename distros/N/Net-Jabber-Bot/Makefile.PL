use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Net::Jabber::Bot',
    AUTHOR              => 'Todd E Rinaldo <toddr@cpan.org>',
    VERSION_FROM        => 'lib/Net/Jabber/Bot.pm',
    ABSTRACT_FROM       => 'lib/Net/Jabber/Bot.pm',
    PL_FILES            => {},
    ($ExtUtils::MakeMaker::VERSION >= 6.3002 ? ('LICENSE'        => 'perl', ) : ()),
    PREREQ_PM => {
        'Moose' => 0.82,  # Object Base
        'MooseX::Types' => 0.12, # New variable types
        'Mozilla::CA' => 0, # SSL Cert support.
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
        build_requires => {
            'Test::More' => 0,  # For testing
            'Test::NoWarnings' => 0,  # For testing
            'FindBin' => 0, # Find mock module
            'lib' => 0,  # add lib for Mock jabber module
        },
        resources => {
            license => 'http://dev.perl.org/licenses/',
            homepage => 'http://wiki.github.com/toddr/perl-net-jabber-bot',
            bugtracker => 'https://github.com/toddr/perl-net-jabber-bot/issues',
            repository => 'http://github.com/toddr/perl-net-jabber-bot/tree/master',
#            MailingList => 'http://groups.google.com/group/perl-net-jabber-bot',
        },
    },
);
