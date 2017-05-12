use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'         => 'Perl::Critic::Policy::CompileTime',
    'VERSION_FROM' => 'lib/Perl/Critic/Policy/CompileTime.pm',
    'AUTHOR'       => 'Erin Schoenhals <erin@cpanel.net>',
    'LICENSE'      => 'perl',
    'ABSTRACT'     => 'Find code that runs in compile-time blocks',

    'PREREQ_PM' => {
        'PPI'          => 0,
        'Perl::Critic' => 0
    }
);
