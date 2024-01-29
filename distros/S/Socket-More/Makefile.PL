use ExtUtils::MakeMaker;

WriteMakefile(
	NAME              => 'Socket::More',
	VERSION_FROM      => 'lib/Socket/More.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
	PREREQ_PM         => {
		'Data::Cmp'=>0,
		'Net::IP::Lite'=>0,
    
    'Socket::More::Lookup'=>0,
    'Socket::More::Constants'=>"v0.1.1",
    'Socket::More::Interface'=>0,
    "Export::These"=>"v0.2.1",
    "Import::These"=>"v0.1.2",
    "constant::more"=>"v0.3.0",
		'Data::Combination'=>0,

	}, # e.g., Module::Name => 1.1
	MIN_PERL_VERSION=>"v5.36.0",
	TEST_REQUIRES	=>{
		'Data::Cmp'=>0
	},
	ABSTRACT_FROM     => 'lib/Socket/More.pod', # retrieve abstract from module
	AUTHOR            => 'Ruben Westerberg <drclaw@mac.com>',
	LICENSE           => 'mit',
	META_ADD => {
		"meta-spec" => {
			version => 2
		},
		resources=> {
			repository =>{
				type => "git",
				url => "git://github.com/drclaw1394/perl-socket-more.git",
				web => "http://github.com/drclaw1394/perl-socket-more",
			}
		}
	}
	
);
