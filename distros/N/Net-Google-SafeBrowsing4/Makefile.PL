#use 5.010001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	NAME			=> 'Net::Google::SafeBrowsing4',
	VERSION_FROM	=> 'lib/Net/Google/SafeBrowsing4.pm',
	PREREQ_PM		=> {
		constant		=> 0,
		Carp			=> 0,
		Digest::SHA		=> 0,
		Exporter		=> 0,
		HTTP::Message		=> 0,
		JSON::XS		=> 0,
		List::Util		=> 0,
		LWP::UserAgent		=> 0,
		MIME::Base64		=> 0,
		Net::IP::Lite		=> 0,
		Path::Tiny		=> 0,
		Storable		=> 0,
		Test::More		=> 0.92,
		Test::Pod::Coverage	=> 0,
		Test::LWP::UserAgent	=> 0,
		Text::Trim		=> 0,
		Time::HiRes		=> 0,
		URI			=> 1.61,
		List::BinarySearch	=> 0,
	},
	META_MERGE => {
		'meta-spec' => { version => 2 },
			resources => {
				repository => {
				type => 'git',
				url => 'https://github.com/juliensobrier/Net-Google-SafeBrowsing4.git',
				web => 'https://github.com/juliensobrier/Net-Google-SafeBrowsing4',
			},
		},
	},
	(
		$] >= 5.005 ?     ## Add these new keywords supported since 5.005
			(
				ABSTRACT_FROM	=> 'lib/Net/Google/SafeBrowsing4.pm', # retrieve abstract from module
				AUTHOR			=> 'Julien Sobrier <julien@sobrier.net>'
			) : ()
	),
);
