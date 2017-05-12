use ExtUtils::MakeMaker;

WriteMakefile(
	NAME              => "Net::Telnet::Huawei",
	VERSION_FROM      => "lib/Net/Telnet/Huawei.pm",
	ABSTRACT => 'Tools for Huawei network devices',
	AUTHOR => 'canw(nodejs@live.cn)',
	LICENSE => 'MIT',
	MIN_PERL_VERSION => 5.10.0,
	NO_META => 1,
);

