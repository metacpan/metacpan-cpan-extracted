use ExtUtils::MakeMaker;
use strict;

WriteMakefile(
	NAME			=> 'Mojo::Zabbix',
	VERSION_FROM	        => 'lib/Mojo/Zabbix.pm',
	ABSTRACT_FROM           => 'lib/Mojo/Zabbix.pm',
        AUTHOR			=> 'Orange <bollwarm@ijz.me>',
	LICENSE			=> 'Perl',
	PREREQ_PM		=> {
		"Mojolicious"   => '6.11',
                'Scalar::Util'	=> 0,
		'Carp'		=> 0,
		'Time::HiRes'	=> 0,
		'POSIX'		=> 0,
	},
       META_MERGE => {
          'meta-spec' => { version => 2 },
           resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/bollwarm/Mojo-Zabbix',
                web  => 'http://ijz.me',
            },
        },
    },
);
