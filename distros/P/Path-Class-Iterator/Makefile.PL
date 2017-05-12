use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Path::Class::Iterator',
    VERSION_FROM => 'lib/Path/Class/Iterator.pm',
    PREREQ_PM    => {

        'Path::Class'           => 0.01,
        'Iterator'              => 0.01,
        'Class::Accessor::Fast' => 0.01

    },

    clean => {
        FILES =>
          'test/cannot_chdir test/link_to_cannot_chdir test/bar test/no_such_dir'
    }
);
