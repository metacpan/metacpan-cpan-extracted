use 5.008;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'SVN::Deploy',
    VERSION_FROM      => 'lib/SVN/Deploy.pm',
    PREREQ_PM         => {
        SVN::Client           => 0,
        SVN::Ra               => 0,
        File::Copy::Recursive => 0.31,
    },
    (
        $] >= 5.005
        ? (
            ABSTRACT_FROM  => 'lib/SVN/Deploy.pm',
            AUTHOR         => 'Thomas Kratz <tomk@cpan.org>'
          )
        : ()
    ),
    (
        $ExtUtils::MakeMaker::VERSION >= 6.3002
        ? (LICENSE => "perl")
        : (),
    ),
);
