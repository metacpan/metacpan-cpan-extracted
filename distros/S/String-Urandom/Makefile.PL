use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    NAME         => 'String::Urandom',
    VERSION_FROM => 'lib/String/Urandom.pm', # finds \$VERSION
    AUTHOR       => 'Marc S. Brooks <mbrooks@cpan.org>',
    PREREQ_PM    => {
        'Test::More'       => 0.88,
        'Params::Validate' => 0,
    },
  );
