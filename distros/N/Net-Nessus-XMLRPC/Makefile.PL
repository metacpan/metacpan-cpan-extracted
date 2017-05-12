use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Net::Nessus::XMLRPC',
    AUTHOR              => 'Vlatko Kosturjak <kost@linux.hr>',
    VERSION_FROM        => 'lib/Net/Nessus/XMLRPC.pm',
    ABSTRACT_FROM       => 'lib/Net/Nessus/XMLRPC.pm',
($ExtUtils::MakeMaker::VERSION >= 6.3002 ?
	('LICENSE'		=> 'perl', ) : ()),
($ExtUtils::MakeMaker::VERSION < 6.46 ? () : (
    META_MERGE          => {
	    resources => {
	    bugtracker  =>      'https://rt.cpan.org/Public/Bug/Report.html?Queue=Net-Nessus-XMLRPC',
	    repository  =>      'http://github.com/kost/nessus-xmlrpc-perl'
	    }
    })),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	'XML::Simple' => 0,
	'HTTP::Request::Common' => 0,
	'LWP::UserAgent' => 0 
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Net-Nessus-XMLRPC-*' },
);
