# Makefile.PL
#
# Makefile for Net::SLP
# Author Mike McCauley (mikem@airspayce.com)
# Copyright (C) Mike McCauley
# $Id: Makefile.PL,v 1.2 2004/11/01 06:24:49 mikem Exp $
use 5.00503;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Net::SLP',
    VERSION_FROM      => 'lib/Net/SLP.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Net/SLP.pm', # retrieve abstract from module
       AUTHOR         => 'Mike McCauley <mikem@airspayce.com>') : ()),
    LIBS              => ['-lslp '], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
	      dist           => {
		  COMPRESS => 'gzip -f',
	      },
);
if  (eval {require ExtUtils::Constant; 1}) {
  # If you edit these definitions to change the constants used by this module,
  # you will need to use the generated const-c.inc and const-xs.inc
  # files to replace their "fallback" counterparts before distributing your
  # changes.
  my @names = (qw(SLP_AUTHENTICATION_ABSENT SLP_AUTHENTICATION_FAILED
		 SLP_BUFFER_OVERFLOW SLP_FALSE SLP_HANDLE_IN_USE
		 SLP_INTERNAL_SYSTEM_ERROR SLP_INVALID_REGISTRATION
		 SLP_INVALID_UPDATE SLP_LANGUAGE_NOT_SUPPORTED SLP_LAST_CALL
		 SLP_LIFETIME_DEFAULT SLP_LIFETIME_MAXIMUM
		 SLP_MEMORY_ALLOC_FAILED SLP_NETWORK_ERROR
		 SLP_NETWORK_INIT_FAILED SLP_NETWORK_TIMED_OUT
		 SLP_NOT_IMPLEMENTED SLP_OK SLP_PARAMETER_BAD SLP_PARSE_ERROR
		 SLP_REFRESH_REJECTED SLP_SCOPE_NOT_SUPPORTED SLP_TRUE
		 SLP_TYPE_ERROR));
  ExtUtils::Constant::WriteConstants(
                                     NAME         => 'Net::SLP',
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
