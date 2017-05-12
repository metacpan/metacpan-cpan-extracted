

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Mojo::Run',
    VERSION_FROM => 'lib/Mojo/Run.pm', # finds \$VERSION
    AUTHOR       => 'Alexey Likhatskiy (likhatski@cpan.org)',
    ABSTRACT     => 'Asynchronous external command execution',
    PREREQ_PM    => {
     'Test::Simple' => 0.44,
     'Mojolicious'  => 2.77,
    },
);
