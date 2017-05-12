use 5.008;
use ExtUtils::MakeMaker;

my $o = $Config{_o};
print "Now attempting to compile and install supporting library to /usr/lib\n";
chdir "./mdns";
system qw [ make install ];
chdir "../";

sub MY::postamble	{
'
$(MYEXTLIB): mdns/Makefile
	cd mdns && $(MAKE) $(PASSTHRU)
';
}
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Net::MDNS::Server',
    'VERSION_FROM'	=> 'Server.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Server.pm', # retrieve abstract from module
       AUTHOR     => 'Jepri <jepri@perlmonk.org>') : ()),
		'LDFROM'	=>	'$(OBJECT) ./mdns/libmdns_server.so ',
    'LIBS'		=> ['-L./mdns/ -lmdns_server'], # e.g., '-lm'
    'DEFINE'		=> '', # e.g., '-DHAVE_SOMETHING'
    'INC'		=> '-I. -I./mdns', # e.g., '-I. -I/usr/include/other'
		'MYEXTLIB'	=>	'./mdns/libmdns_server$(LIB_EXT)',
	# Un-comment this if you add C files to link with later:
    # 'OBJECT'		=> '$(O_FILES)', # link all the C files too
);
if  (eval {require ExtUtils::Constant; 1}) {
  # If you edit these definitions to change the constants used by this module,
  # you will need to use the generated const-c.inc and const-xs.inc
  # files to replace their "fallback" counterparts before distributing your
  # changes.
  my @names = (qw());
  ExtUtils::Constant::WriteConstants(
                                     NAME         => 'Net::MDNS::Server',
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

