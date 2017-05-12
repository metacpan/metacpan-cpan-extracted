#!/usr/bin/perl

use Encode;

open(LST,"region.txt");
@items=<LST>;
close LST;

foreach $item (@items) {
	my ($id,$city,$country,$label)=split(/\t/,$item);
	$label=~s/\n//;
	Encode::from_to($label,'cp1251','utf8');
	print "'$label'=>'$country',\n" if ($city==0);
}
