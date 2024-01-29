use 5.036000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Socket::More::Lookup',
    VERSION_FROM      => 'lib/Socket/More/Lookup.pm', 
    PREREQ_PM         => {
      "Export::These" =>"v0.2.1",
      "Socket::More::Constants"=>"v0.1.1",
      "constant::more"=>"v0.3.0",
    }, 
    ABSTRACT_FROM     => 'lib/Socket/More/Lookup.pod', 
    AUTHOR            => 'Ruben Westerberg <drclaw@mac.com>',
    LIBS              => [''], 
    DEFINE            => '', 
    INC               => '-I.',

	MIN_PERL_VERSION=>"v5.36.0",
	META_ADD => {
		"meta-spec" => {
			version => 2
		},
		resources=> {
			repository =>{
				type => "git",
				url => "git://github.com/drclaw1394/perl-socket-more-lookup.git",
				web => "https://github.com/drclaw1394/perl-socket-more-lookup",
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
                                     NAME         => 'Socket::More::Lookup',
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
