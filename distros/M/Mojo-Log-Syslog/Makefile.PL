use 5.010001;

use strict;
use ExtUtils::MakeMaker;
use Module::Metadata;

WriteMakefile(
    NAME => 'Mojo::Log::Syslog',
    VERSION_FROM => 'lib/Mojo/Log/Syslog.pm',
    ABSTRACT_FROM => 'lib/Mojo/Log/Syslog.pm',
    AUTHOR => 'Sergey Poznyakoff <gray@gnu.org>',
    LICENSE      => 'artistic_2',
    PREREQ_PM => {
	'Mojolicious' => '7.58',
	'Sys::Syslog' => 0
    },
    META_MERGE   => {
	'meta-spec' => { version => 2 },
	resources => {
	    repository => {
		type => 'git',
		url => 'git://git.gnu.org.ua/mojosyslog.git',
		web => 'http://git.gnu.org.ua/cgit/mojosyslog.git/',
	    },
	}
    }
);
