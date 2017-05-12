# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 20-api.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';
#use Test::Simple tests => 5;
use Test::More tests=>2;

BEGIN { 
	use SWISH::API::Remote; 
	use SWISH::API::Remote::Results; 
	use SWISH::API::Remote::Result; 
};


#
# below is the output of:
#
# % lynx -source \
#	'http://localhost/swished/swished?f=DEFAULT&w=unix&p=swishrank,swishdocpath,swishtitle,swishdocsize&b=0&m=10'
#
# which in turn, came from ./example/swishedsearch


my $remote;
my $res;

ok( $remote = new SWISH::API::Remote("http://nosuchserverllk.com/perltest/swished", "index1"));

my $content = qq{
d: pid 32673 opened index /var/lib/sman/sman.index for search 'unix'
k: 0=swishrank&1=swishdocpath&2=swishtitle&3=swishdocsize
m: hits=1123&swished_version=0.09k
r: 0=1000&1=%2Fusr%2Fshare%2Fman%2Fman1%2Fperlport.1.gz&2=perlport&3=159080
r: 0=893&1=%2Fusr%2Fshare%2Fman%2Fman5%2Fsmb.conf.5.gz&2=smb.conf&3=457503
r: 0=825&1=%2Fusr%2Fshare%2Fman%2Fman3%2FExtUtils%3A%3ALiblist.3pm&2=ExtUtils%3A%3ALiblist&3=17854
r: 0=825&1=%2Fusr%2Fshare%2Fman%2Fman3%2FExtUtils%3A%3ALiblist.3pm.gz&2=ExtUtils%3A%3ALiblist&3=18358
r: 0=805&1=%2Fusr%2Fshare%2Fman%2Fman1%2Fperlipc.1.gz&2=perlipc&3=120841
r: 0=796&1=%2Fusr%2Fshare%2Fman%2Fman7%2Funix.7.gz&2=unix&3=13999
r: 0=786&1=%2Fusr%2Fshare%2Fman%2Fman1%2Funzip.1.gz&2=unzip&3=74656
r: 0=786&1=%2Fusr%2Fshare%2Fman%2Fman1%2Fzipinfo.1.gz&2=zipinfo&3=38401
r: 0=786&1=%2Fusr%2Fshare%2Fman%2Fman8%2Flsof.8.gz&2=lsof&3=200104
r: 0=766&1=%2Fusr%2Fshare%2Fman%2Fman1%2Fdc_client.1.gz&2=dc_client&3=16446 
};

#warn $content;
my($results, $headers, $props, $metas) = $remote->_ParseContent( $content );

cmp_ok( $results->Hits(), '==', 1123, 'hits');

#use Data::Dumper;
#print Dumper( $results );



#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

