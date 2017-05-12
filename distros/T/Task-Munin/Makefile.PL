use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME         => 'Task::Munin',
	AUTHOR       => q{Gabor Szabo <szabgab@cpan.org>},
	VERSION_FROM => 'lib/Task/Munin.pm',
	ABSTRACT_FROM => 'lib/Task/Munin.pm',
	( $ExtUtils::MakeMaker::VERSION >= 6.3002
		? ( 'LICENSE' => 'perl' )
		: () ),
	PL_FILES  => {},
	PREREQ_PM => {
		'Module::Build'                => '0.21',
		'perl'                         => '5.10.0',
		'DBD::SQLite'                  => '1.42',
		'DBI'                          => '1.631',
		'HTML::Template::Pro'          => '0',
		'HTTP::Server::Simple::CGI'    => '0',
		'IO::Socket::INET6'            => '2.69',
		'LWP::UserAgent'               => '6.06',
		'List::Util'                   => '0',
		'List::MoreUtils'              => '0.33',
		'Log::Dispatch'                => '2.41',
		'Net::SNMP'                    => 'v6.0.1',
		'Net::SSLeay'                  => '1.65',
		'Net::Server::Daemonize'       => '0.06',
		'Net::Server::Fork'            => '0',
		'Params::Validate'             => '1.13',
		'Alien::RRDtool'               => '0',
		'URI'                          => '1.64',
		'XML::Dumper'                  => '0',
		'IO::Scalar'                   => '0',
		'Test::Class'                  => '0',
		'Test::Differences'            => '0.62',
		'Test::MockModule'             => '0',
		'Test::MockObject'             => '0',
		'Test::Deep'                   => '0',
		'Test::LongString'             => '0',
		'Test::Perl::Critic'           => '0',
		'File::Slurp'                  => '9999.19',
		'File::ReadBackwards'          => '0',
		'XML::Parser'                  => '0',
		'DBD::Pg'                      => '0',
		'Net::DNS'                     => '0',
		'Net::IP'                      => '0',
		'XML::LibXML'                  => '0',
	},
	META_MERGE => {
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type       => 'git',
				url        => 'http://github.com/szabgab/Task-Munin.git',
				web        => 'http://github.com/szabgab/Task-Munin',
				license    => 'http://dev.perl.org/licenses/',
			},
			bugtracker => {
				web        => 'http://github.com/szabgab/Task-Munin/issues',
			},
		},
	},

	dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
