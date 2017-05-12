require 5.008001;
use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'          => 'PocketIO::Client::IO',
    'VERSION_FROM'  => 'lib/PocketIO/Client/IO.pm',
    'PREREQ_PM'     => {
              'Test::More'  => 0,
              'Test::TCP'   => 0,
              'AnyEvent'    => 0,
              'Plack'       => 0,
              'Twiggy'      => 0,
              'PocketIO'    => '0.13',
    },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/PocketIO/Client/IO.pm', # retrieve abstract from module
       AUTHOR     => 'Makamaka Hannyaharamitu, E<lt>makamaka[at]cpan.orgE<gt>') : ()),
    ( $ExtUtils::MakeMaker::VERSION >= 6.3002 ? ('LICENSE' => 'perl', ) : () ),

    ( $ExtUtils::MakeMaker::VERSION >= 6.46 ? (
        'META_MERGE' => {
            resources => {
                repository  =>      'http://github.com/makamaka/AnyEvent-PocketIO-Client/',
            },
        } ) : ()
    ),
);



