use strict;
use warnings;
use Sort::filevercmp 'filevercmp', 'fileversort';
use Test::More;

# Sorted examples from gnulib filevercmp tests
my @sorted = (
  "",
  ".",
  "..",
  ".0",
  ".9",
  ".A",
  ".Z",
  ".a~",
  ".a",
  ".b~",
  ".b",
  ".z",
  ".zz~",
  ".zz",
  ".zz.~1~",
  ".zz.0",
  "0",
  "9",
  "A",
  "Z",
  "a~",
  "a",
  "a.b~",
  "a.b",
  "a.bc~",
  "a.bc",
  "b~",
  "b",
  "gcc-c++-10.fc9.tar.gz",
  "gcc-c++-10.fc9.tar.gz.~1~",
  "gcc-c++-10.fc9.tar.gz.~2~",
  "gcc-c++-10.8.12-0.7rc2.fc9.tar.bz2",
  "gcc-c++-10.8.12-0.7rc2.fc9.tar.bz2.~1~",
  "glibc-2-0.1.beta1.fc10.rpm",
  "glibc-common-5-0.2.beta2.fc9.ebuild",
  "glibc-common-5-0.2b.deb",
  "glibc-common-11b.ebuild",
  "glibc-common-11-0.6rc2.ebuild",
  "libstdc++-0.5.8.11-0.7rc2.fc10.tar.gz",
  "libstdc++-4a.fc8.tar.gz",
  "libstdc++-4.10.4.20040204svn.rpm",
  "libstdc++-devel-3.fc8.ebuild",
  "libstdc++-devel-3a.fc9.tar.gz",
  "libstdc++-devel-8.fc8.deb",
  "libstdc++-devel-8.6.2-0.4b.fc8",
  "nss_ldap-1-0.2b.fc9.tar.bz2",
  "nss_ldap-1-0.6rc2.fc8.tar.gz",
  "nss_ldap-1.0-0.1a.tar.gz",
  "nss_ldap-10beta1.fc8.tar.gz",
  "nss_ldap-10.11.8.6.20040204cvs.fc10.ebuild",
  "z",
  "zz~",
  "zz",
  "zz.~1~",
  "zz.0",
  "#.b#",
);

foreach my $i (1..$#sorted) {
  is filevercmp($sorted[$i-1], $sorted[$i]), -1, "'$sorted[$i]' sorts after '$sorted[$i-1]'";
}

is_deeply [fileversort reverse @sorted], \@sorted, 'version sorted list correct';

done_testing;
