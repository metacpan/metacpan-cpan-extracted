#!/usr/bin/perl 
use strict;
use warnings;

use Net::Amazon::S3;
use Net::Amazon::S3::ACL;

my ($id, $secret, $bucketname, $key) = @ARGV;
die "getacl.pl <id> <secret> <bucket> <key>\n"
   unless defined $key;

my $s3 = Net::Amazon::S3->new(
   {
      aws_access_key_id     => $id,
      aws_secret_access_key => $secret,
      retry                 => 1,
   }
);

my $bucket = $s3->bucket($bucketname);
my $acl_xml = $bucket->get_acl($key);

my $acl = Net::Amazon::S3::ACL->new({xml => $acl_xml});
print $acl->dump();
