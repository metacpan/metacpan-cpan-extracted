#!perl
use strict;
use warnings;
use IO::Prompt;
use Test::More;
use Test::Exception;

my($aws_access_key_id, $secret_access_key);

eval {
  local $SIG{ALRM} = sub { die "alarm\n" };
  alarm 60;
  $aws_access_key_id = prompt("Please enter an AWS access key ID for testing: ");
  alarm 60;
  $secret_access_key = prompt("Please enter a secret access key for testing: ");
  alarm 0;
};

if ($aws_access_key_id && length $aws_access_key_id &&
	$secret_access_key && length $secret_access_key) {
  eval 'use Test::More tests => 2;';
} else {
  eval 'use Test::More; plan skip_all => "Need AWS access key ID and secret access key for testing, skipping"';
  exit;
}

use_ok("Net::Amazon::ATS");

my $awis = Net::Amazon::ATS->new($aws_access_key_id, $secret_access_key);
isa_ok($awis, "Net::Amazon::ATS", "Have an object back");

my $data = $awis->topsites();
use Data::Dumper;
print Dumper($data);
