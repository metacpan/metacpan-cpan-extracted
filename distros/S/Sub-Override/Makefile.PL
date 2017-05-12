use 5.006;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Sub::Override',
    VERSION_FROM => 'lib/Sub/Override.pm',    # finds $VERSION
    PREREQ_PM    => {
        'Test::More'  => .47,
        'Test::Fatal' => '0.010',
    },
    (   $] >= 5.005
        ? ( ABSTRACT_FROM => 'lib/Sub/Override.pm',
            AUTHOR        => 'Curtis Poe <ovid@cpan.org>'
          )
        : ()
    ),
    META_MERGE => {
        resources => {
            repository => 'https://github.com/Ovid/sub-override',
        },
    },
);

# reverse the email name to get my email address
