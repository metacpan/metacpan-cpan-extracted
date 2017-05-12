use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'POE::Component::Server::HTTPServer',
    'VERSION_FROM' => 'lib/POE/Component/Server/HTTPServer.pm',
    'PREREQ_PM'		=> {
			    'POE' => 0,
			    'MIME::Types' => 1.06,
			    # these are from libwww-perl (req >=5.76)
			    'HTTP::Status' => 0,
			    'URI::Escape' => 0,
			    'HTTP::Message' => 1.30
			   }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (AUTHOR     => 'Greg Fast <gdf@speakeasy.net>') : ()),
);
