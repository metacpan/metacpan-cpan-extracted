

use strict;
use warnings;
use lib qw(../lib);
use Test::More tests =>1;
use Data::Dumper;
use Net::IP::RangeCompare qw(:ALL);
our $package_name='Net::IP::RangeCompare';

#### range_compare_force_cidr
{
  my $ranges=[
    [
      map { $package_name->new(@{$_}[0,1]) }
        [0,8]
    ]

    ,[
      map { $package_name->new(@{$_}[0,1]) }
        [0,1]
        ,[3,4]
        ,[4,5]
    ]

    ,[
      map { $package_name->new(@{$_}[0,1]) }
        [0,1]
        ,[3,3]
        ,[4,5]
    ]
  ];
  my $sub=range_compare_force_cidr($ranges);
  my $max=9;
  my $count=0;
  while(my ($common,$cidr,@cols)=$sub->()) {
  	#print '  ',$common,', ',$cidr,"\n";
	#print '  ',join(', ',@cols),"\n\n";
	last if --$max<=0;
	++$count;
  }
  ok($count==6,'should get 6 cidrs');

}

