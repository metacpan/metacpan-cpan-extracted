use lib 'lib';
use lib '../lib';
use 5.006;
use strict;
use warnings;
use Test::More tests => 20;
use Perlmazing qw(windows_path unix_path);

my $tests = {
  '/usr/bin/perl' => {
    unix => '/usr/bin/perl',
    windows => '\usr\bin\perl',
  },
  '\\\\ws1\d$\Users\fzarabozo\file.txt' => {
    unix => '//ws1/d$/Users/fzarabozo/file.txt',
    windows => '\\\\ws1\d$\Users\fzarabozo\file.txt',
  },
  '\\\\ws1\d$\Users\fzarabozo\folder' => {
    unix => '//ws1/d$/Users/fzarabozo/folder',
    windows => '\\\\ws1\d$\Users\fzarabozo\folder',
  },
  '\\\\ws1\d$\Users\fzarabozo\folder\\' => {
    unix => '//ws1/d$/Users/fzarabozo/folder',
    windows => '\\\\ws1\d$\Users\fzarabozo\folder',
  },
  '\\\\ws1\folder' => {
    unix => '//ws1/folder',
    windows => '\\\\ws1\folder',
  },
  '\\\\ws3' => {
    unix => '//ws3',
    windows => '\\\\ws3',
  },
  '\\\\ws3\\' => {
    unix => '//ws3',
    windows => '\\\\ws3',
  },
  'C:/Program files/Microsoft/file.txt' => {
    unix => 'C:/Program files/Microsoft/file.txt',
    windows => 'C:\Program files\Microsoft\file.txt',
  },
  'C:\Program files\Microsoft' => {
    unix => 'C:/Program files/Microsoft',
    windows => 'C:\Program files\Microsoft',
  },
  'C:\Program files\Microsoft\file.txt' => {
    unix => 'C:/Program files/Microsoft/file.txt',
    windows => 'C:\Program files\Microsoft\file.txt',
  },
};

for my $path (sort keys %$tests) {
  my $unix = unix_path $path;
  my $windows = windows_path $path;
  is $unix, $tests->{$path}->{unix}, "unix_path returns $tests->{$path}->{unix}";
  is $windows, $tests->{$path}->{windows}, "windows_path returns $tests->{$path}->{windows}";
}
