use ExtUtils::MakeMaker;
require 5.008;

my $mm_ver = ExtUtils::MakeMaker->VERSION;

WriteMakefile(
    NAME         => 'Perl::Download::FTP',
    VERSION_FROM => 'lib/Perl/Download/FTP.pm', # finds \$VERSION
    AUTHOR       => 'James E Keenan (jkeenan@cpan.org)',
    ABSTRACT     => 'Identify Perl releases and download the most recent via FTP',
    MIN_PERL_VERSION => '5.10.1',
    PREREQ_PM    => {
                     'Net::FTP'     => 0,
                     'Carp'         => 0,
                     'Cwd'          => 0,
                     'File::Copy'   => 0,
                     'File::Spec'   => 0,
    },
    ( $mm_ver < 6.63_03 ? 'BUILD_REQUIRES' : 'TEST_REQUIRES' )
                    =>  {
                            'Test::Simple' => 0.44,
                            'List::Compare' => 0.51,
                            'Test::RequiresInternet' => 0,
                            'Capture::Tiny' => 0,
                            'File::Path' => 2.06,
                        },
    ($mm_ver < 6.46 ? () : (META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        resources => {
            homepage => 'http://thenceforward.net/perl/modules/Perl-Download-FTP/',
            repository => {
                url => 'https://github.com/jkeenan/perl-download-ftp.git',
                web => 'https://github.com/jkeenan/perl-download-ftp',
                type => 'git',
            },
            bugtracker => {
                web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Perl-Download-FTP',
            },
        },
    })),
    ($mm_ver < 6.31 ? () : (LICENSE => 'perl_5')),
);
