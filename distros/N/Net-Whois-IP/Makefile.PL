use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME	   => 'Net::Whois::IP',
    VERSION_FROM   => 'IP.pm', # finds $VERSION
    LICENSE        => 'perl',

    BUILD_REQUIRES	 => {
		'Regexp::IPv6' => '.02',
		'Test::More'   => 0,
    },

    PREREQ_PM => {
        'IO::Socket' => 0,
        'Exporter'   => 0,
    },

    ABSTRACT => 'Perl module for performing WHOIS IP lookups',

    AUTHOR   => 'Ben Schmitz <ben@foink.com>',
);
