use 5.010;
use ExtUtils::MakeMaker;

my $version = qx{svnversion 2>/dev/null};
$version = sprintf("%d", (q$Revision: 114 $ =~ /\d+/g)[0])
    unless $version;
$version /= 1000;
$version += 1;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile
    (
     NAME              => 'Net::Radius::Server',
     VERSION           => $version,
     PREREQ_PM         => 
     {
	 'Class::Accessor'		=> 0.27,
	 'NetAddr::IP'			=> 4,
	 # PAM and LDAP are required if you intend to use them in your
	 # RADIUS processing
	 'Authen::PAM'			=> 0,
	 'BerkeleyDB'                   => 0,
	 'Net::LDAP'			=> 0,
	 # Net::Radius - We need dynamic packet types
	 # and other recent niceties
	 'Net::Radius::Packet'		=> 1.51,
	 'Net::Radius::Dictionary'	=> 1.51,
	 # We use Net::Server as our server's engine
	 'Net::Server'			=> 0.94,
	 # Utilities and tests use this
	 'IO::Async'			=> 0,
	 'IO::Prompt'			=> 0,
         'File::Find::Rule'             => 0,
         'Test::File::Contents'         => 0,
	 'Time::HiRes'                  => 0,
	 'Time::Stopwatch'              => 0,
	 'Statistics::Descriptive'      => 0,
	 'YAML::Syck'                   => 0,
	 'MLDBM::Sync'                  => 0,
     },
     EXE_FILES        => [ qw!
			   bin/nrsd
                           bin/nrsdbtoyaml
			   bin/rad-client
			   bin/pam-client
                           bin/rad-bulk
			   bin/rad-bulk-make
			   !],
     ($] >= 5.005 ?    
      (ABSTRACT_FROM  => 'lib/Net/Radius/Server.pm', 
       AUTHOR         => 'Luis E. Muñoz <luismunoz@cpan.org>') : ()),
     );
