use 5.010000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Net::uTorrent',
    VERSION_FROM      => 'lib/Net/uTorrent.pm', # finds $VERSION
    PREREQ_PM         => {

				'URI'			=> 0,
				'URI::QueryParam'	=> 0,
				'HTTP::Request::Common'	=> 0,
				'LWP::UserAgent'	=> 0,
				'JSON::XS'		=> 0,
				'HTML::TreeBuilder'	=> 0,
			 },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Net/uTorrent.pm', # retrieve abstract from module
       AUTHOR         => 'rarbox <rarbox@cpan.org>') : ()),
);
