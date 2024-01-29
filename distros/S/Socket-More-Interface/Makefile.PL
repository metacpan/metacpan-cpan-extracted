use 5.036000;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Socket::More::Interface',
    VERSION_FROM      => 'lib/Socket/More/Interface.pm',
    PREREQ_PM         => {
      "Export::These"=> 'v0.2.1' 
    },
    ABSTRACT_FROM     => 'lib/Socket/More/Interface.pod', 
    

	MIN_PERL_VERSION=>"v5.36.0",
	AUTHOR            => 'Ruben Westerberg <drclaw@mac.com>',
	LICENSE           => 'mit',
	LIBS              => [''], # e.g., '-lm'
	DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
	INC               => '-I.', # e.g., '-I. -I/usr/include/other'
	MIN_PERL_VERSION=>"v5.36.0",
	META_ADD => {
		"meta-spec" => {
			version => 2
		},
		resources=> {
			repository =>{
				type => "git",
				url => "git://github.com/drclaw1394/perl-socket-more-interface.git",
				web => "https://github.com/drclaw1394/perl-socket-more-interface",
			}
		}
	}
	





);

if  (eval {require ExtUtils::Constant; 1}) {
  # If you edit these definitions to change the constants used by this module,
  # you will need to use the generated const-c.inc and const-xs.inc
  # files to replace their "fallback" counterparts before distributing your
  # changes.
  my @names = (qw());
  ExtUtils::Constant::WriteConstants(
                                     NAME         => 'Socket::More::Interface',
                                     NAMES        => \@names,
                                     DEFAULT_TYPE => 'IV',
                                     C_FILE       => 'const-c.inc',
                                     XS_FILE      => 'const-xs.inc',
                                  );

}
else {
  use File::Copy;
  use File::Spec;
  foreach my $file ('const-c.inc', 'const-xs.inc') {
    my $fallback = File::Spec->catfile('fallback', $file);
    copy ($fallback, $file) or die "Can't copy $fallback to $file: $!";
  }
}
