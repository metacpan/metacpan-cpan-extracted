use ExtUtils::MakeMaker::CPANfile;

WriteMakefile(
    NAME             => 'MojoX::Pg::Migrations::Env',
    VERSION_FROM     => 'lib/MojoX/Pg/Migrations/Env.pm',
    ABSTRACT_FROM    => 'lib/MojoX/Pg/Migrations/Env.pm',
    AUTHOR           => 'David Jack Wange Olrik <djo@cpan.org>',
    LICENSE          => 'mit',
    MIN_PERL_VERSION => '5.020',
);
