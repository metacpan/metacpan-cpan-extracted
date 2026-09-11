#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use OpenStack::MetaAPI::Helpers::DataAsYaml;

# Verify all spec classes load and have valid data for their declared types.
# A getfromid type MUST have a uid field; a listable type MUST have a listable_key.
# This catches regressions like missing uid in Compute v2_0 specs.

my @spec_classes = qw(
    OpenStack::MetaAPI::API::Specs::Compute::v2_0
    OpenStack::MetaAPI::API::Specs::Compute::v2_1
    OpenStack::MetaAPI::API::Specs::Network::v2
);

for my $class (@spec_classes) {
    subtest "specs integrity: $class" => sub {
        (my $file = $class) =~ s{::}{/}g;
        $file .= '.pm';
        eval { require $file; 1 } or do {
            fail "Failed to load $class: $@";
            return;
        };

        my $obj = $class->new;
        ok $obj, "instantiated $class";

        my $specs = $obj->specs;
        ok ref $specs eq 'HASH', "specs returns a hashref";

        for my $method (sort keys %$specs) {
            next unless ref $specs->{$method} eq 'HASH';
            for my $route (sort keys %{$specs->{$method}}) {
                my $rule = $specs->{$method}->{$route};
                next unless ref $rule && ref $rule->{perl_api};

                my $api  = $rule->{perl_api};
                my $label = "$method $route ($api->{method})";

                ok defined $api->{method}, "$label has method";
                ok defined $api->{type},   "$label has type";

                if ($api->{type} eq 'getfromid') {
                    ok defined $api->{uid},
                      "$label: getfromid type has uid field";
                } elsif ($api->{type} eq 'listable') {
                    ok defined $api->{listable_key},
                      "$label: listable type has listable_key field";
                }
            }
        }
    };
}

done_testing;
