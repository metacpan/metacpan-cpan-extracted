use ExtUtils::MakeMaker;

WriteMakefile(
	NAME => "Net::RabbitMQ::Channel",
	VERSION_FROM => "lib/Net/RabbitMQ/Channel.pm",
	'dist' => { COMPRESS=>"gzip", SUFFIX=>"gz" },
	AUTHOR => 'Ivan Baktsheev <dot.and.thing@gmail.com>',
	META_MERGE      => {
		resources => {
			license     =>      'http://dev.perl.org/licenses/',
			homepage    =>      'http://perlhug.com',
			bugtracker  =>      'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-RabbitMQ-Channel',
			repository  =>      'git://web-app.git.sourceforge.net/gitroot/perl-easy/perl-easy',
			#			MailingList =>      'makemaker@perl.org',
		},
	},
	PREREQ_PM => {
		'Class::Easy'   => '0.11',
		'Net::RabbitMQ' => '0.1.8',
		# hello, windows
		($^O eq 'MSWin32' ? () : ('Sys::SigAction' => '0.11'))
	}
);
