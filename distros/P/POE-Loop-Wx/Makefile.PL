use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'POE::Loop::Wx',
    ABSTRACT            => 'wxPerl event loop for POE',
    AUTHOR              => 'Mike Schroeder <mike-cpan@donorware.com>',
    VERSION_FROM        => 'lib/POE/Loop/Wx.pm',
    PREREQ_PM           => { 'Wx'                      => 0.20,
                             'POE'                     => 0.3009,
                             'Test::More'              => 0,
                           },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'POE-Loop-Wx-*' },
);
