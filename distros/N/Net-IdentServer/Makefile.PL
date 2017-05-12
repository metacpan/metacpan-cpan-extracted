# vi:set syntax=perl:

use ExtUtils::MakeMaker;

unless( -r "/proc/net/tcp" ) {
    exit 0 if $ENV{AUTOMATED_TESTING};
    die "this module relies heavily on /proc/net/tcp (probably loonix only)\n";
}

WriteMakefile(
    NAME         => 'Net::IdentServer',
    VERSION_FROM => 'IdentServer.pm',
    AUTHOR       => 'Paul Miller <jettero@cpan.org>',
    PREREQ_PM    => { 
        'Net::Server' => 0,
    },
);
