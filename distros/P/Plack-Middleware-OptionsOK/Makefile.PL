use ExtUtils::MakeMaker;
use strict;
use warnings;

WriteMakefile(
    'NAME'         => 'Plack::Middleware::OptionsOK',
    'VERSION_FROM' => 'lib/Plack/Middleware/OptionsOK.pm',
    'PREREQ_PM'    => {
        'Plack'      => '0.9901',
        'Test::More' => '0',
    }
);

