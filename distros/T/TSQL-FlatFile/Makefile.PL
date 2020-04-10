use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'TSQL::FlatFile',
    AUTHOR              => q{Ded MedVed <dedmedved@cpan.org>},
    VERSION_FROM        => 'lib/TSQL/FlatFile.pm',
    ABSTRACT_FROM       => 'lib/TSQL/FlatFile.pm',
    MIN_PERL_VERSION    => 5.10.0,
    ($ExtUtils::MakeMaker::VERSION >= 6.48
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    EXE_FILES => [ "gen-FormatFile.pl"
                 , "gen-SkeletonTable.pl"
                 , "renumber-FormatFile.pl"
                 , "test-FormatFile.pl"
                 , "gen-CsvHeader.pl"
                 ],
    PREREQ_PM => {
        'Test::More'                => 0,
        'Array::Diff'               => 0,
        'Carp'                      => 0,
        'Clone'                     => 0,
        'Data::Dumper'              => 0,
        'English'                   => 0,
        'File::Basename'            => 0,
        'Getopt::Euclid'            => 0,
        'IO::File'                  => 0,
        'Text::CSV'                 => 0,
        'List::MoreUtils'           => 0,
        'List::Util'                => 0,
        'Modern::Perl'              => 0,
        'Readonly'                  => 0,
        'Text::Diff'                => 0,
        'autodie'                   => 0,
        'indirect'                  => 0,
        'version'                   => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => '/TSQL/FlatFile-*' },
);



