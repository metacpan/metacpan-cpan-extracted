use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Plack::Middleware::Auth::FCGI',
    VERSION_FROM => 'lib/Plack/Middleware/Auth/FCGI.pm',
    PREREQ_PM    => {
        'FCGI::Client' => '0.08',
        'Plack'        => '1.000',
    },
    ABSTRACT_FROM => 'lib/Plack/Middleware/Auth/FCGI.pm',
    AUTHOR        => 'Xavier Guimard <x.guimard@free.fr>',
    LICENSE       => 'perl',
);
