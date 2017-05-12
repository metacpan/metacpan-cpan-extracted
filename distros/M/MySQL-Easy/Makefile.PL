
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'         => 'MySQL::Easy',
    'VERSION_FROM' => 'Easy.pm',
    'PREREQ_PM'    => { DBI => 0, 'DBD::mysql' => 0, 'common::sense' => 0 },

    ($ExtUtils::MakeMaker::VERSION ge '6.48'? 
        (MIN_PERL_VERSION => 5.006001,
            META_MERGE => {
                keywords => ['mysql', 'helper', 'easy'],
                resources=> { repository => 'http://github.com/jettero/mysql--easy' },
            },

        LICENSE	=> 'LGPL',
    ) : ()),
);
