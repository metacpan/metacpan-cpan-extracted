#use 5.010001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Net::Google::SafeBrowsing3',
    VERSION_FROM      => 'lib/Net/Google/SafeBrowsing3.pm', # finds $VERSION
    PREREQ_PM         => {
		LWP::UserAgent			=> 0,
		URI				=> 0,
		Digest::SHA			=> 0,
		List::Util			=> 0,
		constant			=> 0,
		Test::More			=> 0,
		Text::Trim			=> 0,
		Google::ProtocolBuffers		=> 0,
		MIME::Base64::URLSafe		=> 0,
		MIME::Base64			=> 0,
		String::HexConvert		=> 0,
		IO::Socket::SSL			=> 0,
		Data::Dumper			=> 0,
    },
    META_MERGE => {
	'meta-spec' => { version => 2 },
		resources => {
			repository => {
			type => 'git',
			url => 'https://github.com/juliensobrier/Net-Google-SafeBrowsing3.git',
			web => 'https://github.com/juliensobrier/Net-Google-SafeBrowsing3',
		},
	},
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Net/Google/SafeBrowsing3.pm', # retrieve abstract from module
       AUTHOR         => 'Julien Sobrier <julien@sobrier.net>') : ()),
);
