# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..13\n"; }
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;
use Net::DNSBL::MultiDaemon;

*purge_cache	= \&Net::DNSBL::MultiDaemon::purge_cache;
*set_nownext	= \&Net::DNSBL::MultiDaemon::set_nownext;

$loaded = 1;
print "ok 1\n";
######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$test = 2;

sub ok {
  print "ok $test\n";
  ++$test;
}

my($expires,$used);
my $now = 1000;
my $next = $now;
my $csize = 10;

my($interval,$AVGs,$CNTs,$cache,$topurge) = set_nownext($now,$next,$csize);

#my %cache = (
#
#       ip address      => {
#               expires =>      time,           now + TTL from response or 3600 minimum
#               used    =>      time,           time cache item was last used
#		who	=>	blist[0],	which DNSBL caused caching
#               txt     =>      'string',       txt from our config file or empty
#       },
#);

my $who = 'bl name';
my $txt = 'bl text';


sub fill_cache {
  (my $size) = @_;
  my $w = 200;
  my $x = 0;
  my $y = 0;
  my $z = 0;
  foreach (0..$size-1) {
    my $rip = sprintf("%d.%d.%d.%d",$z,$y,$x,$w);
    ++$z;
    if ($z > 255) {
      $z = 0;
      ++$y;
      if ($y > 255) {
	$y = 0;
	++$x;
      }
    }
    $cache->{$rip} = {			# global cache ptr
	expires	=> $expires--,
	used	=> $used++,
	who	=> $who,
	txt	=> $txt,
    };
  }
}

sub collect_results {
  my $hash = $_[0] || $cache;		# use argument or default $cache ptr
  my $results = '';
  foreach (sort keys %$hash) {
    $results .=  
"$_  => {
        expires => $hash->{$_}->{expires},
        used    => $hash->{$_}->{used},
        who     => $hash->{$_}->{who},
        txt     => $hash->{$_}->{txt},
},
";
  }
  return $results;
}

sub purge {
  while ( purge_cache() >= 0 ) {};
}

# test 2, 3, 4		# check removal of expired items and returned values
$expires = $now +6;			# should be three expired items, 7 kept items
$used = 1;				# should all be used a LONG time ago
fill_cache(10);
my $size = keys %$cache;
print "bad cache size exp 10, got $size\nnot " unless $size == 10;
&ok;

# test 3
purge();
$size = keys %$cache;
print "bad cache size exp 7, got $size\nnot " unless $size == 7;
&ok;

# test 4
my $got = collect_results();
my $exp = "0.0.0.200  => {
        expires => 1006,
        used    => 1,
        who     => bl name,
        txt     => bl text,
},
1.0.0.200  => {
        expires => 1005,
        used    => 2,
        who     => bl name,
        txt     => bl text,
},
2.0.0.200  => {
        expires => 1004,
        used    => 3,
        who     => bl name,
        txt     => bl text,
},
3.0.0.200  => {
        expires => 1003,
        used    => 4,
        who     => bl name,
        txt     => bl text,
},
4.0.0.200  => {
        expires => 1002,
        used    => 5,
        who     => bl name,
        txt     => bl text,
},
5.0.0.200  => {
        expires => 1001,
        used    => 6,
        who     => bl name,
        txt     => bl text,
},
6.0.0.200  => {
        expires => 1000,
        used    => 7,
        who     => bl name,
        txt     => bl text,
},
";
print "exp
$exp
got
$got

not " unless $exp eq $got;
&ok;

# test 5, 6, 7			# check removal of oversize array and returned results
%$cache = ();			# clear cache
$expires = $now + 100;		# all valid expire times
$used = 1;			# used sequence
fill_cache(15);			# overfill cache
$size = keys %$cache;
print "bad cache size exp 15, got $size\nnot " unless $size == 15;
&ok;

# test 6
purge();
$size = keys %$cache;
print "bad cache size exp 10, got $size\nnot " unless $size == 10;
&ok;

# test 7
$got = collect_results();
$exp = "10.0.0.200  => {
        expires => 1090,
        used    => 11,
        who     => bl name,
        txt     => bl text,
},
11.0.0.200  => {
        expires => 1089,
        used    => 12,
        who     => bl name,
        txt     => bl text,
},
12.0.0.200  => {
        expires => 1088,
        used    => 13,
        who     => bl name,
        txt     => bl text,
},
13.0.0.200  => {
        expires => 1087,
        used    => 14,
        who     => bl name,
        txt     => bl text,
},
14.0.0.200  => {
        expires => 1086,
        used    => 15,
        who     => bl name,
        txt     => bl text,
},
5.0.0.200  => {
        expires => 1095,
        used    => 6,
        who     => bl name,
        txt     => bl text,
},
6.0.0.200  => {
        expires => 1094,
        used    => 7,
        who     => bl name,
        txt     => bl text,
},
7.0.0.200  => {
        expires => 1093,
        used    => 8,
        who     => bl name,
        txt     => bl text,
},
8.0.0.200  => {
        expires => 1092,
        used    => 9,
        who     => bl name,
        txt     => bl text,
},
9.0.0.200  => {
        expires => 1091,
        used    => 10,
        who     => bl name,
        txt     => bl text,
},
";
print "exp
$exp
got
$got

not " unless $exp eq $got;
&ok;

# test 8, 9, 10		# mixed purge
%$cache = ();		# clear cache
$expires = $now +16;			# should be three expired items, 17 kept items
$used = 1;				# should all be used a LONG time ago
fill_cache(20);
$size = keys %$cache;
print "bad cache size exp 20, got $size\nnot " unless $size == 20;
&ok;

# test 9
purge();
$size = keys %$cache;
print "bad cache size exp 10, got $size\nnot " unless $size == 10;
&ok;

# test 10
$got = collect_results();
$exp = "10.0.0.200  => {
        expires => 1006,
        used    => 11,
        who     => bl name,
        txt     => bl text,
},
11.0.0.200  => {
        expires => 1005,
        used    => 12,
        who     => bl name,
        txt     => bl text,
},
12.0.0.200  => {
        expires => 1004,
        used    => 13,
        who     => bl name,
        txt     => bl text,
},
13.0.0.200  => {
        expires => 1003,
        used    => 14,
        who     => bl name,
        txt     => bl text,
},
14.0.0.200  => {
        expires => 1002,
        used    => 15,
        who     => bl name,
        txt     => bl text,
},
15.0.0.200  => {
        expires => 1001,
        used    => 16,
        who     => bl name,
        txt     => bl text,
},
16.0.0.200  => {
        expires => 1000,
        used    => 17,
        who     => bl name,
        txt     => bl text,
},
7.0.0.200  => {
        expires => 1009,
        used    => 8,
        who     => bl name,
        txt     => bl text,
},
8.0.0.200  => {
        expires => 1008,
        used    => 9,
        who     => bl name,
        txt     => bl text,
},
9.0.0.200  => {
        expires => 1007,
        used    => 10,
        who     => bl name,
        txt     => bl text,
},
";
print "exp
$exp
got
$got

not " unless $exp eq $got;
&ok;

############################
# test 11, 12, 13	sort with missing cache items
%$cache = ();		# clear cache
$expires = $now +100;			# nothing expires
$used = 1;				# should all be used a LONG time ago
fill_cache(10);
$size = keys %$cache;
print "bad cache size exp 10, got $size\nnot " unless $size == 10;
&ok;

# test 12
my %lcache = %$cache;			# local copy of cache;
purge_cache();				# initialize gnome sort
my($k1,$k2) = @{$topurge}[0,2];
#print "k1=$k1, k2=$k2\n";
delete @{$cache}{$k1,$k2};
delete @lcache{$k1,$k2};
purge();				# do sort, noting deleted members
$size = keys %$cache;
print "bad cache size exp 8, got $size\nnot " unless $size == 8;
&ok;

# test 13
$got = collect_results();
$exp = collect_results(\%lcache);
print "exp
$exp
got
$got

not " unless $exp eq $got;
&ok;
