use ExtUtils::MakeMaker;

WriteMakefile(
    NAME			=> 'Net::DNS::Namesrver::Trivial',
    AUTHOR			=> 'Lukasz Strzelecki <l.strzelecki@ita.wat.edu.pl>',
    VERSION_FROM	=> 'lib/Net/DNS/Nameserver/Trivial.pm',
#    ABSTRACT_FROM	=> 'lib/Net/DNS/Nameserver/Trivial.pm',
    PL_FILES		=> { },
    PREREQ_PM		=> {
		'Net::IP::XS'			=> 0,
		'Net::DNS'				=> 0,
		'Net::DNS::Nameserver'	=> 0,
		'Log::Tiny'				=> 0,
		'List::MoreUtils'		=> 0,
		'Cache::FastMmap'		=> 0,
		'Regexp::IPv6'			=> 0,
	},
);
