use ExtUtils::MakeMaker;
WriteMakefile(
  NAME              => 'Socket::More::Resolver',
  VERSION_FROM      => 'lib/Socket/More/Resolver.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
  PREREQ_PM         => {
    "Export::These"=>"v0.2.1",
    "constant::more"=>"v0.3.0",
    "Socket::More::Constants"=>"v0.1.1",
    "Socket::More::Lookup"=>0
    ,
  }, # e.g., Module::Name => 1.1
  ABSTRACT_FROM     => 'lib/Socket/More/Resolver.pod', # retrieve abstract from module
  AUTHOR            => 'Ruben Westerberg <drclaw@mac.com>',
  LICENSE           => 'mit',
	MIN_PERL_VERSION=>"v5.36.0",
	META_ADD => {
		"meta-spec" => {
			version => 2
		},
		resources=> {
			repository =>{
				type => "git",
				url => "git://github.com/drclaw1394/perl-socket-more-resolver.git",
				web => "https://github.com/drclaw1394/perl-socket-more-resolver",
			}
		}
  }

);
