use 5.012001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Net::Chaton::API',
    VERSION_FROM      => 'lib/Net/Chaton/API.pm', # finds $VERSION
    PREREQ_PM         => {
    	'Pipe::Between::Object' => 0.01,
	'LWP::UserAgent' => 5.835,
	'HTTP::Request::Common' => 5.824,
	'JSON' => 2.22,
	'Desktop::Notify' => 0.03,
	'Encode::Guess' => 2.03,
	'Encode' => 2.39
	}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Net/Chaton/API.pm', # retrieve abstract from module
       AUTHOR         => 'Pocket <poketo7878@yahoo.co.jp>') : ()),
);
