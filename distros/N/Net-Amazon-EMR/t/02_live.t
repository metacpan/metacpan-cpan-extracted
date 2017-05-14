use strict;
use lib 'lib', '../lib';
use Test::More;
use Log::Log4perl qw/:easy/;
use Exception::Class;
use Data::Dumper;

BEGIN { 
    if (! $ENV{AWS_ACCESS_KEY_ID} || ! $ENV{AWS_ACCESS_KEY_SECRET} ) {
        plan skip_all => "Set AWS_ACCESS_KEY_ID and AWS_ACCESS_KEY_SECRET environment variables to run these _LIVE_ tests (NOTE: they may incur costs on EMR)";
    }
    else {
        Log::Log4perl->easy_init($ERROR);
        plan tests => 15;
        use_ok( 'Net::Amazon::EMR' );
    }
};


#try ssl first
my $emr = eval {
    Net::Amazon::EMR->new(
	AWSAccessKeyId  => $ENV{AWS_ACCESS_KEY_ID},
	SecretAccessKey => $ENV{AWS_ACCESS_KEY_SECRET},
	ssl             => 1,
    );
};

$emr = Net::Amazon::EMR->new(
	AWSAccessKeyId  => $ENV{AWS_ACCESS_KEY_ID},
	SecretAccessKey => $ENV{AWS_ACCESS_KEY_SECRET},
) if $@;

isa_ok($emr, 'Net::Amazon::EMR');

my $id = $emr->run_job_flow(Name => "API Test Job",
                            AmiVersion => '2.2.4',
                            Instances => {
                                Ec2KeyName => 'panda1',
                                InstanceCount => 2,
                                KeepJobFlowAliveWhenNoSteps => 1,
                                MasterInstanceType => 'm1.small',
                                Placement => { AvailabilityZone => 'us-east-1d' },
                                SlaveInstanceType => 'm1.small',
                            },
    );

isa_ok($id, 'Net::Amazon::EMR::RunJobFlowResult', 'run_job_flow type');
#print "Job flow id = ". Dumper($id);

#my $result = $emr->describe_job_flows(CreatedAfter => DateTime->new(year => 2012, month => 12, day => 17));
my $result = $emr->describe_job_flows(JobFlowIds => [ $id->JobFlowId ]);

isa_ok($result, 'Net::Amazon::EMR::DescribeJobFlowsResult', 'describe_job_flows type');
ok(@{$result->JobFlows} == 1, "describe_job_flows count");
ok($result->JobFlows->[0]->Instances->InstanceCount == 2, "run_job_flow 2 instances");

my $igs = $emr->add_instance_groups(JobFlowId => $id->JobFlowId,
                                    InstanceGroups => [
                                        { InstanceCount => 1,
                                          InstanceRole => 'TASK',
                                          InstanceType => 'm1.small',
                                          Market => 'ON_DEMAND',
                                          Name => 'API Test Group',
                                        }]);
isa_ok($igs, 'Net::Amazon::EMR::AddInstanceGroupsResult', 'add_instance_groups type');

$result = $emr->describe_job_flows(JobFlowIds => [ $id->JobFlowId ]);
ok($result->JobFlows->[0]->Instances->InstanceCount == 3, "add_instance_group 3 instances");

# Expect an error - instance group may not be modified while in startup
eval {
    $emr->modify_instance_groups(InstanceGroups => [
                                     { InstanceGroupId => $result->JobFlows->[0]->Instances->InstanceGroups->[2]->InstanceGroupId,
                                       InstanceCount => 2,
                                     }]);
};
my $e = Exception::Class->caught('Net::Amazon::EMR::Exception');
ok($e && $e->message eq 'An instance group may only be modified when the job flow is running or waiting', 'modify_instance_groups (expecting an ERROR)');


ok($emr->set_visible_to_all_users(JobFlowIds => [ $id->JobFlowId ],
                                    VisibleToAllUsers => 0,
   ), "set_visible_to_all_users");
ok($emr->set_termination_protection(JobFlowIds => [ $id->JobFlowId ],
                                    TerminationProtected => 'false',
   ), "set_termination_protection");


#use Data::Dumper; print Dumper($result);
#print STDERR Dumper($result->as_hash);

ok($emr->add_job_flow_steps(JobFlowId => $id->JobFlowId,
                            Steps => [ 
                                { ActionOnFailure => 'CONTINUE',
                                  HadoopJarStep => { Jar => 'MyJar',
                                                     MainClass => 'MainClass',
                                                     Args => [ 'arg1' ] },
                                  Name => 'TestStep',
                                }
                            ]), 'add_job_flow_steps');

                   
ok($emr->terminate_job_flows(JobFlowIds => [ $id->JobFlowId ]), "terminate_job_flow");

$result = $emr->describe_job_flows(JobFlowIds => [ $id->JobFlowId ]);
#print STDERR "VTAU: " . $result->JobFlows->[0]->VisibleToAllUsers . "\n";
ok(! $result->JobFlows->[0]->VisibleToAllUsers, "set_visible_to_all_users value");
ok(! $result->JobFlows->[0]->Instances->TerminationProtected, "set_termination_protection value");



