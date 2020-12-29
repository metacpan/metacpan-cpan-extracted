use strict;
use warnings;

use Test::More;

use Sys::Linux::KernelVersion;

my @version_lines = (
  'Linux version 5.9.0-2-amd64 (debian-kernel@lists.debian.org) (gcc-10 (Debian 10.2.0-16) 10.2.0, GNU ld (GNU Binutils for Debian) 2.35.1) #1 SMP Debian 5.9.6-1 (2020-11-08)',
  'Linux version 5.4.0-48-generic (buildd@lcy01-amd64-010) (gcc version 9.3.0 (Ubuntu 9.3.0-10ubuntu2)) #52-Ubuntu SMP Thu Sep 10 10:58:49 UTC 2020',
  'Linux version 5.4.0-58-generic (buildd@lcy01-amd64-004) (gcc version 9.3.0 (Ubuntu 9.3.0-17ubuntu1~20.04)) #64-Ubuntu SMP Wed Dec 9 08:16:25 UTC 2020',
  'Linux version 5.10.3 (root@magellan) (gcc (Debian 10.2.1-3) 10.2.1 20201224, GNU ld (GNU Binutils for Debian) 2.35.1) #1 SMP Mon Dec 28 19:32:58 PST 2020'
);

# These probably aren't real versions, but follow the patterns as specified
my @development_versions = qw/2.5.18 2.3.12 2.3.0 2.1.99 1.9.85 1.9.2 1.9.0 1.1.1 5.10.0-rc2 3.2.0-rc9/;
my @release_versions = qw/2.6.28 3.11.0 5.10.3 5.6.0 5.5.99 2.2.18 1.0.0 4.1.1/;

for my $line (@version_lines) {
  my $parsed = Sys::Linux::KernelVersion::_parse_version_line($line);
  ok(defined $parsed, "Parsed line $line");
}

for my $dev_ver (@development_versions) {
  my $parsed = Sys::Linux::KernelVersion::_parse_version_spec($dev_ver);

  ok(defined $parsed, "Parsed line $dev_ver");
  is(Sys::Linux::KernelVersion::_is_development($parsed)+0, 1, "Identify $dev_ver as development");
}

for my $rel_ver (@release_versions) {
  my $parsed = Sys::Linux::KernelVersion::_parse_version_spec($rel_ver);

  ok(defined $parsed, "Parsed line $rel_ver");
  is(Sys::Linux::KernelVersion::_is_development($parsed)+0, 0, "Identify $rel_ver as release");
}

done_testing;
