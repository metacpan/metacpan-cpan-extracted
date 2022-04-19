use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    ABSTRACT_FROM	=> 'lib/OSPF/LSDB.pm',
    AUTHOR		=> 'BLUHM <bluhm@cpan.org>',
    EXE_FILES		=> [qw(
	script/ospf2dot
	script/ospfd2yaml
	script/gated2yaml
	script/ospfconvert
	script/ciscoospf2yaml
	script/ospfview
	script/ospfview.cgi
    )],
    LICENSE		=> 'bsd',
    MAN1PODS		=> {
	'doc/ospf2dot.pod'	=> 'blib/man1/ospf2dot.1',
	'doc/ospfd2yaml.pod'	=> 'blib/man1/ospfd2yaml.1',
	'doc/gated2yaml.pod'	=> 'blib/man1/gated2yaml.1',
	'doc/ospfconvert.pod'	=> 'blib/man1/ospfconvert.1',
	'doc/ciscoospf2yaml.pod'	=> 'blib/man1/ciscoospf2yaml.1',
	'doc/ospfview.pod'	=> 'blib/man1/ospfview.1',
	'doc/ospfview.cgi.pod'	=> 'blib/man1/ospfview.cgi.1',
    },
    META_MERGE	=> {
	'meta-spec'	=> { version => 2 },
	resources => {
	    homepage	=> 'https://sourceforge.net/projects/ospfview/',
	    repository	=> {
		type	=> 'git',
		url	=> 'git://git.code.sf.net/p/ospfview/code',
	    },
	},
    },
    MIN_PERL_VERSION	=> '5.10.0',
    NAME		=> 'OSPF::LSDB',
    PREREQ_PM		=> {
	"CGI"				=> 0,
	"Data::Validate"		=> 0,
	"Data::Validate::Struct"	=> 0,
	"File::Slurp"			=> 0,
	"File::Temp"			=> 0,
	"Getopt::Long"			=> 0,
	"IPC::Open2"			=> 0,
	"List::MoreUtils"		=> 0,
	"POSIX"				=> 0,
	"Regexp::Common"		=> 0,
	"Regexp::IPv6"			=> 0,
	"Sys::Hostname"			=> 0,
	"Time::HiRes"			=> 0,
	"YAML::Syck"			=> 0,
    },
    SIGN		=> 1,
    TEST_REQUIRES	=> {
	"Pod::Checker"			=> 0,
	"Test::EOL"			=> 0,
	"Test::More"			=> 0,
	"Test::NoWarnings"		=> 0,
	"Test::Pod"			=> '1.00',
	"Test::Requires"		=> 0,
	"Test::Strict"			=> 0,
    },
    VERSION_FROM	=> 'lib/OSPF/LSDB.pm',
);
