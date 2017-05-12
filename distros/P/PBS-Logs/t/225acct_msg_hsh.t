use Test::More tests => 6;
#use Test::More "no_plan";

use PBS::Logs::Acct qw{message_hash message_hash_dump};

my $m = qq{user="gonwat		" group='mpccc' account="  mp99" jobname=n queue=' workq' ctime=1107284778 qtime=1107284778 etime=1107284778 start=1107284778 exec_host=davinci/0*4 Resource_List.nodes=1:ppn=2 Resource_List.mem=500mb Resource_List.ncpus=4 Resource_List.walltime=00:25:00 session=15040 end=1107284778 Exit_status=255 resources_used.cpupercent=0 resources_used.cput=00:00:00 resources_used.mem=2880kb resources_used.ncpus=4 resources_used.vmem=6848kb resources_used.walltime=00:00:00};

my $s = qq{{
'account' => '  mp99',
'ctime' => '1107284778',
'end' => '1107284778',
'etime' => '1107284778',
'exec_host' => 'davinci/0*4',
'Exit_status' => '255',
'group' => 'mpccc',
'jobname' => 'n',
'qtime' => '1107284778',
'queue' => ' workq',
'Resource_List' => 
    {
    'mem' => '500mb',
    'ncpus' => '4',
    'nodes' => '1:ppn=2',
    'walltime' => '00:25:00',
    },
'resources_used' => 
    {
    'cpupercent' => '0',
    'cput' => '00:00:00',
    'mem' => '2880kb',
    'ncpus' => '4',
    'vmem' => '6848kb',
    'walltime' => '00:00:00',
    },
'session' => '15040',
'start' => '1107284778',
'user' => 'gonwat  ',
}
};
my $h;
eval "\$h = $s";

my $pl = new PBS::Logs::Acct([]);

is_deeply($pl->message_hash($m),$h,		"object method");
is_deeply(PBS::Logs::Acct::message_hash($m),$h,	"full path function");
is_deeply(message_hash($m),$h,			"exported function");

is($pl->message_hash_dump($h),$s,		"object dump method");
is(PBS::Logs::Acct::message_hash_dump($h),$s,	"full path dump function");
is(message_hash_dump($h),$s,			"exported dump function");

