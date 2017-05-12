# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl PBS.t'

#########################

# change 'tests => 2' to 'tests => last_test_to_print';

use Test::More tests => 14;
BEGIN { use_ok('PBS'); use_ok('PBS::Status'); use_ok('PBS::Attr'); };


my $fail = 0;
foreach my $constname (qw(
	 MAXNAMLEN MAXPATHLEN MAX_ENCODE_BFR MGR_CMD_ACTIVE MGR_CMD_CREATE
	MGR_CMD_DELETE MGR_CMD_LIST MGR_CMD_PRINT MGR_CMD_SET MGR_CMD_UNSET
	MGR_OBJ_JOB MGR_OBJ_NODE MGR_OBJ_NONE MGR_OBJ_QUEUE MGR_OBJ_SERVER
	MSG_ERR MSG_OUT PBS_BATCH_SERVICE_PORT PBS_BATCH_SERVICE_PORT_DIS
	PBS_INTERACTIVE PBS_MANAGER_SERVICE_PORT PBS_MAXCLTJOBID PBS_MAXDEST
	PBS_MAXGRPN PBS_MAXHOSTNAME PBS_MAXPORTNUM PBS_MAXQUEUENAME
	PBS_MAXROUTEDEST PBS_MAXSEQNUM PBS_MAXSERVERNAME PBS_MAXSVRJOBID
	PBS_MAXUSER PBS_MOM_SERVICE_PORT PBS_SCHEDULER_SERVICE_PORT
	PBS_TERM_BUF_SZ PBS_TERM_CCA PBS_USE_IFF RESOURCE_T_ALL RESOURCE_T_NULL
	SHUT_DELAY SHUT_IMMEDIATE SHUT_QUICK SHUT_SIG)) {
  next if (eval "my \$a = $constname; 1");
  if ($@ =~ /^Your vendor has not defined PBS macro $constname/) {
    print "# pass: $@";
  } else {
    print "# fail: $@";
    $fail = 1;
  }

}

ok( $fail == 0 , 'Constants' );
#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $pbs = PBS->new();
ok($pbs, 'New');
ok($pbs->connect(), 'pbs_connect');

my $stat = $pbs->stat_server();
ok($stat, "stat_server");
my $statlist = $stat->get();
my $default_queue;
my $node;
foreach my $s (@$statlist) {
  $node = $s->{'name'};
   my $attrs = $s->{'attributes'};
   my $attrlist = $attrs->get();
   foreach my $a (@$attrlist) {
       if ($a->{'name'} =~ /default_queue/) {
           $default_queue = $a->{'value'};
       }
   }
}

$stat = $pbs->stat_queue($default_queue);
ok($stat, "stat_queue");
my $stat_info = $stat->get();
ok($stat_info, "stat");
my $s1 = pop(@$stat_info);
my $attr = $s1->{'attributes'};
my $attrs = $attr->get();
ok($attrs, "attributes");

$stat = $pbs->stat_node($node);
ok($stat, "stat_node");
# try to stat an invalid job to see if it returns an error
$stat = $pbs->stat_job("5822A");
ok(!$stat, "stat_job");
ok($pbs->error(), "error");

$pbs->disconnect();
pass('pbs_disconnect');
