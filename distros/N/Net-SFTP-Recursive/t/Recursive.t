# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use strict;
use warnings;

use Test::More qw(no_plan); 

use Net::SFTP::Recursive qw(:all);
my $class = 'Net::SFTP::Recursive';
my $obj = bless {}, $class;

isa_ok($obj, $class);

my @md = (@Net::SFTP::Recursive::EXPORT_OK, 
          @Net::SFTP::Recursive::IMPORT_OK);
foreach my $m (@md) {
    ok($obj->can($m), "$class->can('$m')");
}

exit;

1;

