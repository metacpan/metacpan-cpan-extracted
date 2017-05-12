use 5.008008;
use ExtUtils::MakeMaker;

my $tests = 't/Local/*.t';
if( ! $ENV{AUTOMATED_TESTING} ) {
    if ( prompt(
        "External tests require a running apache sling instance to test against!\n".
        'Skip external tests?',
        'y',
        ) =~ /^n/i ) {
        $tests = 't/Local/*.t t/External/*.t';
    }
}

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Sakai::Nakamura',
    VERSION_FROM      => 'lib/Sakai/Nakamura.pm', # finds $VERSION
    PREREQ_PM         => {Apache::Sling => 0.27},
    test              => { TESTS => $tests },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Sakai/Nakamura.pm', # retrieve abstract from module
       AUTHOR         => 'D. D. Parry <perl@ddp.me.uk>') : ()),
);
