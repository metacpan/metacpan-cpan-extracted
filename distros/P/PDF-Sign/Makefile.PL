use strict;
use warnings;
use ExtUtils::MakeMaker;

# PDF::Sign requires either PDF::API2 or PDF::Builder
my $has_pdf_api2   = eval { require PDF::API2;   1 };
my $has_pdf_builder = eval { require PDF::Builder; 1 };

# ID:174516 by SREZIC@cpan.org
# exit the Makefile.PL prematurely in this situation (this will give a NA or UNKNOWN report, not a FAIL report)
# 
unless ($has_pdf_api2 || $has_pdf_builder) {
    warn <<'END_WARN';

PDF::Sign requires either PDF::API2 or PDF::Builder to be installed.
Please install one of them first:

    cpanm PDF::API2
  or
    cpanm PDF::Builder

END_WARN
    exit 0;   # NA report, not FAIL
}

# ID:174516 Determine which to add to PREREQ as suggested by SREZIC@cpan.org
my $pdf_dep = $has_pdf_api2
    ? { 'PDF::API2'   => '2.038' }
    : { 'PDF::Builder' => '3.025' };

WriteMakefile(
    NAME             => 'PDF::Sign',
    AUTHOR           => 'Massimiliano Citterio <mcitterio@cmcps.it>',
    VERSION_FROM     => 'lib/PDF/Sign.pm',
    ABSTRACT_FROM    => 'lib/PDF/Sign.pm',
    LICENSE          => 'perl',
    MIN_PERL_VERSION => '5.010',
    PREREQ_PM => {
        'Exporter'              => 0,
        'Cwd'                   => 0,
        'POSIX'                 => 0,
        'Time::Local'           => 0,
        'MIME::Base64'          => 0,
        'File::Slurp'           => 0,
         %$pdf_dep,
    },
    # PDF::API2 or PDF::Builder — one required, checked at runtime in BEGIN
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.64',
    },
    TEST_REQUIRES => {
        'Test::More' => '0.88',
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'cvs',
                url  => '',
            },
        },
        prereqs => {
            runtime => {
                recommends => {
                    'PDF::API2'        => 0,
                    'LWP::UserAgent'   => 0,
                },
                suggests => {
                    'PDF::Builder'     => 0,
                },
            },
        },
    },
    META_ADD => {
        provides => {
            'PDF::Sign' => { file => 'lib/PDF/Sign.pm', version => '0.07' },
        },
    },  
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    clean => { FILES    => 'PDF-Sign-*' },
    macro => { TARFLAGS   => "--format=ustar -c -v -f"},
);
