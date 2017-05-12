use 5.014000;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME              => 'Plack::Middleware::BasicStyle',
	VERSION_FROM      => 'lib/Plack/Middleware/BasicStyle.pm',
	ABSTRACT_FROM     => 'lib/Plack/Middleware/BasicStyle.pm',
	AUTHOR            => 'Marius Gavrilescu <marius@ieval.ro>',
	MIN_PERL_VERSION  => '5.14.0',
	LICENSE           => 'perl',
	SIGN              => 1,
	PREREQ_PM         => {
		qw/HTML::Parser          0
		   Plack::Middleware     0
		   Plack::Request        0
		   Plack::Util           0
		   Plack::Util::Accessor 0/,
	},
	TEST_REQUIRES    => {
		qw/HTTP::Request::Common 0
		   Plack::Builder        0
		   Plack::Test           0
		   Test::More            0/,
	},
	META_ADD           => {
		dynamic_config => 1,
		resources      => {
			repository => 'https://git.ieval.ro/?p=plack-middleware-basicstyle.git',
		},
	}
);
