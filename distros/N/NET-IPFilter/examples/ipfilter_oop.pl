#!/usr/bin/perl

use Benchmark;
use Data::Dumper;
use NET::IPFilter;

#system("clear");

########
#### INIT()
########

# start timer
my $start_init = Benchmark->new();

# my $obj = NET::IPFilter->new(	ipfilter	=> 'http://www.bluetack.co.uk/config/pipfilter.dat.gz',
my $obj = NET::IPFilter->new(	ipfilter	=> '/home/thecerial/firewall/ipfilter.dat',
				tmpdir		=> '/var/tmp',
				force_init	=> '0'
);


# end timer
my $end_init = Benchmark->new();

# calculate difference
my $diff_init = timediff($end_init, $start_init);

# report
print "_init():: Time taken was ", timestr($diff_init, 'all'), " seconds\n";


	
#######
### CHECK()
#######
# 024.199.196.184-024.199.196.191,109,[L2]NORTEL-SOFTSWITCH-WA

my $IP 		= "024.199.196.184";
my $start_chk 	= Benchmark->new();

my $isValid 	= $obj->isValid($IP);	#  1 not to be blocked | 0 to be blocked

my $end_chk 	= Benchmark->new();
my $diff_chk 	= timediff($end_chk, $start_chk);


# report
print "_check():: Time taken was ", timestr($diff_chk, 'all'), " seconds\n";

if ( $isValid == 1 ) {
	print "$IP dont need to be blocked because it is not in ipfilter.dat\n";
} elsif( $isValid == 0 ) {
	print "$IP MUST be blocked because it is in ipfilter.dat\n";
};





exit;





#######
# 222.228.226.192-222.228.226.255,090,[L1]Movie Full,inc

my $s 		= $obj->_ip2long("222.228.226.192");
my $e 		= $obj->_ip2long("222.228.226.255");
my $IPtoCheck	= $obj->_ip2long("222.228.226.210"); 

print "FROM: $s \n";
print "TO  : $e \n";
print "CHK : $IPtoCheck\n";
print "FLG : " . check(). " \n";

my $RangesArrayRef = $obj->{'_IPRANGES_ARRAY_REF'};

sub check(){

for ( my $count=0; $count<=$howmany; $count++) {
		
	my ($RangFrom, $RangTo) = split("-", $RangesArrayRef->[$count]);
	
	if ( $IPtoCheck > $RangFrom && $IPtoCheck < $RangTo ) {
		return 0;	# to be blocked
	} elsif ( $IPtoCheck <=> $RangFrom || $IPtoCheck <=> $RangTo ) {
		return 0;	# to be blocked
	}; # if ( $IPtoCheck > $RangTo || $IPtoCheck < $RangFrom ) {

	$count++;

}; # for ( my $count=0; $count<=$howmany; $count++) {

};