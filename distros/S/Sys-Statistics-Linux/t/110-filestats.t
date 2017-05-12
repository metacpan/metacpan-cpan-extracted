use strict;
use warnings;
use Test::More;
use Sys::Statistics::Linux;

if (!-r '/proc/sys/fs/file-nr' || !-r '/proc/sys/fs/inode-nr' || !-r '/proc/sys/fs/dentry-state') {
    plan skip_all => "it seems that your system doesn't provide file statistics";
    exit(0);
}

plan tests => 10;

my @filestats = qw(
   fhalloc
   fhfree
   fhmax
   inalloc
   infree
   inmax
   dentries
   unused
   agelimit
   wantpages
);

my $sys = Sys::Statistics::Linux->new();
$sys->set(filestats => 1);
my $stats = $sys->get;
ok(defined $stats->filestats->{$_}, "checking filestats $_") for @filestats;
