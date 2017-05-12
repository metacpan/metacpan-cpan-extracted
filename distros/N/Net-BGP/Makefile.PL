use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'              => 'Net::BGP',
    'ABSTRACT'          => 'Object-oriented API to the BGP protocol',
    'AUTHOR'            => 'Stephen J. Scheck <sscheck@cpan.org>',
    'LICENSE'           => 'perl_5',
    'VERSION_FROM'      => 'lib/Net/BGP.pm', # finds $VERSION
    'SIGN'              => 1,
    'PREREQ_PM'         => {
        'IO::Select'    => 0,
        'IO::Socket'    => 0,
        'List::Util'    => 1.01, # Actully Scalar::Util - but no version there!
    },
    'TEST_REQUIRES'     => {
        'Test::Harness' => '2.00', # ?
        'Test::More'    => '0.47'
    }
);
