use 5.006;
use ExtUtils::MakeMaker;

print "Please, enter your api and secret keys from bobrdobr.ru site\n";
my $api_key = prompt ("api key: ");
my $sec_key = prompt ("api secure key: ");

WriteMakefile(
    NAME	=> "Net::BobrDobr",
    VERSION	=> "0.04",
    PREREQ_PM	=> { 'Digest::MD5' => 0,
		     'LWP::UserAgent' => 0,
		     'URI::Escape' => 0,
		     'IO::File' => 0,
		     'XML::Simple' => 0 },
    ABSTRACT	=> "Using BobrDobr.ru service",
    AUTHOR	=> "Artur Penttinen <artur+perl\@niif.spb.su>"
);

unless ($api_key eq "" || $api_sec eq "") {
	open F,"> bobr-api";
	print F "api-key: $api_key\napi-secret: $api_sec\n";
	close F;
}

exit;

### That's all, folks!
