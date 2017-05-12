####!perl -T

use Test::More tests => 41;

use strict;
use warnings;
use File::Temp qw/tempfile/;
use YAML ();
use SIAM;
use SIAM::Driver::Simple;


my $yaml = <<EOT;
---
Driver:
  Class: SIAM::Driver::Simple
  Options:
    Datafile: t/driver-simple.data.yaml
Client:
  Test:
    x: 5
EOT

my $config = YAML::Load($yaml);
ok(ref($config)) or diag('Failed to read the configuration YAML');

note('loading SIAM');
ok( defined(my $siam = new SIAM($config)), 'load SIAM');

note('connecting the driver');
ok($siam->connect(), 'connect');

ok($siam->get_client_config('Test')->{'x'} == 5) or
    diag('Failed to retrieve client configuration');

my $component = $siam->instantiate_object('SIAM::ServiceComponent',
                                          'SRVC0002.01.u02.c01');
ok(defined($component), '$siam->instantiate_object');

### user: root
note('testing the root user');
my $user1 = $siam->get_user('root');
ok(defined($user1), 'get_user root');


note('checking that we retrieve all contracts');
my $all_contracts = $siam->get_all_contracts();
ok(scalar(@{$all_contracts}) == 2, 'get_all_contracts') or
    diag('Expected 2 contracts, got ' . scalar(@{$all_contracts}));


note('checking that root sees all contracts');
my $user1_contracts =
    $siam->get_contracts_by_user_privilege($user1, 'ViewContract');
ok(scalar(@{$all_contracts}) == scalar(@{$user1_contracts}),
   'get_contracts_by_user_privilege root') or
    diag('Expected ' . scalar(@{$all_contracts}) .
         ' contracts, got ' . scalar(@{$user1_contracts}));


### user: perpetualair
note('testing the user perpetualair');
my $user2 = $siam->get_user('perpetualair');
ok(defined($user1), 'get_user perpetualair');


note('checking that perpetualair sees only his contract');
my $user2_contracts =
    $siam->get_contracts_by_user_privilege($user2, 'ViewContract');
ok(scalar(@{$user2_contracts}) == 1,
   'get_contracts_by_user_privilege perpetualair') or
    diag('Expected 1 contract, got ' . scalar(@{$user2_contracts}));


my $x = $user2_contracts->[0]->attr('siam.object.id');
ok($x eq 'CTRT0001', 'get_contracts_by_user_privilege perpetualair') or
    diag('Expected siam.object.id: CTRT0001, got: ' . $x);



### user: zetamouse
note('testing the user zetamouse');
my $user3 = $siam->get_user('zetamouse');
ok(defined($user1), 'get_user zetamouse');


note('checking that zetamouse sees only his contract');
my $user3_contracts =
    $siam->get_contracts_by_user_privilege($user3, 'ViewContract');
ok(scalar(@{$user3_contracts}) == 1,
   'get_contracts_by_user_privilege zetamouse') or
    diag('Expected 1 contract, got ' . scalar(@{$user3_contracts}));


$x = $user3_contracts->[0]->attr('siam.object.id');
ok($x eq 'CTRT0002', 'get_contracts_by_user_privilege zetamouse') or
    diag('Expected siam.object.id: CTRT0002, got: ' . $x);


### Privileges
note('verifying privileges');
ok($user1->has_privilege('ViewContract', $user2_contracts->[0]) and
   $user1->has_privilege('ViewContract', $user3_contracts->[0]),
   'root->has_privilege') or
    diag('Root does not see a contract');

ok($user2->has_privilege('ViewContract', $user2_contracts->[0]) and
   $user3->has_privilege('ViewContract', $user3_contracts->[0]),
   'users see their contracts') or
    diag('one of users does not see his contract');

ok((not $user2->has_privilege('ViewContract', $user3_contracts->[0])),
   'perpetualair should not see contracts of zetamouse') or
    diag('perpetualair sees a contract of zetamouse');

ok((not $user3->has_privilege('ViewContract', $user2_contracts->[0])),
   'zetamouse should not see contracts of perpetualair') or
    diag('zetamouse sees a contract of perpetualair');



### Service units
note('testing the service units and data elements');

my $services = $user2_contracts->[0]->get_services();
ok((scalar(@{$services}) == 2), 'get_services') or
    diag('Expected 2 services for CTRT0001, got ' . scalar(@{$services}));

# find SRVC0001.01 for further testing
my $s;
foreach my $obj (@{$services})
{
    if( $obj->id() eq 'SRVC0001.01')
    {
        $s = $obj;
        last;
    }
}
ok(defined($s)) or diag('Expected to find Service SRVC0001.01');

my $units = $s->get_service_units();
ok((scalar(@{$units}) == 2), 'get_service_units') or
    diag('Expected 2 service units for SRVC0001.01, got ' .
         scalar(@{$units}));

# find SRVC0001.01.u01 for further testing
my $u;
foreach my $obj (@{$units})
{
    if( $obj->id() eq 'SRVC0001.01.u01' )
    {
        $u = $obj;
        last;
    }
}
ok(defined($u)) or diag('Expected to find Service Unit SRVC0001.01.u01');

my $components = $u->get_components();
ok(scalar(@{$components}) == 1, 'get_components') or
    diag('Expected 1 component for SRVC0001.01.u01, got ' .
         scalar(@{$components}));

### Devices and components

my $dev = $siam->get_device('ZUR8050AN33');
ok(defined($dev)) or diag('$siam->get_device(\'ZUR8050AN33\') returned undef');

my $dc = $dev->get_components();
ok((scalar(@{$dc}) == 2), '$dev->get_components()'), or
    diag('Expected 2 device components for ZUR8050AN33, got ' .
         scalar(@{$dc}));

### User privileges to see attributes
note('testing user privileges to see attributes');
my $filtered = $siam->filter_visible_attributes($user2, $u->attributes());

ok((not defined($filtered->{'xyz.serviceclass'}))) or
    diag('User perpetualair is not supposed to see xyz.serviceclass');

ok( defined($filtered->{'xyz.access.redundant'})) or
    diag('User perpetualair is supposed to see xyz.access.redundant');


### $object->contained_in()
note('testing $object->contained_in()');
my $x1 = $user2_contracts->[0]->contained_in();
ok(not defined($x1)) or
    diag('contained_in() did not return undef as expected');

my $x2 = $component->contained_in();
ok(defined($x2)) or diag('contained_in() returned undef');

ok($x2->objclass eq 'SIAM::ServiceUnit') or
    diag('contained_in() returned siam.object.class: ' . $x2->objclass);

ok($x2->id eq 'SRVC0002.01.u01') or
    diag('contained_in() returned siam.object.id: ' . $x2->id);


### siam.contract.content_md5hash
note('testing computable: siam.contract.content_md5hash');
my $md5sum =
    $user2_contracts->[0]->computable('siam.contract.content_md5hash');
ok(defined($md5sum) and $md5sum ne '') or
    diag('Computable siam.contract.content_md5hash ' .
         'returned undef or empty string');

my $expected_md5 = '2929c2392b8008ef6fd4666553c355b1';
ok($md5sum eq $expected_md5) or
    diag('Computable siam.contract.content_md5hash ' .
         'returned unexpected value: ' . $md5sum);

$siam->_driver->{'objects'}{'SRVC0001.02.u01.c01'}{'torrus.port.nodeid'} = 'xx';
delete $siam->_driver->{'computable_cache'}{'siam.contract.content_md5hash'};
ok($user2_contracts->[0]->computable('siam.contract.content_md5hash') ne
   $expected_md5) or
    diag('Computable siam.contract.content_md5hash did not ' .
         'change as expected');


### Reports
ok($user2_contracts->[0]->attr('siam.object.has_reports')) or
    diag('CTRT0001 does not have any reports');

my $reports = $user2_contracts->[0]->get_reports();
ok(scalar(@{$reports}) == 1) or diag('Cannot retrieve reports for CTRT0001');

my $report_data = $reports->[0]->get_items();
ok(scalar(@{$report_data}) == 2) or diag('expected 2 report items');

ok($report_data->[1]->{'siam.report.item'}->id() eq 'SRVC0001.02.u01.c01');


### Deep walk
my $walk_res =
    $user2_contracts->[0]->deep_walk_contained_objects('SIAM::ServiceUnit');
my $walk_count = scalar(@{$walk_res});
ok($walk_count == 3) or diag('deep_walk_contained_objects returned ' . 
                             $walk_count . ' objects, expected 3');

### clone_data
note('testing SIAM::Driver::Simple->clone_data');

my $filter = sub {
    my $obj = shift;
    if( $obj->objclass eq 'SIAM::Contract' )
    {
        if( $obj->id =~ /0002$/ )
        {
            return 1;
        }
        else
        {
            return 0;
        }
    }

    return 1;
};

my ($fh, $filename) = tempfile();
binmode($fh, ':utf8');
my $clone = SIAM::Driver::Simple->clone_data($siam, $filter);
print $fh YAML::Dump($clone);
$fh->close;

my $data = YAML::LoadFile($filename);
my $len = scalar(@{$data});
ok( $len == 20 ) or
    diag('clone_data is expected to produce array of size 20, got: ' . $len);

unlink $filename;

### manifest_attributes
note('testing $siam->manifest_attributes()');
my $manifest = $siam->manifest_attributes();
my $manifest_size = scalar(@{$manifest});
my $manifest_size_expected = 51;
ok($manifest_size == $manifest_size_expected) or
    diag('$siam->manifest_attributes() returned ' . $manifest_size .
         ', expected: ' . $manifest_size_expected);
# print STDERR "\n", join("\n", @{$manifest}), "\n";


# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-continued-statement-offset: 4
# cperl-continued-brace-offset: -4
# cperl-brace-offset: 0
# cperl-label-offset: -2
# End:

