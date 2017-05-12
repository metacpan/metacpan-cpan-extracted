use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Template::Provider::HTTP',
    VERSION_FROM => 'lib/Template/Provider/HTTP.pm',
    LICENSE      => 'perl',
    PREREQ_PM    => {
        'Cwd'                        => 0,
        'Data::Dumper'               => 0,
        'File::Slurp'                => 0,
        'LWP::UserAgent'             => 0,
        'Template'                   => 0,
        'Test::HTTP::Server::Simple' => 0,
        'Test::More'                 => 0,
        'Time::HiRes'                => 0,
    },
);

