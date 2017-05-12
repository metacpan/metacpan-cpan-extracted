use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'TSQL::SplitStatement',
    AUTHOR              => q{Ded MedVed <dedmedved@cpan.org>},
    VERSION_FROM        => 'lib/TSQL/SplitStatement.pm',
    ABSTRACT_FROM       => 'lib/TSQL/SplitStatement.pm',
    MIN_PERL_VERSION    => 5.10.0,
    ($ExtUtils::MakeMaker::VERSION >= 6.48
      ? ('LICENSE'=> 'perl_5')
      : ()),
    PL_FILES            => {},
    EXE_FILES => [ "grepTSQL.pl" 
                 ],
    
    PREREQ_PM => {
        'Test::More'                => 0,
        'Test::Deep'                => 0,
        'Carp'                      => 0,
        'Clone'                     => 0,
        'Data::Dumper'              => 0,
        'Data::Dump'                => 0,
        'IPC::System::Simple'       => 0, 
        'List::MoreUtils'           => 0,
        'List::Util'                => 0,
        'TSQL::Common::Regexp'      => 0.05,
        'autodie'                   => 0,
        'indirect'                  => 0,
        'version'                   => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'TSQL-SplitStatement-*' },
);



