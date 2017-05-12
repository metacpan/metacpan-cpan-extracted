#!/usr/bin/perl

use strict;
use warnings;

use Digest::file qw(digest_file_hex);
use English qw(-no_match_vars);
use File::Temp qw(tempdir);
use List::MoreUtils qw(any none);
use Net::Nessus::REST;
use IO::Socket::SSL;

use Test::More;
use Test::Exception;

plan(skip_all => 'live test, set $ENV{NESSUS_TEST_URL} to a true value to run')
    if !$ENV{NESSUS_TEST_URL};
plan(skip_all => 'live test, set $ENV{NESSUS_TEST_USERNAME} to a true value to run')
    if !$ENV{NESSUS_TEST_USERNAME};
plan(skip_all => 'live test, set $ENV{NESSUS_TEST_PASSWORD} to a true value to run')
    if !$ENV{NESSUS_TEST_PASSWORD};

plan tests => 59;

my $nessus;
lives_ok {
    $nessus = Net::Nessus::REST->new(
        url => $ENV{NESSUS_TEST_URL},
        ssl_opts => {
            verify_hostname => 0,
            SSL_verify_mode => SSL_VERIFY_NONE
        }
    );
} 'connection succeeds';

isa_ok($nessus, 'Net::Nessus::REST');

lives_ok {
    $nessus->create_session(
        username => $ENV{NESSUS_TEST_USERNAME},
        password => $ENV{NESSUS_TEST_PASSWORD},
    );
} 'authentication succeeds';

BAIL_OUT('unable to connect, skipping remaining tests') if $EVAL_ERROR;

like(
    $nessus->{agent}->default_header('X-Cookie'),
    qr/^token=\S+/,
    'nessus handle has authentication token'
);

my @scanners;
lives_ok {
    @scanners = $nessus->list_scanners();
} 'scanners list retrieval succeeds';
ok(@scanners, 'scanners list is not empty');

my @policies;
lives_ok {
    @policies = $nessus->list_policies();
} 'policies list retrieval succeeds';

my @templates;
throws_ok {
    @templates = $nessus->list_templates();
} qr/^missing type parameter/, 
'templates list retrieval without type argument fails';

lives_ok {
    @templates = $nessus->list_templates(type => 'policy');
} 'templates list retrieval succeeds';

ok(@templates, 'templates list is not empty');

my $policy_template_id;
lives_ok {
    $policy_template_id = $nessus->get_template_id(
        name => 'discovery',
        type => 'policy'
    );
} 'policy ID retrieval succeeds';

ok(defined $policy_template_id, "policy ID is defined");

my @scans;
lives_ok {
    @scans = $nessus->list_scans();
} 'initial scan list retrieval succeeds';

my $initial_scan_count = scalar @scans;

# use a random scan name to ensure empty history
my @chars = ("A".."Z", "a".."z");
my $scan_name = 'test scan ' . join('' , map { $chars[rand @chars] } 1 .. 8);

my $scan;
lives_ok {
    $scan = $nessus->create_scan(
        uuid     => $policy_template_id,
        settings => {
            text_targets => '127.0.0.1',
            name         => $scan_name
        }
    );
} 'scan creation succeeds';

ok(ref $scan eq 'HASH', "scan handle is an hashref");

# first run

lives_ok {
    $nessus->launch_scan(scan_id => $scan->{id});
} 'scan first run launch succeeds';

while ($nessus->get_scan_status(scan_id => $scan->{id}) ne 'completed') {
    sleep 3;
}

lives_ok {
    @scans = $nessus->list_scans();
} 'new scan list retrieval succeeds';

ok(
    any(sub { $_->{name} eq $scan_name }, @scans),
    'the scan lists contains the new scan'
);

cmp_ok(
    scalar @scans,
    '==',
    $initial_scan_count + 1,
    'the scan list has one more element'
);

my $details;
throws_ok {
    $details = $nessus->get_scan_details();
} qr/^missing scan_id parameter/, 
'scan details retrieval without scan_id argument fails';

lives_ok {
    $details = $nessus->get_scan_details(scan_id => $scan->{id});
} 'scan details retrieval succeeds';

is(
    $details->{info}->{name},
    $scan_name,
    'scan details has expected scan name'
);
is(
    $details->{info}->{targets},
    '127.0.0.1',
    'scan details has expected scan target'
);
cmp_ok(
    scalar @{$details->{history}},
    '==',
    1,
    'scan history has one element'
);

lives_ok {
    $details = $nessus->get_scan_details(
        scan_id    => $scan->{id},
        history_id => $details->{history}->[0]->{history_id},
    );
} 'scan details retrieval for an exiting run succeeds';

throws_ok {
    $details = $nessus->get_scan_details(
        scan_id    => $scan->{id},
        history_id => $details->{history}->[0]->{history_id} + 1,
    );
} qr/^server error: The requested file was not found/,
'scan details retrieval for a non-existing run fails';

# second run

lives_ok {
    $nessus->launch_scan(scan_id => $scan->{id});
} 'scan second run launch succeeds';

while ($nessus->get_scan_status(scan_id => $scan->{id}) ne 'completed') {
    sleep 3;
}

lives_ok {
    $details = $nessus->get_scan_details(scan_id => $scan->{id});
} 'scan details retrieval succeeds';

cmp_ok(
    scalar @{$details->{history}},
    '==',
    2,
    'scan history has two elements'
);

# third run

lives_ok {
    $nessus->launch_scan(scan_id => $scan->{id});
} 'scan third run launch succeeds';

is($nessus->get_scan_status(scan_id => $scan->{id}), 'running', 'scan is running');

lives_ok {
    $nessus->stop_scan(scan_id => $scan->{id});
} 'scan stop succeeds';

is($nessus->get_scan_status(scan_id => $scan->{id}), 'stopping', 'scan is not running anymore');

while ($nessus->get_scan_status(scan_id => $scan->{id}) ne 'canceled') {
    sleep 3;
}

lives_ok {
    $details = $nessus->get_scan_details(scan_id => $scan->{id});
} 'scan details retrieval succeeds';

cmp_ok(
    scalar @{$details->{history}},
    '==',
    3,
    'scan history has three elements'
);

# history deletion

lives_ok {
    $nessus->delete_scan_history(
        scan_id    => $scan->{id},
        history_id => $details->{history}->[2]->{history_id},
    );
} 'last run deletion succeeds';

lives_ok {
    $details = $nessus->get_scan_details(scan_id => $scan->{id});
} 'scan details retrieval succeeds';

cmp_ok(
    scalar @{$details->{history}},
    '==',
    2,
    'scan history has two elements'
);

# first report: last run in history

my $dir = tempdir(CLEANUP => $ENV{TEST_DEBUG} ? 0 : 1);

my $file_id;
lives_ok {
    $file_id = $nessus->export_scan(
        scan_id  => $scan->{id},
        format   => 'nessus',
        chapters => 'vuln_hosts_summary'
    );
} 'report ID retrieval succeeds';

ok(defined $file_id, "first report ID is defined");

while ($nessus->get_scan_export_status(
        scan_id => $scan->{id},
        file_id => $file_id
    ) ne 'ready') {
    sleep 1;
}

my $report1 = "$dir/localhost1.nessus";
lives_ok {
    $nessus->download_scan(
        scan_id  => $scan->{id},
        file_id  => $file_id,
        filename => $report1,
    );
} 'first report download succeeds';

ok(-f $report1, 'first report file exists');

# second report: first run in history

lives_ok {
    $file_id = $nessus->export_scan(
        scan_id    => $scan->{id},
        history_id => $details->{history}->[0]->{history_id},
        format     => 'nessus',
        chapters   => 'vuln_hosts_summary'
    );
} 'second report ID retrieval succeeds';

ok(defined $file_id, "second report ID is defined");

while ($nessus->get_scan_export_status(
        scan_id => $scan->{id},
        file_id => $file_id
    ) ne 'ready') {
    sleep 1;
}

my $report2 = "$dir/localhost2.nessus";
lives_ok {
    $nessus->download_scan(
        scan_id  => $scan->{id},
        file_id  => $file_id,
        filename => $report2,
    );
} 'second report download succeeds';

ok(-f $report2, 'second report file exists');

isnt(
    digest_file_hex($report1, "MD5"), 
    digest_file_hex($report2, "MD5"), 
    "report for the same run are identical"
);

# third report: second run in history

lives_ok {
    $file_id = $nessus->export_scan(
        scan_id    => $scan->{id},
        history_id => $details->{history}->[1]->{history_id},
        format     => 'nessus',
        chapters   => 'vuln_hosts_summary'
    );
} 'third report ID retrieval succeeds';

ok(defined $file_id, "third report ID is defined");

while ($nessus->get_scan_export_status(
        scan_id => $scan->{id},
        file_id => $file_id
    ) ne 'ready') {
    sleep 1;
}

my $report3 = "$dir/localhost3.nessus";
lives_ok {
    $nessus->download_scan(
        scan_id  => $scan->{id},
        file_id  => $file_id,
        filename => $report3,
    );
} 'second report download succeeds';

ok(-f $report3, 'third report file exists');

is(
    digest_file_hex($report1, "MD5"), 
    digest_file_hex($report3, "MD5"), 
    "report for different runs are different"
);

lives_ok {
    $file_id = $nessus->delete_scan(
        scan_id => $scan->{id},
    );
} 'scan deletion succeeds';

throws_ok {
    $details = $nessus->get_scan_details(scan_id => $scan->{id});
} qr/^server error: The requested file was not found/,
'scan details retrieval fails';

lives_ok {
    @scans = $nessus->list_scans();
} 'new scan list retrieval succeeds';

ok(
    none(sub { $_->{name} eq $scan_name }, @scans),
    'the scan lists does not contain the new scan'
);

cmp_ok(
    scalar @scans,
    '==',
    $initial_scan_count,
    'the scan list has initial scan count'
);

# deconnection

lives_ok {
    $nessus->destroy_session()
} 'deconnection succeeds';

throws_ok {
    @policies = $nessus->list_policies();
} qr/^server error: Invalid Credentials/,
'policies list retrieval fails';

diag("report files directory: $dir") if $ENV{TEST_DEBUG};
