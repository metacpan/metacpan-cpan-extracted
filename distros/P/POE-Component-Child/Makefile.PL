use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    NAME                => 'POE::Component::Child',
    VERSION_FROM        => 'Child.pm', 
    $] < 5.005 ? () : (
        AUTHOR          => 'Erick Calder <ecalder@cpan.org>',
        ABSTRACT_FROM   => 'Child.pm',
        ),
    PREREQ_PM => {
        POE             => '0.23',
        Test::Simple    => 0,
        },
    );
