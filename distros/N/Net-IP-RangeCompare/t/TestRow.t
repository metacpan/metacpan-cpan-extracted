
use strict;
use warnings;
use Test::More tests =>59;
use Data::Dumper;
use lib qw(../lib);
use Net::IP::RangeCompare qw(:ALL);
our $p='Net::IP::RangeCompare';

## Simple tests;
{
  my $list_a=[];
  my $list_b=[];
  my $list_c=[];

  push @$list_a,$p->parse_new_range('10.0.0.2 - 10.0.0.11');
  push @$list_b,$p->parse_new_range('10.0.0.7 - 10.0.0.12');

  push @$list_a,$p->parse_new_range('10.0.0.32 - 10.0.0.66');
  push @$list_c,$p->parse_new_range('10.0.0.128/30');

  push @$list_a,$p->parse_new_range('11/32');

  push @$list_b,$p->parse_new_range('172.16/255.255.255');

  push @$list_c,$p->parse_new_range('192.168.2');

  my $data=[];
  foreach($list_a,$list_b,$list_c) {
    push @$data,consolidate_ranges($_);
  }

## Compare_row Tests
  my ($row,$cols,$next);
  ($row,$cols,$next)=compare_row($data,$row,$cols);
  ok($row->[0] eq '10.0.0.2 - 10.0.0.11','compare_row 0 col 0');
  ok(!$row->[0]->missing,'compare_row 0,0 should not be missing');
  ok($row->[2] eq '10.0.0.2 - 10.0.0.127','compare_row 0 col 2');
  ok($row->[2]->missing,'compare_row 0,2 should be missing');
  ok($next,'next should be true');

  ($row,$cols,$next)=compare_row($data,$row,$cols);
  ok($row->[0] eq '10.0.0.2 - 10.0.0.11','compare_row 1 col 0');
  ok(!$row->[0]->missing,'compare_row row 1,0 should be missing');
  ok($row->[1] eq '10.0.0.7 - 10.0.0.12','compare_row 1 col 1');
  ok(!$row->[1]->missing,'compare_row row 1,1 should not be missing');
  ok($row->[2] eq '10.0.0.2 - 10.0.0.127','compare_row 1 col 2');
  ok($row->[2]->missing,'compare_row row 1,2 should be missing');
  ok($next,'next should be true');

  ($row,$cols,$next)=compare_row($data,$row,$cols);
  ok($row->[0] eq '10.0.0.12 - 10.0.0.31','compare_row 2 col 0');
  ok($row->[0]->missing,'compare_row row 2,0 should be missing');
  ok($row->[1] eq '10.0.0.7 - 10.0.0.12','compare_row 2 col 1');
  ok(!$row->[1]->missing,'compare_row row 2,1 should not be missing');
  ok($row->[2] eq '10.0.0.2 - 10.0.0.127','compare_row 2 col 2');
  ok($row->[2]->missing,'compare_row row 2,2 should be missing');
  ok($next,'next should be true');

  ($row,$cols,$next)=compare_row($data,$row,$cols);
  ok($row->[0] eq '10.0.0.32 - 10.0.0.66','compare_row 3 col 0');
  ok(!$row->[0]->missing,'compare_row row 3,0 should not be missing');
  ok($row->[1] eq '10.0.0.13 - 172.15.255.255','compare_row 3 col 1');
  ok($row->[1]->missing,'compare_row row 3,1 should be missing');
  ok($row->[2] eq '10.0.0.2 - 10.0.0.127','compare_row 3 col 2');
  ok($row->[2]->missing,'compare_row row 3,2 should be missing');
  ok($next,'next should be true');

  ($row,$cols,$next)=compare_row($data,$row,$cols);
  ok($row->[0] eq '10.0.0.67 - 10.255.255.255','compare_row 4 col 0');
  ok($row->[0]->missing,'compare_row row 4,0 should be missing');
  ok($row->[1] eq '10.0.0.13 - 172.15.255.255','compare_row 4 col 1');
  ok($row->[1]->missing,'compare_row row 4,1 should be missing');
  ok($row->[2] eq '10.0.0.128 - 10.0.0.131','compare_row 4 col 2');
  ok(!$row->[2]->missing,'compare_row row 4,2 should not be missing');
  ok($next,'next should be true');

  ($row,$cols,$next)=compare_row($data,$row,$cols);
  ok($row->[0] eq '11.0.0.0 - 11.0.0.0','compare_row 5 col 0');
  ok(!$row->[0]->missing,'compare_row row 5,0 should not be missing');
  ok($row->[1] eq '10.0.0.13 - 172.15.255.255','compare_row 5 col 1');
  ok($row->[1]->missing,'compare_row row 5,1 should not be missing');
  ok($row->[2] eq '10.0.0.132 - 192.168.1.255','compare_row 5 col 2');
  ok($row->[2]->missing,'compare_row row 5,2 should be missing');
  ok($next,'next should be true');

  ($row,$cols,$next)=compare_row($data,$row,$cols);
  ok($row->[0] eq '11.0.0.1 - 192.168.2.0','compare_row 6 col 0');
  ok($row->[0]->missing,'compare_row row 6,0 should not be missing');
  ok($row->[1] eq '172.16.0.0 - 172.16.0.255','compare_row 6 col 1');
  ok(!$row->[1]->missing,'compare_row row 6,1 should be missing');
  ok($row->[2] eq '10.0.0.132 - 192.168.1.255','compare_row 6 col 2');
  ok($row->[2]->missing,'compare_row row 6,2 should be missing');
  ok($next,'6 next should be true');

  ($row,$cols,$next)=compare_row($data,$row,$cols);
  ok($row->[0] eq '11.0.0.1 - 192.168.2.0','compare_row 7 col 0');
  ok($row->[0]->missing,'compare_row row 7,0 should be missing');
  ok($row->[1] eq '172.16.1.0 - 192.168.2.0','compare_row 7 col 1');
  ok($row->[1]->missing,'compare_row row 7,1 should not be missing');
  ok($row->[2] eq '192.168.2.0 - 192.168.2.0','compare_row 7 col 2');
  ok(!$row->[2]->missing,'compare_row row 7,2 should not be missing');
  ok(!$next,'7 next should be false');
}
{
  my $ranges=[
    [
      map { $p->new(@{$_}[0,1]) }
        [3,8]
    ]

    ,[
      map { $p->new(@{$_}[0,1]) }
        [0,1]
        ,[4,5]
    ]

    ,[
      map { $p->new(@{$_}[0,1]) }
        [0,1]
        ,[3,3]
        ,[4,5]
    ]
  ];

   my ($row,$cols,$next,$common);
   ($row,$cols,$next)=compare_row($ranges,$row,$cols);
   $common=get_common_range($row);
   #print $common,"\n";
   ok($common eq '0.0.0.0 - 0.0.0.1','compare_row set 2 row 1');

   ($row,$cols,$next)=compare_row($ranges,$row,$cols);
   $common=get_common_range($row);
   #print $common,"\n";
   ok($common eq '0.0.0.3 - 0.0.0.3','compare_row set 2 row 2');

   ($row,$cols,$next)=compare_row($ranges,$row,$cols);
   $common=get_common_range($row);
   #print $common,"\n";
   #print Dumper($row);
   ok($common eq '0.0.0.4 - 0.0.0.5','compare_row set 2 row 2');
   ok($next,'should say we have something next');
   #print Dumper($cols);
   ($row,$cols,$next)=compare_row($ranges,$row,$cols);
   $common=get_common_range($row);
   #print $common,"\n";
   ok(!$next,'should not have anything next');

}
###########################
# End of the unit script
__END__
