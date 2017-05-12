use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'		=> 'Remedy::ARSTools',
    'VERSION_FROM'	=> 'ARSTools.pm',
    'ABSTRACT_FROM'	=> 'ARSTools.pod',
    'AUTHOR'		=> 'Andrew N. Hicox <andrew@hicox.com>',
    'PREREQ_PM'		=> {
        'Data::DumpXML'		=> 1.03,
        'ARS'			=> 1.72,
        'Date::Parse'		=> 2.30,
        'Time::Interval'	=> 1.233
    }
);
