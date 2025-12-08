#!/usr/bin/perl

use strict;
use warnings;
use Schedule::Activity::Attribute;
use Test::More tests=>9;

subtest 'init'=>sub {
	plan tests=>13;
	my $attr;
	my $m='Schedule::Activity::Attribute';
	#
	$attr=$m->new();
	is($$attr{type}, 'int','Default:  type');
	is($$attr{value},    0,'Default:  value');
	is($attr->value(),   0,'Default:  ->value');
	#
	$attr=$m->new(value=>5);
	is($$attr{type}, 'int','Value init:  type');
	is($$attr{value},    5,'Value init:  value');
	is($attr->value(),   5,'Value init:  ->value');
	is($$attr{avg},      5,'Value init:  average');
	is($$attr{tmsum},    0,'Value init:  tmsum/weight');
	#
	$attr=$m->new(type=>'bool');
	is($$attr{type},'bool','Boolean:  type');
	is($$attr{value},    0,'Boolean:  value');
	is($attr->value(),  '','Boolean:  ->value');
	is($$attr{avg},      0,'Boolean:  average');
	is($$attr{tmsum},    0,'Boolean:  tmsum/weight');
};

subtest 'Validation of options'=>sub {
	plan tests=>5;
	#
	my $attr=Schedule::Activity::Attribute->new(type=>'int',value=>7);
	ok(!defined($attr->validateConfig(set=>1,incr=>2,decr=>3,tm=>5,note=>'note',value=>3)),'int:  set/incr/decr/tm/note/value');
	is($attr->value(),7,'Int:  update options');
	#
	$attr=Schedule::Activity::Attribute->new(type=>'bool',value=>0);
	ok(!defined($attr->validateConfig(set=>1,tm=>5,note=>'note',value=>1)),'bool:  set/tm/note/value');
	is($attr->value(),'','Bool:  update options');
	#
	eval { $attr=Schedule::Activity::Attribute->new(type=>'real') };
	like($@,qr/invalid type/,'Invalid type');
};

subtest 'change()'=>sub {
	plan tests=>11;
	my $attr=Schedule::Activity::Attribute->new(type=>'int',value=>0);
	is($attr->value(),0,'int init 0');
	$attr->change(set=>5);  is($attr->value(),5,'int set 5');
	$attr->change(incr=>2); is($attr->value(),7,'int incr 2');
	$attr->change(decr=>3); is($attr->value(),4,'int decr 3');
	is_deeply($$attr{log},{0=>4},'int log');
	is_deeply($$attr{aog},{0=>4},'int avg log');
	#
	$attr=Schedule::Activity::Attribute->new(type=>'bool',value=>0);
	ok(!$attr->value(),'bool init 0');
	$attr->change(set=>1); ok( $attr->value(),'bool set 1');
	$attr->change(set=>0); ok(!$attr->value(),'bool set 0');
	is_deeply($$attr{log},{0=>0},'bool log');
	is_deeply($$attr{aog},{0=>0},'bool avg log');
};

subtest 'Log values'=>sub {
	plan tests=>9;
	my $attr;
	$attr=Schedule::Activity::Attribute->new(type=>'int');
	is_deeply($$attr{log},{0=>0},'int:  log at 0');
	$attr->change(set=>10,tm=>3);
	is($attr->value(),10,'int:  value at 3');
	is_deeply($$attr{log},{0=>0,3=>10},'int:  log at 3');
	$attr->change(set=>20,tm=>6);
	is_deeply($$attr{log},{0=>0,3=>10,6=>20},'int:  log at 6');
	is($attr->value(),20,'int:  value from maximum time');
	#
	$attr=Schedule::Activity::Attribute->new(type=>'int',value=>5);
	$attr->change(set=>30,tm=>6);
	$attr->change(set=>15,tm=>3);
	$attr->change(set=> 0,tm=>0);
	is($attr->value(),30,'int:  historic event does not affect value');
	is_deeply($$attr{log},{0=>5,6=>30},'int:  historic event is not logged');
	#
	$attr=Schedule::Activity::Attribute->new(type=>'bool',value=>1);
	$attr->change(set=> 1,tm=>6);
	$attr->change(set=> 0,tm=>3);
	$attr->change(set=> 1,tm=>0);
	is($attr->value(),1,'bool:  historic event does not affect value');
	is_deeply($$attr{log},{0=>1,6=>1},'bool:  historic event is not logged');
};

# t  x
# 0  0
# 1  12
# 3  22
# 7  0
subtest 'Log averages:  Integer'=>sub {
	plan tests=>16;
	my $attr=Schedule::Activity::Attribute->new(type=>'int',value=>33,tm=>0);
	is($$attr{avg},33,            'Initial avg');
	is_deeply($$attr{aog},{0=>33},'Initial avg log');
	$attr->change(set=>0,tm=>0);
	is($$attr{avg},0,            'Overwrite initial avg');
	is_deeply($$attr{aog},{0=>0},'Overwrite initial avg log');
	$attr->change(set=>12,tm=>1);
	is($$attr{avg},6,'Method:  Trapezoidal');
	$attr->change(set=>22,tm=>3);
	$attr->change(set=> 0,tm=>7);
	$attr->change(set=> 0,tm=>2); # this should be a noop, guarantees that historical logging is not supported
	is($attr->average(),(1*6+2*17+4*11)/7,'Weighted average');
	is_deeply($$attr{log},{0=>0,1=>12,3=>22,7=>0},'Log');
	is_deeply($$attr{aog},{0=>0,1=>6,3=>40/3,7=>12},'Avg log');
	$attr->change(set=>14,tm=>7);
	is($attr->average(),(1*6+2*17+4*18)/7,          'Overwrite avg');
	is_deeply($$attr{log},{0=>0,1=>12,3=>22,7=>14}, 'Overwrite log');
	is_deeply($$attr{aog},{0=>0,1=>6,3=>40/3,7=>16},'Overwrite avg log');
	$attr->change(incr=>-14,tm=>7);
	is($attr->average(),(1*6+2*17+4*11)/7,          'Incr overwrite avg');
	is_deeply($$attr{log},{0=>0,1=>12,3=>22,7=>0},  'Incr overwrite log');
	is_deeply($$attr{aog},{0=>0,1=>6,3=>40/3,7=>12},'Incr overwrite avg log');
	#
	for(my $tm=8;$tm<84;$tm+=4) { $attr->change(tm=>$tm,_log=>1) }
	ok($attr->average()>1,'Long term average still above 1');
	$attr->change(tm=>84,_log=>1);
	ok($attr->average()<=1,'Long term average reaches 1');
};

# t  x
# 0  0
# 2  1
# 4  0
# 6  1
# 8  0
subtest 'Log averages:  Boolean'=>sub {
	plan tests=>13;
	my $attr=Schedule::Activity::Attribute->new(type=>'bool',value=>1,tm=>0);
	is($$attr{avg},1,            'Initial avg');
	is_deeply($$attr{aog},{0=>1},'Initial avg log');
	$attr->change(set=>0,tm=>0);
	is($$attr{avg},0,            'Overwrite avg');
	is_deeply($$attr{aog},{0=>0},'Overwrite avg log');
	$attr->change(set=>1,tm=>2);
	is($$attr{avg},0,'Method:  Percent active');
	$attr->change(set=>0,tm=>4);
	$attr->change(set=>1,tm=>6);
	$attr->change(set=>0,tm=>8);
	$attr->change(set=>1,tm=>4); # this should be a noop, guarantees that historical logging is not supported
	is($attr->average(),1/2,                             'Weighted average');
	is_deeply($$attr{log},{0=>0,2=>1,4=>0,6=>1,8=>0},    'Log');
	is_deeply($$attr{aog},{0=>0,2=>0,4=>.5,6=>1/3,8=>.5},'Avg log');
	$attr->change(set=>1,tm=>8);
	is($attr->average(),1/2,                             'Overwrite avg');
	is_deeply($$attr{log},{0=>0,2=>1,4=>0,6=>1,8=>1},    'Overwrite log');
	is_deeply($$attr{aog},{0=>0,2=>0,4=>.5,6=>1/3,8=>.5},'Overwrite avg log');
	#
	for(my $tm=8;$tm<80;$tm+=4) { $attr->change(tm=>$tm,_log=>1) }
	ok($attr->average()<0.95,'Long term average still below 0.95 ');
	$attr->change(tm=>80,_log=>1);
	ok($attr->average()>=0.95,'Long term average still reaches 0.95');
};

subtest 'Report'=>sub {
	plan tests=>6;
	my ($y,$attr,%report);
	$y=0;
	$attr=Schedule::Activity::Attribute->new(type=>'int',value=>$y,tm=>0);
	foreach my $tm (1..4) { $y+=2; $attr->change(tm=>$tm,set=>$y) }
	%report=$attr->report();
	is($report{y},  8,'Integer:  value');
	is($report{avg},4,'Integer:  avg');
	is_deeply($report{xy},[map {[$_,2*$_,$_]} (0..4)],'Integer:  xy');
	#
	$y=0;
	$attr=Schedule::Activity::Attribute->new(type=>'bool',value=>$y,tm=>0);
	foreach my $tm (1..4) { $y=1-$y; $attr->change(tm=>$tm,set=>$y) }
	%report=$attr->report();
	is($report{y},  0, 'Boolean:  value');
	is($report{avg},.5,'Boolean:  avg');
	my @avgs=(0,0,1/2,1/3,1/2);
	is_deeply($report{xy},[map {[$_,$_%2,$avgs[$_]]} (0..4)],'Boolean:  xy');
};

subtest 'Reset'=>sub {
	plan tests=>5;
	my $attr=Schedule::Activity::Attribute->new(type=>'int',value=>321,tm=>3);
	$attr->change(tm=>6,incr=>7);
	is($attr->value(),328,'Integer:  incremented');
	$attr->reset();
	is($attr->value(),  321,'Integer:  value');
	is($attr->average(),321,'Integer:  avg');
	is_deeply($$attr{log},{3=>321},'Integer:  log');
	is_deeply($$attr{aog},{3=>321},'Integer:  avg log');
};

subtest 'Dump/Restore'=>sub {
	plan tests=>29;
	my $attr=Schedule::Activity::Attribute->new(type=>'int',value=>0,tm=>0);
	$attr->change(tm=>5,set=>15);
	$attr->change(tm=>10,set=>5);
	$attr->change(tm=>15,set=>10);
	my %copy=$attr->dump();
		$copy{avg}=int($copy{avg}*1e2)/1e2;
		$copy{aog}{15}=int($copy{aog}{15}*1e2)/1e2;
	$attr->change(tm=>20,incr=>10);
	$attr->change(tm=>25,incr=>10);
	is($copy{type},'int','Dumped:  type');
	is($copy{value},10,  'Dumped:  value');
	is($copy{tmmax},15,  'Dumped:  tmmax');
	is($copy{avg},8.33,  'Dumped:  avg');
	is($copy{tmsum},15,  'Dumped:  tmsum');
	is_deeply($copy{log},{0=>0,5=>15,10=>5,15=>10},      'Dumped:  log');
	is_deeply($copy{aog},{0=>0,5=>7.5,10=>8.75,15=>8.33},'Dumped:  avg log');
	is($attr->value(),  30,'Attr:  value');
	is($$attr{tmmax},   25,'Attr:  tmmax');
	is($attr->average(),13,'Attr:  avg');
	is($$attr{tmsum},   25,'Attr:  tmsum');
		$$attr{aog}{15}=int($$attr{aog}{15}*1e2)/1e2;
	is_deeply($$attr{log},{0=>0,5=>15,10=>5,15=>10,20=>20,25=>30},      'Attr:  log');
	is_deeply($$attr{aog},{0=>0,5=>7.5,10=>8.75,15=>8.33,20=>10,25=>13},'Attr:  avg log');
	#
	$attr->restore(%copy);
	is($$attr{type},'int','Restored:  type');
	is($attr->value(), 10,'Restored:  value');
	is($$attr{tmmax},  15,'Restored:  tmmax');
	is($$attr{avg},  8.33,'Restored:  avg');
	is($$attr{tmsum},  15,'Restored:  tmsum');
	is_deeply($$attr{log},{0=>0,5=>15,10=>5,15=>10},      'Restored:  log');
	is_deeply($$attr{aog},{0=>0,5=>7.5,10=>8.75,15=>8.33},'Restored:  avg log');
	#
	$$attr{avg}=$$attr{aog}{15}=25/3;
	$attr->change(tm=>20,incr=>10);
	$attr->change(tm=>25,incr=>10);
	is($attr->value(),  30,'Attr2:  value');
	is($$attr{tmmax},   25,'Attr2:  tmmax');
	is($attr->average(),13,'Attr2:  avg');
	is($$attr{tmsum},   25,'Attr2:  tmsum');
		$$attr{aog}{15}=int($$attr{aog}{15}*1e2)/1e2;
	is_deeply($$attr{log},{0=>0,5=>15,10=>5,15=>10,20=>20,25=>30},      'Attr2:  log');
	is_deeply($$attr{aog},{0=>0,5=>7.5,10=>8.75,15=>8.33,20=>10,25=>13},'Attr2:  avg log');
	#
	my $refid="$attr";
	$attr=Schedule::Activity::Attribute->restore(%copy);
	is($attr->value(),10,'Restored (copy):  value');
	is($$attr{tmmax}, 15,'Restored (copy):  tmmax');
	isnt("$attr",$refid,'New object created');
};
