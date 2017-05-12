use ExtUtils::MakeMaker;

WriteMakefile(
    NAME      => 'Template::Plugin::LDAP',
    VERSION   => '0.05',
    PREREQ_PM => {
        'Net::LDAP'  => 0,
        'Template'   => 0,
        'Test::More' => 0,
    },
);
