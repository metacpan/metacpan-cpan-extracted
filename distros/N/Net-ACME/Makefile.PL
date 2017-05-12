
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Net::ACME',
    VERSION_FROM => 'lib/Net/ACME/Constants.pm',            # finds \$VERSION
    AUTHOR       => 'Felipe Gasper',
    ABSTRACT     => 'Client logic for the ACME protocol',
    LICENSE      => 'perl',
    MIN_PERL_VERSION => '5.8.9',
    PREREQ_PM    => {
        'autodie'                  => 0,
        'constant'                 => 1.23,
        'parent'                   => 0.225,
        'Call::Context'            => 0.02,
        'Crypt::Format'            => 0.06,
        'Crypt::Perl'              => '0.17',
        'Digest::SHA'              => 0,
        'HTTP::Tiny'               => 0.058,
        'HTTP::Tiny::UA::Response' => 0.004,
        'JSON'                     => 2.9,
        'MIME::Base64'             => 3.11,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/FGasper/p5-Net-ACME.git',
                web  => 'https://github.com/FGasper/p5-Net-ACME',
            },
        },
    },
    TEST_REQUIRES => {
        'File::Slurp'     => 0,
        'Test::Class'     => 0.4,
        'Test::More'      => 1.0,
        'Test::Deep'      => 0,
        'Test::Simple'    => 0.44,
        'Test::Exception' => 0.40,
    },
);
