use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Net::Traceroute::PurePerl',
    'VERSION_FROM'	=> 'PurePerl.pm', # finds $VERSION
    'PREREQ_PM'		=> { Net::Traceroute => 1.05 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      ( 'AUTHOR'     => 'Tom Scanlan <tscanlan@openreach.com>, Andrew Hoying <ahoying@cpan.org', 'ABSTRACT' => 'traceroute(1) functionality in perl via raw sockets' ) : ()),
    dist		=> {
	'COMPRESS'	=> 'gzip',
	'SUFFIX'	=> 'gz'
    },
);
