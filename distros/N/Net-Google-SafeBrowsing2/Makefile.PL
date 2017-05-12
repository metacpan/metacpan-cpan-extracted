use 5.008008;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Net::Google::SafeBrowsing2',
    VERSION_FROM      => 'lib/Net/Google/SafeBrowsing2.pm', # finds $VERSION
    PREREQ_PM         => {
		LWP::UserAgent			=> 0,
		URI				=> 0,
		Digest::SHA			=> 0,
		List::Util			=> 0,
		constant			=> 0,
		Test::More			=> 0,
		Text::Trim			=> 0,
		Digest::HMAC_SHA1		=> 0,
		MIME::Base64::URLSafe		=> 0,
		MIME::Base64			=> 0,
		String::HexConvert		=> 0,
		File::Slurp			=> 0,
		IO::Socket::SSL			=> 0,
	},
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Net/Google/SafeBrowsing2.pm', # retrieve abstract from module
       AUTHOR         => 'Julien Sobrier <julien@sobrier.net>') : ()),
);
