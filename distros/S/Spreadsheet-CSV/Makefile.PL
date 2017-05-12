use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

my $ext_utils_version = $ExtUtils::MakeMaker::VERSION;
$ext_utils_version =~ s/^(\d+(?:\.\d+)).*$/$1/; # force the version to be a number, not something like \d\.\d+_\d+

WriteMakefile(
    NAME             => 'Spreadsheet::CSV',
    AUTHOR           => q{David Dick <ddick@cpan.org>},
    VERSION_FROM     => 'lib/Spreadsheet/CSV.pm',
    ABSTRACT_FROM    => 'lib/Spreadsheet/CSV.pm',
    ($ext_utils_version >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    MIN_PERL_VERSION => 5.010,
    PL_FILES         => {},
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
	'CGI' => 0,
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Fcntl' => 0,
        'Spreadsheet::ParseExcel' => 0,
        'Text::CSV_XS' => 1.00, # UTF-8 fixes
        'Archive::Zip' => 0,
	'File::Temp' => 0,
        'XML::Parser' => 0,
        'English' => 0,
        'Fcntl' => 0,
        'charnames' => 0,
        'Compress::Zlib' => 0,
        'Carp' => 0,
        'IO::File' => 0,
        'strict' => 0,
        'warnings' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Spreadsheet-CSV-*' },
);
