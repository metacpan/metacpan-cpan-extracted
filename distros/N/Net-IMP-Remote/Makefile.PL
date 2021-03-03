use ExtUtils::MakeMaker;
require 5.10.0;

WriteMakefile(
    NAME => 'Net::IMP::Remote',
    ABSTRACT => 'RPC Interface for External IMP Plugins',
    AUTHOR => 'Steffen Ullrich <sullr@cpan.org>',
    VERSION_FROM => 'lib/Net/IMP/Remote.pm',
    LICENSE => 'perl',
    PREREQ_PM => {
	'Net::IMP' => 0.618,
	# useful but not necessary
	#'Sereal::Decoder' => 0.36,
	#'Sereal::Encoder' => 0.36,
    },
    META_MERGE => {
	resources => {
	    license => 'http://dev.perl.org/licenses/',
	    homepage  => 'https://github.com/noxxi/p5-net-imp-remote',
	    repository => 'https://github.com/noxxi/p5-net-imp-remote',
	    bugtracker => 'https://github.com/noxxi/p5-net-imp-remote/issues',
	},
   },
);

