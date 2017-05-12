

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
system("svnadmin help > /dev/null") and die "SVN binaries are not found!";
WriteMakefile(
    NAME         => 'SVN::Agent',
    VERSION_FROM => 'lib/SVN/Agent.pm', # finds \$VERSION
    AUTHOR       => 'Boris Sukholitko (boriss@gmail.com)',
    ABSTRACT     => 'Simple way of working with SVN',
    PREREQ_PM    => {
                     'Test::More' => '',
		     'File::Slurp' => '',
		     'Class::Accessor' => ''
                    },
);
