use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Spread::Client::Constant',
    VERSION_FROM      => 'lib/Spread/Client/Constant.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Spread/Client/Constant.pm', # retrieve abstract from module
       AUTHOR         => 'Marlon Bailey <mcbailey@localdomain>') : ()),
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
);
if  (eval {require ExtUtils::Constant; 1}) {
  # If you edit these definitions to change the constants used by this module,
  # you will need to use the generated const-c.inc and const-xs.inc
  # files to replace their "fallback" counterparts before distributing your
  # changes.
  my @names = (qw(ACCEPT_SESSION AGREED_MESS BUFFER_TOO_SHORT CAUSAL_MESS
		 CAUSED_BY_DISCONNECT CAUSED_BY_JOIN CAUSED_BY_LEAVE
		 CAUSED_BY_NETWORK CONNECTION_CLOSED COULD_NOT_CONNECT
		 DEFAULT_SPREAD_PORT DROP_RECV ENDIAN_RESERVED FIFO_MESS
		 GROUPS_TOO_SHORT HIGH_PRIORITY ILLEGAL_GROUP ILLEGAL_MESSAGE
		 ILLEGAL_SERVICE ILLEGAL_SESSION ILLEGAL_SPREAD LOW_PRIORITY
		 MAX_CLIENT_SCATTER_ELEMENTS MAX_GROUP_NAME MAX_PRIVATE_NAME
		 MAX_PROC_NAME MEDIUM_PRIORITY MEMBERSHIP_MESS MESSAGE_TOO_LONG
		 NET_ERROR_ON_SESSION REGULAR_MESS REG_MEMB_MESS REJECT_AUTH
		 REJECT_ILLEGAL_NAME REJECT_MESS REJECT_NOT_UNIQUE
		 REJECT_NO_NAME REJECT_QUOTA REJECT_VERSION RELIABLE_MESS
		 RESERVED SAFE_MESS SELF_DISCARD SPREAD_VERSION TRANSITION_MESS
		 UNRELIABLE_MESS));
  ExtUtils::Constant::WriteConstants(
                                     NAME         => 'Spread::Client::Constant',
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
