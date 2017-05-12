use ExtUtils::MakeMaker;

WriteMakefile(
	NAME => "Net::Domain::Info",
	VERSION_FROM => "lib/Net/Domain/Info.pm",
	'dist' => { COMPRESS=>"gzip", SUFFIX=>"gz" },
	AUTHOR => 'Ivan Baktsheev <dot.and.thing@gmail.com>',
	PREREQ_PM => {
		'Unicode::Stringprep' => 1.00,
		
		'WWW::Google::PageRank' => 0,
		'WWW::Yahoo::InboundLinks' => 0,
		'WWW::Yandex::TIC' => 0,
		
		'Net::Domain::ExpireDate' => 0,
		'Net::Whois::Raw' => 0,
		
		'Class::Easy' => 0,
	}
);
