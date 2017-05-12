

use strict;
use warnings;
use lib qw(../lib);
use Test::More tests =>145;
use Data::Dumper;
use Net::IP::RangeCompare qw(:ALL);
our $package_name='Net::IP::RangeCompare';

## helper functions ( everything depends on these )
{

	ok(int_to_ip(1) eq '0.0.0.1','int_to_ip check');

	ok(ip_to_int('0.0.0.1')==1,'ip_to_int check');


	ok(hostmask(0xff000000)==0x00ffffff,'host mask /8 check');
	ok(hostmask(0xffffffff)==0x00000000,'host mask /32 check');
	ok(hostmask(0)==0xffffffff,'host mask /0 check');

	ok('255.0.0.0' eq int_to_ip(cidr_to_int(8))
			,'cidr_to_int test /8 conversion');
	ok('255.255.255.255' eq int_to_ip(cidr_to_int(32))
			,'cidr_to_int test /32 conversion');
	ok('0.0.0.0' eq int_to_ip(cidr_to_int(0))
			,'cidr_to_int test /0 conversion');
}

# Constructor tests ( all oo stuff depends on this )
{
# normal constructor use
	my $obj=$package_name->new(0,0);
  ok(defined($obj),"Numbers should work in the constructor call");

  ## These tests should fail the constructor
  $obj=$package_name->new('x',0);
  ok(!defined($obj),"Start value should be a number");

  $obj=$package_name->new(0,'y');
  ok(!defined($obj),"end value should be a number");


  $obj=$package_name->new(1,0);
  ok(!defined($obj),"Start ip must be <= End ip");

  $obj=$package_name->new(0,0,1,0);
  ok($obj->generated,'generated should be true');
  ok(!$obj->missing,'missing should be false');
  $obj=$package_name->new(0,0,0,1);
  ok($obj->missing,'missing should be true');
  ok(!$obj->generated,'generated should be false');
}

## CMP checks
{
  my $obj_a=$package_name->new(0,1);
  my $obj_b=$package_name->new(1,1);
  my $obj_c=$package_name->new(1,1);
  my $obj_d=$package_name->new(2,2);
  my $obj_e=$package_name->new(1,2);
  ok($obj_b->cmp_first_int($obj_c)==0,'cmp_first_int 0');
  ok($obj_a->cmp_first_int($obj_b)==-1,'cmp_first_int -1');
  ok($obj_d->cmp_first_int($obj_a)==1,'cmp_first_int 1');

  ok($obj_a->cmp_last_int($obj_b)==0,'cmp_last_int 0');
  ok($obj_c->cmp_last_int($obj_d)==-1,'cmp_last_int -1');
  ok($obj_d->cmp_last_int($obj_a)==1,'cmp_last_int 1');

  ok($obj_a->contiguous_check($obj_d),'contiguous_check 1');
  ok(!$obj_a->contiguous_check($obj_b),'contiguous_check 1');

  ok($obj_b->cmp_ranges($obj_c)==0,'cmp_ranges same start and end check');
  ok($obj_a->cmp_ranges($obj_b)==-1,'cmp_ranges obj_a starts before obj_b');
  ok($obj_b->cmp_ranges($obj_a)==1,'cmp_ranges obj_b starts before obj_a');

  ok($obj_b->cmp_ranges($obj_e)==-1,'cmp_ranges obj_a ends before obj_b');
  ok($obj_e->cmp_ranges($obj_b)==1,'cmp_ranges obj_b ends before obj_a');

  
}
## Notation checks
{
  my $obj=$package_name->new(0,0);
  ok($obj->size==1,"0.0.0.0 - 0.0.0.0 is 1 ip");

  ok($obj->notation eq '0.0.0.0 - 0.0.0.0', "notation formatting check");
  
  ok(''.$obj eq '0.0.0.0 - 0.0.0.0',"Obj should stringify as an ip range");
}

## Misc parser checks ( makes life easy interface )
{

  # parser checks for a single ip
  my $r=$package_name->new_from_ip("10");
  ok($r eq '10.0.0.0 - 10.0.0.0',"parse ip check");
  $r=$package_name->new_from_ip(undef);
  ok(!$r," undef should retun undef");

  $r=$package_name->new_from_range("10 - 10");
  ok($r eq '10.0.0.0 - 10.0.0.0',"parse range notation check");
  $r=$package_name->new_from_range("10 - ");
  ok(!$r,"parse invalid range should fail");
  $r=$package_name->new_from_range('10.0.0.0 - 10.0.0.0');
  ok($r eq '10.0.0.0 - 10.0.0.0',"parse range notation check");

  $r=$package_name->new_from_cidr('10.0/255.255.255.0');
  ok($r,'parse a cidr in long hand');
  ok($r->first_ip eq '10.0.0.0','validate the first ip');
  ok($r->last_ip eq '10.0.0.255','validate the last ip');

  $r=$package_name->new_from_cidr('0/0');
  ok($r,'parse a cidr in short hand 0/0');
  ok($r->first_ip eq '0.0.0.0','validate the first ip 0/0');
  ok($r->last_ip eq '255.255.255.255','validate the last ip 0/0');

  $r=$package_name->new_from_cidr('10/32');
  ok($r,'parse a cidr in short hand 10/32');
  ok($r->first_ip eq '10.0.0.0','validate the first ip 10/32');
  ok($r->last_ip eq '10.0.0.0','validate the last ip 10/32');


}
## auto parse test ( makes life very easy )
{
  my $r=$package_name->parse_new_range('10');
  ok($r,"should parse 10");
  ok($r eq '10.0.0.0 - 10.0.0.0','validate 10 start and end');

  $r=$package_name->parse_new_range('10/32');
  ok($r,"should parse 10/32");
  ok($r eq '10.0.0.0 - 10.0.0.0','validate 10/32 start and end');

  $r=$package_name->parse_new_range('10/255');
  ok($r,"should parse 10/255");
  ok($r eq '10.0.0.0 - 10.255.255.255','validate 10/255 start and end');

  $r=$package_name->parse_new_range('10 - 255');
  ok($r,"should parse 10/255");
  ok($r eq '10.0.0.0 - 255.0.0.0','validate 10 - 255 start and end');


  $r=$package_name->parse_new_range($r);
  ok($r,"should pass the ref through without error");
  ok($r eq '10.0.0.0 - 255.0.0.0','validate ref 10 - 255 start and end');

  $r=$package_name->parse_new_range([]);
  ok(!$r,'should not parse an unblessed ref');

  $r=$package_name->parse_new_range(10,32);
  ok($r,"should handle the cidr list");
  ok($r eq '10.0.0.0 - 32.0.0.0','validate list (10,32) start and end');

}

## Size Checks
{
  my $obj=$package_name->new(0,1);
  ok($obj->size==2,"0.0.0.1 - 0.0.0.2 is 2 ips");
  $obj=$package_name->new(0,0xffffffff);
  ok($obj->size==(1 + 0xffffffff)
    ,"0.0.0.0 - 255.255.255.255  0/0 size");
  $obj=$package_name->new(0,0);
  ok($obj->size==1,"0.0.0.0 - 0.0.0.0 is 1 ip");
}


# sort testing
{

  my @list=map { $package_name->new(@{$_}[0,1]) } (
    [2,17]
    ,[0,7]
    ,[0,1]
    ,[2,17]
  );
  my @cmp=map { $package_name->new(@{$_}[0,1]) } (
    [0,7]
    ,[0,1]
    ,[2,17]
    ,[2,17]
  );
  ok(join(",",@cmp) eq join(",",sort sort_ranges @list),"Sort test -- consolidation order a");

  @list=map { $package_name->new(@{$_}[0,1]) } (
    [1,2]
    ,[5,6]
    ,[2,3]
  );
  @cmp=map { $package_name->new(@{$_}[0,1]) } (
    [1,2]
    ,[2,3]
    ,[5,6]
  );
  ok(join(",",@cmp) eq join(",",sort sort_ranges @list),"Sort test -- consolidation order b");

  @list=map { $package_name->new(@{$_}[0,1]) } (
    [1,2]
    ,[5,6]
    ,[2,3]
  );
  @cmp=map { $package_name->new(@{$_}[0,1]) } (
    [5,6]
    ,[2,3]
    ,[1,2]
  );
  ok(join(",",@cmp) eq join(",",sort sort_largest_last_int_first @list),"Sort test -- sort_largest_last_int_first");

  @cmp=map { $package_name->new(@{$_}[0,1]) } (
    [1,2]
    ,[2,3]
    ,[5,6]
  );
  ok(join(",",@cmp) eq join(",",sort sort_smallest_first_int_first @list),"Sort test -- sort_smallest_first_int_first");

  @cmp=map { $package_name->new(@{$_}[0,1]) } (
    [1,2]
    ,[2,3]
    ,[5,6]
  );
  ok(join(",",@cmp) eq join(",",sort sort_smallest_last_int_first @list),"Sort test -- sort_smallest_last_int_first");

  @cmp=map { $package_name->new(@{$_}[0,1]) } (
    [5,6]
    ,[2,3]
    ,[1,2]
  );
  ok(join(",",@cmp) eq join(",",sort sort_largest_first_int_first @list),"Sort test -- sort_largest_first_int_first");
}

# overlap checking
{
  my ($obj_a,$obj_b);


  ## postive checks
  $obj_a=$package_name->new(10,11);
  $obj_b=$package_name->new(10,11);
  ok($obj_a->overlap($obj_b),"overlap 10,11 -- duplicates");

  $obj_a=$package_name->new(10,11);
  $obj_b=$package_name->new(0,221);
  ok($obj_a->overlap($obj_b),"overlap 10 - 11, 0 - 221 -- one range contains the other");
  ok($obj_b->overlap($obj_a),"overlap  0 - 221, 10 - 11 -- one range contains the other");

  $obj_a=$package_name->new(10,11);
  $obj_b=$package_name->new(9,221);
  ok($obj_a->overlap($obj_b),"partial overlap 10 - 11, 9 - 221 -- one range contains the other");
  ok($obj_b->overlap($obj_a),"partial overlap  9 - 221, 10 - 11 -- one range contains the other");

  ## Negative Cheks
  $obj_a=$package_name->new(10,11);
  $obj_b=$package_name->new(12,221);
  ok(!$obj_a->overlap($obj_b),"no overlap 10 - 11, 12 - 221");
  ok(!$obj_b->overlap($obj_a),"no overlap  12 - 221,10 - 11");
}

# data function checks
{
  my $obj=$package_name->new(0,0);
  my $ref=$obj->data;
  ok(ref($ref),"data should be a ref");
  ok(ref($ref) eq 'HASH',"data should be a hash ref");
  ok($ref eq $obj->data,"data should be the same hash ref");
}

# get overlap testing 
{
  
  my $obj_a=$package_name->new(0,1);
  my $obj_b=$package_name->new(1,2);
  my $obj=get_overlapping_range([$obj_a,$obj_b]);
  ok($obj.'' eq '0.0.0.0 - 0.0.0.2',"get_overlapping_range test");
}

## BIG CHECK HERE consolidate_ranges!!
{
  my @list=map { $package_name->new(@{$_}[0,1]) } (
    [0,1]
    ,[0,1]
    ,[0,1]

    ,[2,3]

    ,[7,9]
    ,[9,11]
  );
  my @cmp=map { $package_name->new(@{$_}[0,1]) } (
    [0,1]
    ,[2,3]
    ,[7,11]
  );
  my $result=consolidate_ranges(\@list);
  #print join(', ',@{$result}),"\n";
  ok(join(', ',@$result) eq join(', ',@cmp),"range consolidation test 1");

  $result=consolidate_ranges([$package_name->new(0,1)]);
  ok($#{$result}==0,'should have just 1 range');
  $result=consolidate_ranges([
    $package_name->new(0,1)
    ,$package_name->new(2,3)
    ]
    );
  ok($#{$result}==1,'should have just 2 ranges');
}

## next and previous checks
{
  my $obj=$package_name->new(10,11);
  ok($obj->next_first_int==12,"get the next first integer");
  ok($obj->previous_last_int==9,"get the previous last interger");
}

# get missing ranges
{ 
  
  my @list=map { $package_name->new(@{$_}[0,1]) } (
    [0,1]
    ,[2,3]
    ,[7,11]
  );
  my @cmp=map { $package_name->new(@{$_}[0,1]) } (
    [0,1]
    ,[2,3]
    ,[4,6]
    ,[7,11]
  );
  my $result=fill_missing_ranges(\@list);
  #print join(', ',@$result),"\n";
  ok(join(', ',@$result) eq join(', ',@cmp),"find missing blocks");


  @list=map { $package_name->new(@{$_}[0,1]) } (
    [0,1]
    ,[2,3]
  );
  $result=fill_missing_ranges(\@list);
  ok(join(', ',@$result) eq '0.0.0.0 - 0.0.0.1, 0.0.0.2 - 0.0.0.3',"Test to make sure no invalid ranges are added");

}

# fill start and end of block sets
{
  my $ranges=[
    [
      map { $package_name->new(@{$_}[0,1]) }
        [0,1]
    ]

    ,[
      map { $package_name->new(@{$_}[0,1]) }
        [6,7]
    ]

    ,[
      map { $package_name->new(@{$_}[0,1]) }
        [8,10]
    ]
  ];
  my $test=range_start_end_fill($ranges);
  # each start range should be the followign
  my $id=-1;
  foreach(@$ranges) {
    ++$id;
    
    ok($_->[0]->first_int==0,
      'rangeid: '.$id.' first_int should be 0');
    ok($_->[$#{$_}]->last_int==10,
      'rangeid: '.$id.' last_int should be 10');
  }
  
}

## get common range
{
  my $obj_a=$package_name->new(3,5);
  my $obj_b=$package_name->new(4,6);
  ok('0.0.0.4 - 0.0.0.5' eq get_common_range([$obj_a,$obj_b])
    ,"validate the overlap between 3-5 and 4-6");
  $obj_a=$package_name->new(7,9);
  $obj_b=$package_name->new(4,6);
  ok(!get_common_range([$obj_a,$obj_b])
    ,"bogus overlaps should return undef");
}

## Compare_row
#### range_compare
{
  my $ranges=[
    [
      map { $package_name->new(@{$_}[0,1]) }
        [0,1]
        ,[2,5]
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
  my $range_copy=[];
  foreach (@$ranges) { push @$range_copy,[@$_] }

  my $obj;
  {
    my $ranges=[];
    while(my $range=shift @$range_copy) {
      push @$ranges,consolidate_ranges($range);
    }
    my ($row,$column_ids,$next)=compare_row($ranges,undef,undef);
    my $string=join(', ',@$row);
    #print $string,"\n";
    ok($string eq 
      '0.0.0.0 - 0.0.0.1, 0.0.0.0 - 0.0.0.1, 0.0.0.0 - 0.0.0.1'
      ,"compare_row test 1 row 1"
    );
    ok(0!=$next,'compare_row test 1 exit row');
    ($row,$column_ids,$next)=compare_row($ranges,$row,$column_ids);
    $string=join(', ',@$row);
    #print 'compare_row test 1 row 2 ',$string,"\n";
    ok($string eq 
     '0.0.0.2 - 0.0.0.5, 0.0.0.2 - 0.0.0.2, 0.0.0.2 - 0.0.0.2'
     ,"compare_row test 1 row 2"
    );
    ok(0!=$next,'compare_row test 2 exit row');
    ($row,$column_ids,$next)=compare_row($ranges,$row,$column_ids);
    $string=join(', ',@$row);
    ok($string eq 
      '0.0.0.2 - 0.0.0.5, 0.0.0.3 - 0.0.0.5, 0.0.0.3 - 0.0.0.3'
      ,"compare_row test 1 row 3"
    );
    ok(0!=$next,'compare_row test 3 exit row');

    ($row,$column_ids,$next)=compare_row($ranges,$row,$column_ids);
    $string=join(', ',@$row);
    ok($string eq 
      '0.0.0.2 - 0.0.0.5, 0.0.0.3 - 0.0.0.5, 0.0.0.4 - 0.0.0.5'
      ,"compare_row test 1 row 4");
    ok(0==$next,'compare_row test 4 exit row');

    # just 1 row and 1 colum check
    $obj=$package_name->new(0,1);
    ($row,$column_ids,$next)=compare_row([[$obj]],undef,undef);
    $string=join(', ',@$row);
    ok($string eq '0.0.0.0 - 0.0.0.1','compare_row test 2 row 1');
    
    ok(0==$next,'compare_row test 6 exit row');


  }
  
  $obj=range_compare($ranges);
  my $row=join(', ',$obj->());
  ok($row  eq '0.0.0.0 - 0.0.0.1, 0.0.0.0 - 0.0.0.1, 0.0.0.0 - 0.0.0.1, 0.0.0.0 - 0.0.0.1',"range cmp test 1 row 1");

  $row=join(', ',$obj->());
  ok($row eq '0.0.0.2 - 0.0.0.2, 0.0.0.2 - 0.0.0.5, 0.0.0.2 - 0.0.0.2, 0.0.0.2 - 0.0.0.2',"range cmp test 1 row 2");

  $row=join(', ',$obj->());
  ok($row eq '0.0.0.3 - 0.0.0.3, 0.0.0.2 - 0.0.0.5, 0.0.0.3 - 0.0.0.5, 0.0.0.3 - 0.0.0.3',"range cmp test 1 row 3");

  $row=join(', ',$obj->());
  ok($row eq '0.0.0.4 - 0.0.0.5, 0.0.0.2 - 0.0.0.5, 0.0.0.3 - 0.0.0.5, 0.0.0.4 - 0.0.0.5',"range cmp test 1 row 4");

  ok(!$obj->(),"false check for the end of the data set");


  # just 1 row and 1 colum check
  $obj=range_compare([[$package_name->new(0,1)]]);
  ok(join(', ',$obj->()) eq '0.0.0.0 - 0.0.0.1, 0.0.0.0 - 0.0.0.1',
  'range cmp tesst 2 row 1');
  ok(!$obj->(),"false check for the end of the data set");

  ## This test should skip rows that no range contains
  ## in this case 2-3
  $ranges=[
    [
      map { $package_name->new(@{$_}[0,1]) }
        [0,1]
        ,[4,5]
    ]

    ,[
      map { $package_name->new(@{$_}[0,1]) }
        [0,1]
        ,[4,5]
    ]

    ,[
      map { $package_name->new(@{$_}[0,1]) }
        [0,1]
        ,[4,5]
    ]
  ];
  $obj=range_compare($ranges);
  $row=join(', ',$obj->());
  ok($row eq '0.0.0.0 - 0.0.0.1, 0.0.0.0 - 0.0.0.1, 0.0.0.0 - 0.0.0.1, 0.0.0.0 - 0.0.0.1',"should just be 0-1");

  $row=join(', ',$obj->());
  ok($row eq '0.0.0.4 - 0.0.0.5, 0.0.0.4 - 0.0.0.5, 0.0.0.4 - 0.0.0.5, 0.0.0.4 - 0.0.0.5',"should just be 4-5");
  ok(!$obj->(),"false check for the end of the data set");
  


}

## get first cidr checks
{
  my $ok=0;
  eval {
    
    my $obj=$package_name->new(0,3);
    my ($range,$cidr,$next)=$obj->get_first_cidr;
    ok(!defined($next),'should not have next when we have a cidr');
    $obj=$package_name->new(0,4);
    my @set=$obj->get_first_cidr;
    my $row=join(', ',@set);
    ok($row eq 
      '0.0.0.0 - 0.0.0.3, 0.0.0.0/30, 0.0.0.4 - 0.0.0.4',
      'get next cidr start test');
    $ok++;
    @set=$set[2]->get_first_cidr;
    $row=join(', ',@set);
    ok($row eq '0.0.0.4 - 0.0.0.4, 0.0.0.4/32',
      'get next cidr end test');
    $ok++;
  };
  ok(!$@,'eval of get_first_cidr should not have failed');
  SKIP: {
    skip 'eval failed',(2 -$ok) unless !$@;
  }
}

## is_cidr and is_range checks
{
  my $obj=$package_name->new(0,4);
  #print join(', ',$obj->get_first_cidr),"\n";
  ok(!$obj->is_cidr,'is_cidr false check');
  ok($obj->is_range,'is_range true check');
}

## Get cidr notation lis ref;
{

  my $obj=$package_name->new(0,4);
  ok($obj->get_cidr_notation eq '0.0.0.0/30, 0.0.0.4/32',
    "cidr notation check 1");
  $obj=$package_name->new(0,3);
  ok($obj->get_cidr_notation eq '0.0.0.0/30',
    "cidr notation check 2");
}



{
  my $r=$package_name->new(0,1);
  my $e=$r->enumerate;
  ok($e->() eq '0.0.0.0 - 0.0.0.0',' enumerate test 1 set 1');
  ok($e->() eq '0.0.0.1 - 0.0.0.1',' enumerate test 1 set 2');
  ok(!$e->(),' enumerate test 1 end check');

  $r=$package_name->new(0,7);
  $e=$r->enumerate(30);
  ok($e->() eq '0.0.0.0 - 0.0.0.3',' enumerate test 2 set 1');
  ok($e->() eq '0.0.0.4 - 0.0.0.7',' enumerate test 2 set 2');
  ok(!$e->(),' enumerate test 2 end check');

  $r=$package_name->new(2,6);
  $e=$r->enumerate(30);
  ok($e->() eq '0.0.0.2 - 0.0.0.3',' enumerate test 3 set 1');
  ok($e->() eq '0.0.0.4 - 0.0.0.6',' enumerate test 3 set 2');
  ok(!$e->(),' enumerate test 3 end check');
}
## Simple tests;
{
  my $obj=Net::IP::RangeCompare::Simple->new;
  ok($obj,"Should have a new object");
  ok(!$obj->get_ranges_by_key('a'),'get key should return undef');

  ok($obj->add_range('Tom','10.0.0.2 - 10.0.0.11'),"Tom Test 1");
  ok($obj->add_range('Tom','10.0.0.32 - 10.0.0.66'),"Tom Test 2");
  ok($obj->add_range('Tom','11/32'),"Tom Test 3");
  my $ref=$obj->get_ranges_by_key('Tom');
  ok($ref,"We should get true back from Tom's list");
  ok(ref($ref) eq 'ARRAY','Toms list hould be an array ref');
  ok(join(', ',@$ref) eq 
    '10.0.0.2 - 10.0.0.11, 10.0.0.32 - 10.0.0.66, 11.0.0.0 - 11.0.0.0'
    ,"Check all of Tom's ranges"
  );

  ok(
    $obj->add_range('Sally','10.0.0.7 - 10.0.0.12')
    ,'Sally test 1'
  );
        ok(
    $obj->add_range('Sally','172.16/255.255.255')
    ,'Sally test 2'
  );

  ok(
          $obj->add_range('Harry','192.168.2')
    ,"Harry test 1"
  );
  ok(
          $obj->add_range('Harry','10.0.0.128/30')
    ,'Harry test 2'
  );

  my $total=0;
  while(my ($common,%row)=$obj->get_row) {
    $total++ if $row{Tom};
    $total++ if $row{Sally};
    $total++ if $row{Harry};
    #print $common,"\n";
    #print join(', ',@row{qw(Tom Sally Harry)}),"\n";
  }
  ok($total==24,'get_row check');

  $total=0;
  $obj->compare_ranges('Tom');
  while(my ($common,%row)=$obj->get_row) {
    $total++ if $row{Tom};
    $total++ if $row{Sally};
    $total++ if $row{Harry};
  }
  ok($total==8,'get_row check with "Tom" Removed');
}
###########################
# End of the unit script
__END__
