use 5.014000;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME              => 'Plack::Middleware::Auth::Complex',
	VERSION_FROM      => 'lib/Plack/Middleware/Auth/Complex.pm',
	ABSTRACT_FROM     => 'lib/Plack/Middleware/Auth/Complex.pm',
	AUTHOR            => 'Marius Gavrilescu <marius@ieval.ro>',
	MIN_PERL_VERSION  => '5.14.0',
	EXE_FILES         => ['authcomplex-passwd'],
	LICENSE           => 'perl',
	SIGN              => 1,
	BUILD_REQUIRES    => {
		qw/DBD::SQLite           0
		   HTTP::Request::Common 0
		   Plack::Test           0/,
	},
	PREREQ_PM         => {
		qw/Authen::Passphrase                0
		   Authen::Passphrase::BlowfishCrypt 0
		   Bytes::Random::Secure             0
		   DBI                               0
		   Email::Simple                     0
		   Email::Sender::Simple             0
		   IO::Prompter                      0
		   Plack::Request                    0
		   Tie::Hash::Expire                 0/,
	},
	META_MERGE         => {
		dynamic_config => 0,
		resources      => {
			repository => 'https://git.ieval.ro/?p=plack-middleware-auth-complex.git',
		}
	}
);
