#!/usr/bin/env perl

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;

use OpenStack::MetaAPI::Helpers::DataAsYaml;

# Validate that spec field names match the official OpenStack API documentation.
# This test catches typos like 'prokect_id' instead of 'project_id'.

# Known valid query parameter names per OpenStack service.
# These are the canonical field names from the OpenStack API reference.
my %KNOWN_FIELDS = (
    'OpenStack::MetaAPI::API::Specs::Network::v2' => {
        '/v2.0/ports' => [qw(
            admin_state_up binding:host_id description device_id device_owner
            fixed_ips id ip_allocation mac_address name network_id project_id
            revision_number sort_dir sort_key status tenant_id tags tags-any
            not-tags not-tags-any fields mac_learning_enabled
        )],
    },
    'OpenStack::MetaAPI::API::Specs::Compute::v2_1' => {
        '/servers' => [qw(host flavor hostname image ip)],
        '/flavors' => [qw(sort_key sort_dir limit marker minDisk minRam isPublic)],
        '/os-keypairs' => [qw(user_id limit marker)],
    },
    'OpenStack::MetaAPI::API::Specs::Compute::v2_0' => {
        '/servers' => [qw(host flavor hostname image ip)],
        '/flavors' => [qw(sort_key sort_dir limit marker minDisk minRam isPublic)],
        '/os-keypairs' => [qw(user_id limit marker)],
    },
);

for my $pkg (sort keys %KNOWN_FIELDS) {
    subtest "Spec fields for $pkg" => sub {
        eval "require $pkg; 1" or do {
            fail "Cannot load $pkg: $@";
            return;
        };

        my $spec_obj = $pkg->new();
        my $specs    = $spec_obj->specs;

        for my $route (sort keys %{$KNOWN_FIELDS{$pkg}}) {
            my $expected = $KNOWN_FIELDS{$pkg}->{$route};

            my $route_spec = $specs->{get}{$route};
            ok $route_spec, "$route exists in specs"
              or next;

            my $query = $route_spec->{request}{query};
            ok $query, "$route has query parameters"
              or next;

            my @actual = sort keys %$query;
            is \@actual, [sort @$expected],
              "$route query params match expected fields";
        }
    };
}

# Verify no obvious typos: field names should not contain common misspellings
subtest "No misspelled field names" => sub {
    my %typo_patterns = (
        'prokect' => 'project',
        'desciption' => 'description',
        'stauts' => 'status',
        'netowrk' => 'network',
    );

    for my $pkg (sort keys %KNOWN_FIELDS) {
        eval "require $pkg; 1" or next;
        my $spec_obj = $pkg->new();
        my $specs    = $spec_obj->specs;

        for my $method (sort keys %$specs) {
            next unless ref $specs->{$method} eq 'HASH';
            for my $route (sort keys %{$specs->{$method}}) {
                my $rule = $specs->{$method}{$route};
                next unless ref $rule eq 'HASH'
                    && ref $rule->{request}
                    && ref $rule->{request}{query};

                my @fields = keys %{$rule->{request}{query}};
                for my $field (@fields) {
                    for my $typo (sort keys %typo_patterns) {
                        unlike $field, qr/\Q$typo\E/i,
                          "$pkg $route: '$field' does not contain typo '$typo'";
                    }
                }
            }
        }
    }
};

done_testing;
