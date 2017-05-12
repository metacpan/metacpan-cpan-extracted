use ExtUtils::MakeMaker;
require 5.10.0;
WriteMakefile(
    NAME => 'Net::IMP',
    ABSTRACT => 'Inspection and Modification Protocol to interface with proxies, IDS...',
    AUTHOR => 'Steffen Ullrich <sullr@cpan.org>',
    VERSION_FROM => 'lib/Net/IMP.pm',
    LICENSE => 'perl',
    PREREQ_PM => {
    },
    META_MERGE => {
	resources => {
	    license => 'http://dev.perl.org/licenses/',
	    homepage  => 'https://github.com/noxxi/p5-net-imp',
	    repository => 'https://github.com/noxxi/p5-net-imp',
	    bugtracker  => 'https://rt.cpan.org/Dist/Display.html?Queue=Net-IMP',
	},
   },
);

