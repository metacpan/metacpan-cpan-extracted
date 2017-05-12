use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Net::Amazon::EC2::Metadata',
    AUTHOR              => 'Nathan McFarland <nmcfarl@cpan.org>',
    VERSION_FROM        => 'lib/Net/Amazon/EC2/Metadata.pm',
    ABSTRACT_FROM       => 'lib/Net/Amazon/EC2/Metadata.pm',
    PL_FILES            => {},
    EXE_FILES           => [ 'bin/ec2meta' ],

    PREREQ_PM => {
        'Test::More'    => 0,
        'Perl6::Say'    => 0,
        'Pod::Usage'    => 0,
        'LWP::Simple'   => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Net-Amazon-EC2-Metadata-*' },
);
