use ExtUtils::MakeMaker;

WriteMakefile(
    NAME		=> 'OSPF::LSDB',
    AUTHOR		=> 'BLUHM (bluhm@cpan.org)',
    EXE_FILES		=> [qw(
	script/ospf2dot
	script/ospfd2yaml
	script/gated2yaml
	script/ospfconvert
	script/ciscoospf2yaml
	script/ospfview
	script/ospfview.cgi
    )],
    MAN1PODS		=> {
	'doc/ospf2dot.pod'	=> 'blib/man1/ospf2dot.1',
	'doc/ospfd2yaml.pod'	=> 'blib/man1/ospfd2yaml.1',
	'doc/gated2yaml.pod'	=> 'blib/man1/gated2yaml.1',
	'doc/ospfconvert.pod'	=> 'blib/man1/ospfconvert.1',
	'doc/ciscoospf2yaml.pod'	=> 'blib/man1/ciscoospf2yaml.1',
	'doc/ospfview.pod'	=> 'blib/man1/ospfview.1',
	'doc/ospfview.cgi.pod'	=> 'blib/man1/ospfview.cgi.1',
    },
    SIGN		=> 1,
    VERSION_FROM	=> 'lib/OSPF/LSDB.pm',
    MIN_PERL_VERSION	=> '5.10.0',
    PREREQ_PM		=> {
	"Data::Validate"		=> 0,
	"Data::Validate::Struct"	=> 0,
	"File::Slurp"			=> 0,
	"List::MoreUtils"		=> 0,
	"Regexp::Common"		=> 0,
	"Regexp::IPv6"			=> 0,
	"Test::NoWarnings"		=> 0,  # for test
	"Test::Pod"			=> 0,  # for test
	"Test::Strict"			=> 0,  # for test
	"YAML::Syck"			=> 0,
    },
);
