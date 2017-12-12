#!/usr/bin/env perl
use strict;
use warnings;
use Net::Amazon::Route53;
use Test::More;
use Test::Exception;

# By Amiri Barksdale

my $access_key_id     = $ENV{AWS_ACCESS_KEY_ID};
my $secret_access_key = $ENV{AWS_SECRET_ACCESS_KEY};
my $test_domain       = $ENV{AWS_TEST_DOMAIN};
my $wants_testing     = $ENV{NET_AMAZON_ROUTE53_TESTING};

plan skip_all =>
    'Set AWS_SECRET_ACCESS_KEY, AWS_TEST_DOMAIN, AWS_SECRET_ACCESS_KEY and NET_AMAZON_ROUTE53_TESTING to test this'
    if !$wants_testing
    || !$access_key_id
    || !$secret_access_key
    || !$test_domain;

plan tests => 15;

$test_domain =~ s/\..+?$//g;
my $fq_test_domain = $test_domain . ".test.";
diag "################################################################
This test creates a hosted zone for $fq_test_domain,
creates/deletes records in it, and finally deletes the zone.
################################################################";

my $route53;
my $hosted_zone;

lives_ok {
    $route53 = Net::Amazon::Route53->new(
        id  => $access_key_id,
        key => $secret_access_key
    );
} "I can make a new Net::Amazon::Route53 object";
ok( defined($route53), "That object is defined" );

($hosted_zone) = $route53->get_hosted_zones($fq_test_domain);

if ( !$hosted_zone ) {
    $hosted_zone = Net::Amazon::Route53::HostedZone->new(
        route53         => $route53,
        name            => $fq_test_domain,
        callerreference => 'Route53TestDomain-'
            . int( rand(1_000_000_000_000_000) ),
        comment => 'Installing the perl module Net::Amazon::Route53'
    );
    my $change = $hosted_zone->create(1);
    if ( $change->status eq 'INSYNC' ) {
        is( $change->status, 'INSYNC', "I created a new hosted zone ".$hosted_zone->name );
        lives_ok {
            ($hosted_zone) = $route53->get_hosted_zones($fq_test_domain);
        }
        "I can get my newly created zone from the Route53 object";
    }
} else {
    my $current_records = $hosted_zone->resource_record_sets;
    if ( scalar(@$current_records) ) {
        my ($ns_record)  = grep { $_->type eq 'NS' } @$current_records;
        my ($soa_record) = grep { $_->type eq 'SOA' } @$current_records;
        my $first_delete_amount
            = @$current_records > 98 ? 98 : $#{$current_records};
        my @first_deletes  = @{$current_records}[ 0 .. $first_delete_amount ];
        my $first_deletion = $route53->atomic_update( \@first_deletes,
            [ $ns_record, $soa_record ], 1 );
        ok( $first_deletion->status =~ /INSYNC|NOOP/,
            "My first delete for cleanup of the zone was successful" );
        my $leftover_records = $hosted_zone->resource_record_sets;

        if ( @$leftover_records > 2 ) {
            my ($ns_record)  = grep { $_->type eq 'NS' } @$current_records;
            my ($soa_record) = grep { $_->type eq 'SOA' } @$current_records;
            my $second_deletion = $route53->atomic_update( $leftover_records,
                [ $ns_record, $soa_record ], 1 );
            ok( $second_deletion->status =~ /INSYNC|NOOP/,
                "My second delete for cleanup of the zone was successful" );
        }
    }
}

ok( defined($hosted_zone),
    "My hosted zone " . $hosted_zone->name . " is defined" );

my @records = map {
    my $number = sprintf( "%03d", $_ + 1 );
    Net::Amazon::Route53::ResourceRecordSet->new(
        route53    => $route53,
        hostedzone => $hosted_zone,
        name       => 'host-' . $number . '.' . $fq_test_domain,
        ttl        => 600,
        type       => 'CNAME',
        values => [ 'ec2-50-17-121-' . $number . '.compute-1.amazonaws.com' ],
        )
} ( 0 .. 100 );

is( scalar(@records), 101,
    "I have made 101 new Net::Amazon::Route53::ResourceRecordSet objects" );

my @first_100 = @records[ 0 .. 99 ];
my @last_one  = ( $records[100] );

my $first_creation = $route53->batch_create( \@first_100, 1 );
is( $first_creation->status, 'INSYNC',
    "I saved my first 100 records to Route53" );

my $second_creation = $route53->batch_create( \@last_one, 1 );
is( $second_creation->status, 'INSYNC',
    "I saved my last 1 record to Route53" );

my $new_route53;
lives_ok {
    $new_route53 = Net::Amazon::Route53->new(
        id  => $access_key_id,
        key => $secret_access_key
    );
}
"I can make a second Route53 object";

($hosted_zone) = $new_route53->get_hosted_zones($fq_test_domain);

ok( defined($hosted_zone),
    "And I can get my hosted zone " . $hosted_zone->name );
my $rrsets;
lives_ok { $rrsets = $hosted_zone->resource_record_sets }
"I can call the resource_record_sets method on my hosted zone";

is( scalar(@$rrsets), 103, "And I have 103 records in that set" );

($hosted_zone) = $new_route53->get_hosted_zones($fq_test_domain);
my ($ns_record)  = grep { $_->type eq 'NS' } @$rrsets;
my ($soa_record) = grep { $_->type eq 'SOA' } @$rrsets;
my $first_delete_amount = @$rrsets > 98 ? 98 : $#{$rrsets};
my @first_deletes = @{$rrsets}[ 0 .. $first_delete_amount ];
my $first_deletion
    = $route53->atomic_update( \@first_deletes, [ $ns_record, $soa_record ],
    1 );
ok( $first_deletion->status =~ /INSYNC|NOOP/,
    "My first delete for final cleanup of the zone was successful" );
my $leftover_records = $hosted_zone->resource_record_sets;

if ( @$leftover_records > 2 ) {
    my ($ns_record)  = grep { $_->type eq 'NS'  } @$rrsets;
    my ($soa_record) = grep { $_->type eq 'SOA' } @$rrsets;
    my $second_deletion = $route53->atomic_update( $leftover_records,
        [ $ns_record, $soa_record ], 1 );
    ok( $second_deletion->status =~ /INSYNC|NOOP/,
        "My second delete for final cleanup of the zone was successful" );
}
my $zone_deletion = $hosted_zone->delete(1);
is( $zone_deletion->status, 'INSYNC', "I can delete my zone finally" );
