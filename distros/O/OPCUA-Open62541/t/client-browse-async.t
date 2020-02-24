use strict;
use warnings;
use OPCUA::Open62541 ':all';
use POSIX qw(sigaction SIGALRM);

use Net::EmptyPort qw(empty_port);
use Scalar::Util qw(looks_like_number);
use Test::More tests => 35;
use Test::NoWarnings;
use Test::LeakTrace;

# initialize the server

my $s = OPCUA::Open62541::Server->new();
ok($s, "server");

my $sc = $s->getConfig();
ok($s, "config server");

my $port = empty_port();
my $r = $sc->setMinimal($port, "");
is($r, STATUSCODE_GOOD, "minimal server config");

my $pid = fork // die "Unable to fork: $!\n";

if ( !$pid ) {
    my $running = 1;
    sub handler {
	$running = 0;
    }

    # Perl signal handler only works between perl statements.
    # Use the real signal handler to interrupt the OPC UA server.
    # This is not signal safe, best effort is good enough for a test.
    my $sigact = POSIX::SigAction->new(\&handler)
	or die "could not create POSIX::SigAction";
    sigaction(SIGALRM, $sigact)
	or die "sigaction failed: $!";
    alarm(1)
	// die "alarm failed: $!";

    # run server and stop after one second
    $s->run($running);

    POSIX::_exit 0;
}

my @testdesc = (
    ['client', 'client creation'],
    ['config', 'config creation'],
    ['config_default', 'set default config'],
    ['connect_async', 'call to connect_async'],
    ['iterate', 'calls to run_iterate'],
    ['state_session', 'client state SESSION after connect'],
    ['iterate2', 'calls to second run_iterate'],
    ['browse_data', 'data in browseresponse callback'],
    ['browse_code', 'statuscode of browseresult'],
    ['browse_result_count', 'number of results'],
    ['browse_refs_count', 'number of references'],
    ['browse_refs_foldertype', 'foldertype reference'],
    ['browse_refs_objects_displayname', 'objects reference displayname'],
    ['browse_refs_objects_browsename', 'objects reference browsename'],
    ['browse_refs_types', 'types reference'],
    ['browse_refs_views', 'views reference'],
    ['iterate3', 'calls to third run_iterate'],
    ['browse2_code', 'statuscode of seconds browseresult'],
    ['browse2_result_count', 'number of second results'],
    ['browse2_refs_count', 'number of second references'],
    ['browse2_refs_objects_displayname', 'second objects reference displayname'],
    ['browse2_refs_objects_browsename', 'second objects reference browsename'],
    ['disconnect', 'client disconnected'],
    ['state_disconnected', 'client state DISCONNECTED after disconnect'],
    ['reqid_ref', 'request reference contains a number'],
    ['reqid_sub', 'request reference is the same as request in callback'],
    ['response1', 'first response result is good'],
    ['response2', 'seconnd response result is good'],
);
my %testok = map { $_ => 0 } map { $_->[0] } @testdesc;

no_leaks_ok {
    my $c;
    my $data = ['foo'];
    my $reqid;
    {
	$c = OPCUA::Open62541::Client->new();
	$testok{client} = 1 if $c;

	my $cc = $c->getConfig();
	$testok{config} = 1 if $cc;

	$r = $cc->setDefault();
	$testok{config_default} = 1 if $r == STATUSCODE_GOOD;

	$r = $c->connect_async("opc.tcp://localhost:$port", undef, undef);
	$testok{connect_async} = 1 if $r == STATUSCODE_GOOD;

	my $maxloop = 1000;
	my $failed_iterate = 0;
	while($c->getState != CLIENTSTATE_SESSION && $maxloop-- > 0) {
	    $r = $c->run_iterate(0);
	    $failed_iterate = 1 if $r != STATUSCODE_GOOD;
	}
	$testok{iterate} = 1 if not $failed_iterate and $maxloop > 0;

	$testok{state_session} = 1 if $c->getState == CLIENTSTATE_SESSION;

	my $browsed = 0;
	$c->sendAsyncBrowseRequest(
	    {
		BrowseRequest_requestedMaxReferencesPerNode => 0,
		BrowseRequest_nodesToBrowse => [
		    {
			BrowseDescription_nodeId => {
			    NodeId_namespaceIndex => 0,
			    NodeId_identifierType => 0,
			    NodeId_identifier => 84,		# UA_NS0ID_ROOTFOLDER
			},
			BrowseDescription_resultMask => BROWSERESULTMASK_ALL,
		    }
		],
	    },
	    sub {
		my ($c, $d, $i, $r) = @_;
		$testok{response1} = 1 if $r->{BrowseResponse_results}[0] &&
		    $r->{BrowseResponse_results}[0]{BrowseResult_statusCode} eq
		    'Good';
		$testok{reqid_sub} = 1 if $reqid == $i;
		$browsed = 1;
		push(@$data, $d, $i, $r);
	    },
	    "test",
	    \$reqid,
	);

	$testok{reqid_ref} = 1 if $reqid =~ qr/^\d+$/;

	$maxloop = 1000;
	$failed_iterate = 0;
	while(not $browsed && $maxloop-- > 0) {
	    $r = $c->run_iterate(0);
	    $failed_iterate = 1 if $r != STATUSCODE_GOOD;
	}
	$testok{iterate2} = 1 if not $failed_iterate and $maxloop > 0;

	$testok{browse_data} = 1 if $data->[1] eq "test";

	my $result_code = $data->[3]{BrowseResponse_responseHeader}{ResponseHeader_serviceResult};
	$testok{browse_code} = 1 if $result_code == STATUSCODE_GOOD;

	my $results = $data->[3]{BrowseResponse_results};
	$testok{browse_result_count} = 1 if @$results == 1;
	my $refs = $results->[0]{BrowseResult_references};
	$testok{browse_refs_count} = 1 if @$refs == 4;

	$testok{browse_refs_foldertype} = 1
	    if $refs->[0]{ReferenceDescription_displayName}{text} eq 'FolderType';
	$testok{browse_refs_objects_displayname} = 1
	    if $refs->[1]{ReferenceDescription_displayName}{text} eq 'Objects';
	$testok{browse_refs_objects_browsename} = 1
	    if $refs->[1]{ReferenceDescription_browseName}{name} eq 'Objects';
	$testok{browse_refs_types} = 1
	    if $refs->[2]{ReferenceDescription_displayName}{text} eq 'Types';
	$testok{browse_refs_views} = 1
	    if $refs->[3]{ReferenceDescription_displayName}{text} eq 'Views';

	# make a request for only browse names
	$c->sendAsyncBrowseRequest(
	    {
		BrowseRequest_requestedMaxReferencesPerNode => 0,
		BrowseRequest_nodesToBrowse => [
		    {
			BrowseDescription_nodeId => {
			    NodeId_namespaceIndex => 0,
			    NodeId_identifierType => 0,
			    NodeId_identifier => 84,		# UA_NS0ID_ROOTFOLDER
			},
			BrowseDescription_resultMask => BROWSERESULTMASK_BROWSENAME,
		    }
		],
	    },
	    sub {
		my ($c, $d, $i, $r) = @_;
		$testok{response2} = 1 if $r->{BrowseResponse_results}[0] &&
		    $r->{BrowseResponse_results}[0]{BrowseResult_statusCode} eq
		    'Good';
		$browsed = 1;
		push(@$data, $d, $i, $r);
	    },
	    "test",
	    undef,
	);

	$maxloop = 1000;
	$failed_iterate = 0;
	$browsed = 0;
	while(not $browsed && $maxloop-- > 0) {
	    $r = $c->run_iterate(0);
	    $failed_iterate = 1 if $r != STATUSCODE_GOOD;
	}
	$testok{iterate3} = 1 if not $failed_iterate and $maxloop > 0;

	my $result2_code = $data->[6]{BrowseResponse_responseHeader}{ResponseHeader_serviceResult};
	$testok{browse2_code} = 1 if $result2_code == STATUSCODE_GOOD;

	my $results2 = $data->[6]{BrowseResponse_results};
	$testok{browse2_result_count} = 1 if @$results2 == 1;
	my $refs2 = $results2->[0]{BrowseResult_references};
	$testok{browse2_refs_count} = 1 if @$refs2 == 4;

	$testok{browse2_refs_objects_displayname} = 1
	    if not defined $refs2->[1]{ReferenceDescription_displayName}{text};
	$testok{browse2_refs_objects_browsename} = 1
	    if $refs2->[1]{ReferenceDescription_browseName}{name} eq 'Objects';

	$r = $c->disconnect();
	$testok{disconnect} = 1 if $r == STATUSCODE_GOOD;
	$testok{state_disconnected} = 1
	    if $c->getState == CLIENTSTATE_DISCONNECTED;
    }
} "leak browse_service callback/data";

ok(delete($testok{$_->[0]}), $_->[1]) for (@testdesc);

is(keys %testok, 0, "no remaining tests");

waitpid $pid, 0;

is($?, 0, "server finished");
