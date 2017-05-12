use 5.006000;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Net::LDAPxs',
    VERSION_FROM      => 'lib/Net/LDAPxs.pm',
    PREREQ_PM         => {},
    ($] >= 5.006 ?
      (ABSTRACT  => 'XS version of Net::LDAP',
    AUTHOR            => 'Pan Yu <xiaocong[at]vip.163.com>') : ()),
	LICENSE		      => 'Perl',
    LIBS              => ['-lldap -llber'],
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
);
if  (eval {require ExtUtils::Constant; 1}) {

  my @names = (qw(TESTVAL));
  ExtUtils::Constant::WriteConstants(
                                     NAME         => 'Net::LDAPxs',
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


