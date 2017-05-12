#!/usr/bin/perl -w

#		test DateDesc.pm

push (@INC, '/home/ajackson/bin/lib/'); # include my personal modules

require PlotCalendar::DateDesc;

@regcal = ( qw/ Sunday  monday  Tuesday  Wednesday  thursday  friday  saturday /);

chomp(@line = <DATA>);

print "1..",scalar(@line),"\n";

($month, $year) = (3,1999);

$trans = PlotCalendar::DateDesc->new($month, $year);
$i=1;
foreach (@regcal) {
	chomp;
	$doms = $trans->getdom($_); # return day-of-month
	$regdates{$_} = $doms;
	$answer = join(',',@{$trans->getdates($_)});
	#print "$_ dates: $answer\n";
	if ($answer eq $line[$i-1]) {
		print "ok ",$i,"\n";
	}
	else {
		print "not ok ",$i,"\n";
	}
	$i++;
}

foreach $days (keys %regdates) {
	$answer = '';
	foreach $j (@{$regdates{$days}}) {
		$answer .= $j . ' '; 
	}
	if ($answer eq $line[$i-1]) {
		print "ok ",$i,"\n";
	}
	else {
		print "not ok ",$i,"\n";
	}
	$i++;
}

$day = 'first monday and third monday';
$answer = join(',',@{$trans->getdom($day)});
if ($answer eq $line[$i-1]) {
	print "ok ",$i,"\n";
}
else {
	print "not ok ",$i,"\n";
}
$i++;

$day = 'last monday and third monday';
$answer = join(',',@{$trans->getdom($day)});
if ($answer eq $line[$i-1]) {
	print "ok ",$i,"\n";
}
else {
	print "not ok ",$i,"\n";
}
$i++;

$day = 'last fri and third Monday';
$answer = join(',',@{$trans->getdom($day)});
if ($answer eq $line[$i-1]) {
	print "ok ",$i,"\n";
}
else {
	print "not ok ",$i,"\n";
}

1;

__DATA__
3/7/1999,3/14/1999,3/21/1999,3/28/1999
3/1/1999,3/8/1999,3/15/1999,3/22/1999,3/29/1999
3/2/1999,3/9/1999,3/16/1999,3/23/1999,3/30/1999
3/3/1999,3/10/1999,3/17/1999,3/24/1999,3/31/1999
3/4/1999,3/11/1999,3/18/1999,3/25/1999
3/5/1999,3/12/1999,3/19/1999,3/26/1999
3/6/1999,3/13/1999,3/20/1999,3/27/1999
1 8 15 22 29 
4 11 18 25 
3 10 17 24 31 
7 14 21 28 
6 13 20 27 
5 12 19 26 
2 9 16 23 30 
1,15
29,15
26,15
