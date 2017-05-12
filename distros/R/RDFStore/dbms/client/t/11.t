
$|=1;
$nfork = 0;
$nft = 10;
$tests = 12 + $nfork;
$n= 100;

#use DB_File;
use DBMS;

#use File::Path qw(rmtree);

no strict;

print "1..$tests\n";
$start = time;
$forreal =1;
$test=0;

$test++; # 1
print 1==1 ? "ok $test\n" : "not ok $test\n"
	if $forreal;

$aap = 'aap'.$$;
$noot = 'noot'.$$;

#rmtree '/usr/tmp/ti';

# 2 
$test++;
tie %aap, 'DBMS','tiepje',&DBMS::XSMODE_CREAT,0 and print "ok $test\n" or die $!;


# 3
%aap=();
$tans++;
# try a fetch
$test++;
$tans++;
print ! defined $aap{ $aap } ? "ok $test\n" : "not ok $test\n"
	if $forreal;

# 4
# try a store..
$aap{ $aap } = $noot;
$test++;print 1 ? "ok $test\n" : "not ok $test\n"
	if $forreal;
$trans++;

# 5
# try a fetch...
$test++;print $aap{ $aap } eq $noot ? "ok $test\n" : "not ok $test\n"
	if $forreal;
$trans++;

# 6 

$c='';$d='';
for $i (1..$n) {
	$j = 1+$i;
	$c .= ( $i * $i ).'x'.$$;
	$d .= ( $j * $j ).'y'.$$;
	$c=substr($c,-150) if length($c) > 160;
	$d=substr($d,-150) if length($d) > 160;
	$aap{ $c } = $d;
$trans++;
	};
$test++;print 1 ? "ok $test\n" : "not ok $test\n"
	if $forreal;

# 7 	
$x=0;
$c='';$d='';
for $i (1..$n) {
	$j = 1+$i;
	$c .= ( $i * $i ).'x'.$$;
	$d .= ( $j * $j ).'y'.$$;
	$c=substr($c,-150) if length($c) > 160;
	$d=substr($d,-150) if length($d) > 160;
	$trans++;
	next unless defined $aap{ $c };
	$trans++;
	$x++ if $aap{ $c } eq $d;
	};

$trans++;
$test++;print $x==$n ? "ok $test\n" : "not ok $test\n"
	if $forreal;

# 8
@keys=keys %aap;
$trans+=1+$#keys;
$test++;print $#keys == $n ? "ok $test\n" : "not ok $test\n"
	if $forreal;

# 9
$trans++;
$test++;print exists $aap{ $aap } ? "ok $test\n" : "not ok $test\n"
	if $forreal;

# 10
$trans++;
$test++;print !exists $aap{ $noot } ? "ok $test\n" : "not ok $test\n"
	if $forreal;
# 11

$trans++;
%aap = ();
$trans++;
$test++;print !exists $aap{ $aap } ? "ok $test\n" : "not ok $test\n"
 	if $forreal;
untie %aap;

# 12
if ($nfork) {
for $child ( 1 .. $nfork ) {
	if (fork() == 0) {
  	    if (fork() == 0) {
		@k=();
		tie %aap, 'DBMS','tiepje',&DBMS::XSMODE_CREAT,0 or die;
		tie %aap2, 'DBMS','tiepje'.$$,&DBMS::XSMODE_CREAT,0 or die;
		for $i ( 1 .. $nft ) {
			$k = $i.$$.'hello';	
			$aap{ $k } = $i.$$;
			$aap2{ $k } = $i.$$;
			push @k,$k;
			};
		foreach $k (@k) {
			warn "1 child $child fail $$ $k" unless defined $aap{ $k };#  and $aap{ $k } eq $i.$$;
			warn "2 child $child fail $$ $k" unless defined $aap2{ $k };#  and $aap2{ $k } eq $i.$$;
			};
		untie %aap2;
		untie %aap;
		print "ok ".($test+$child)."\n";
		sleep(1);
		exit 0;
		};
	     exit;
	     };	
	};

do {
	$t = wait;
	} while ($t > 0 );
wait;
};

tie %aap, 'DBMS','tiepje',&DBMS::XSMODE_CREAT,0;
$trans += $nfork * $nft;
$test += $nfork;

# 13 
$i=0;
foreach (keys(%aap)) {
	$trans++;
	next unless m/hello$/;
	$i++;
	};
$test++;
print $i == $nfork * $nft ? "ok $test\n" : "not ok $test\n";

%aap=();
untie %aap;

$end = time;
my $d2 = $end - $start;

#print "$trans Net Transactions ".( ($d2) ? ($trans/$d2) : 'N/A' )." tps\n";

exit;

