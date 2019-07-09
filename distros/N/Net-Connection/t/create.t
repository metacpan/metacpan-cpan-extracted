#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

BEGIN {
   use_ok('Net::Connection');
}

my $extra_tests=0;
my $test={
		  'foreign_host' => undef,
		  'local_host' => undef,
		  'foreign_port' => undef,
		  'foreign_port_name' => undef,
		  'local_port' => undef,
		  'local_port_name' => undef,
		  'sendq' => undef,
		  'recvq' => undef,
		  'pid' => undef,
		  'uid' => undef,
		  'username' => undef,
		  'state' => undef,
		  'proto' => undef,
		  'local_ptr' => undef,
		  'foreign_ptr' => undef,
		  };
my $object;

# Make sure the it wont create a object with stuff undefined.
my $worked=0;
eval{
	$object=Net::Connection->new( $test );
	$worked=1;
};
ok( $worked eq '0', 'all undef check') or diag("Created a object when all requirements were undef");

# Make sure it does not work if state is undef.
$test->{'foreign_host'}='1.2.3.4';
$test->{'foreign_port'}='22';
$test->{'local_host'}='1.2.3.4';
$test->{'local_port'}='11111';
$test->{'proto'}='tcp4';
$test->{'state'}=undef;
$worked=0;
eval{
	$object=Net::Connection->new( $test );
	$worked=1;
};
ok( $worked eq '0', 'state undef check') or diag("Created a object when state was undef");

# Make sure it does not work if proto is undef.
$test->{'foreign_host'}='1.2.3.4';
$test->{'foreign_port'}='22';
$test->{'local_host'}='1.2.3.4';
$test->{'local_port'}='11111';
$test->{'proto'}=undef;
$test->{'state'}='ESTABLISHED';
$worked=0;
eval{
	$object=Net::Connection->new( $test );
	$worked=1;
};
ok( $worked eq '0', 'proto undef check') or diag("Created a object when proto was undef");

# Make sure it does not work if local_port is undef.
$test->{'foreign_host'}='1.2.3.4';
$test->{'foreign_port'}='22';
$test->{'local_host'}='1.2.3.4';
$test->{'local_port'}=undef;
$test->{'proto'}='tcp4';
$test->{'state'}='ESTABLISHED';
$worked=0;
eval{
	$object=Net::Connection->new( $test );
	$worked=1;
};
ok( $worked eq '0', 'local_port undef check') or diag("Created a object when local_port was undef");

# Make sure it does not work if local_host is undef.
$test->{'foreign_host'}='1.2.3.4';
$test->{'foreign_port'}='22';
$test->{'local_host'}=undef;
$test->{'local_port'}='11111';
$test->{'proto'}='tcp4';
$test->{'state'}='ESTABLISHED';
$worked=0;
eval{
	$object=Net::Connection->new( $test );
	$worked=1;
};
ok( $worked eq '0', 'local_host undef check') or diag("Created a object when local_host was undef");

# Make sure it does not work if foreign_port is undef.
$test->{'foreign_host'}='1.2.3.4';
$test->{'foreign_port'}=undef;
$test->{'local_host'}='1.2.3.4';
$test->{'local_port'}='11111';
$test->{'proto'}='tcp4';
$test->{'state'}='ESTABLISHED';
$worked=0;
eval{
	$object=Net::Connection->new( $test );
	$worked=1;
};
ok( $worked eq '0', 'foreign_port undef check') or diag("Created a object when foreign_port was undef");

# Make sure it does not work if foreign_host is undef.
$test->{'foreign_host'}=undef;
$test->{'foreign_port'}='22';
$test->{'local_host'}='1.2.3.4';
$test->{'local_port'}='11111';
$test->{'proto'}='tcp4';
$test->{'state'}='ESTABLISHED';
$worked=0;
eval{
	$object=Net::Connection->new( $test );
	$worked=1;
};
ok( $worked eq '0', 'foreign_host undef check') or diag("Created a object when foreign_host was undef");

# Makes sure we can set the queue stuff
$test->{'foreign_host'}='1.2.3.4';
$test->{'foreign_port'}='22';
$test->{'local_host'}='1.2.3.4';
$test->{'local_port'}='11111';
$test->{'proto'}='tcp4';
$test->{'state'}='ESTABLISHED';
$test->{'sendq'}='1';
$test->{'recvq'}='0';
$worked=0;
eval{
	$object=Net::Connection->new( $test );
	$worked=1;
};
ok( $worked eq '1', 'queue defined check') or diag("Failed to create a object with numeric queue values");

# Makes sure we send queue errors if non-numeric
$test->{'foreign_host'}='1.2.3.4';
$test->{'foreign_port'}='22';
$test->{'local_host'}='1.2.3.4';
$test->{'local_port'}='11111';
$test->{'proto'}='tcp4';
$test->{'state'}='ESTABLISHED';
$test->{'sendq'}='A';
$test->{'recvq'}='0';
$worked=0;
eval{
	$object=Net::Connection->new( $test );
	$worked=1;
};
ok( $worked eq '0', 'send queue non-numeric check') or diag("Created a object when sendq was non-numeric");

# Makes sure we recieve queue errors if non-numeric
$test->{'foreign_host'}='1.2.3.4';
$test->{'foreign_port'}='22';
$test->{'local_host'}='1.2.3.4';
$test->{'local_port'}='11111';
$test->{'proto'}='tcp4';
$test->{'state'}='ESTABLISHED';
$test->{'sendq'}='0';
$test->{'recvq'}='A';
$worked=0;
eval{
	$object=Net::Connection->new( $test );
	$worked=1;
};
ok( $worked eq '0', 'recieve queue non-numeric check') or diag("Created a object when recvq was non-numeric");

# Makes sure we setting the pid works
$test->{'foreign_host'}='1.2.3.4';
$test->{'foreign_port'}='22';
$test->{'local_host'}='1.2.3.4';
$test->{'local_port'}='11111';
$test->{'proto'}='tcp4';
$test->{'state'}='ESTABLISHED';
$test->{'sendq'}='0';
$test->{'recvq'}='0';
$test->{'pid'}='33';
$worked=0;
eval{
	$object=Net::Connection->new( $test );
	$worked=1;
};
ok( $worked eq '1', 'pid numeric check') or diag("Failed to create object");

# Makes sure we pid errors if non-numeric
$test->{'foreign_host'}='1.2.3.4';
$test->{'foreign_port'}='22';
$test->{'local_host'}='1.2.3.4';
$test->{'local_port'}='11111';
$test->{'proto'}='tcp4';
$test->{'state'}='ESTABLISHED';
$test->{'sendq'}='0';
$test->{'recvq'}='0';
$test->{'pid'}='A';
$worked=0;
eval{
	$object=Net::Connection->new( $test );
	$worked=1;
};
ok( $worked eq '0', 'pid non-numeric check') or diag("Created a object when pid was non-numeric");

# Makes sure we setting the uid works
$test->{'foreign_host'}='1.2.3.4';
$test->{'foreign_port'}='22';
$test->{'local_host'}='1.2.3.4';
$test->{'local_port'}='11111';
$test->{'proto'}='tcp4';
$test->{'state'}='ESTABLISHED';
$test->{'sendq'}='0';
$test->{'recvq'}='0';
$test->{'pid'}='33';
$test->{'uid'}='0';
$worked=0;
eval{
	$object=Net::Connection->new( $test );
	$worked=1;
};
ok( $worked eq '1', 'uid numeric check') or diag("Failed to create object");

# Makes sure we uid errors if non-numeric
$test->{'foreign_host'}='1.2.3.4';
$test->{'foreign_port'}='22';
$test->{'local_host'}='1.2.3.4';
$test->{'local_port'}='11111';
$test->{'proto'}='tcp4';
$test->{'state'}='ESTABLISHED';
$test->{'sendq'}='0';
$test->{'recvq'}='0';
$test->{'pid'}='0';
$test->{'uid'}='A';
$worked=0;
eval{
	$object=Net::Connection->new( $test );
	$worked=1;
};
ok( $worked eq '0', 'uid non-numeric check') or diag("Created a object when uid was non-numeric");

# UID resolving tests if on unix
if (
	( $^O =~ /bsd$/ ) ||
	( $^O =~ /linux/ )
	){
	$extra_tests=$extra_tests+2;

	# Makes sure we can resolve UID 0 to root
	$test->{'uid'}='0';
	$test->{'uid_resolve'}='1';
	$worked=0;
	eval{
		$object=Net::Connection->new( $test );
		if ( defined( $object->username ) ){
		$worked=$object->username;
		}
	};
	ok( $worked eq 'root', 'uid 0->root resolve check') or diag("Unable to resolve UID 0 to root");

	# Makes sure can resovle root to UID 0
	$test->{'uid'}=undef;
	$test->{'username'}='root';
	$test->{'uid_resolve'}='1';
	$worked=1;
	eval{
		$object=Net::Connection->new( $test );
		if ( defined( $object->uid ) ){
			$worked=$object->uid;
		}
	};
	ok( $worked eq '0', 'root->uid 0 resolve check') or diag("Unable to resolve root to UID 0");
}

my $tests_ran=15+$extra_tests;
done_testing($tests_ran);
