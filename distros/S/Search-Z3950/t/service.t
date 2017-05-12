#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More;

use Search::Z3950;
use YAML;

$| = 1;

my $services_file = 'services.yml';

my $service = load_service();

plan 'skip_all' => 'user cancelled live testing'
    unless defined $service;

my $z = Search::Z3950->new(%$service, 'delay' => 0.5);

if (defined $z) {
    plan 'no_plan';
    fail( "can't instantiate Search::Z3950 client" );
} else {
    my $searches = $service->{'searches'};
    plan 'tests' => 1 + 2 * scalar(@$searches) + 1;
    isa_ok( $z, 'Search::Z3950' );
    eval {
        foreach my $search (@$searches) {
            SKIP: {
                my $rs = $z->search($search->{'type'} => $search->{'string'});
                skip( "no matches", 1 )
                    unless cmp_ok( $rs->count, '>', 0, $search->{'name'} );
                ok( $rs->record(1), 'fetch first match' );
            }
        }
    };
    my $err = $@;
    
    eval { $z->disconnect };
    is( $@, '', 'disconnect' );
    
    die $err if $err;
}

# ------------------------------------------------------------------------------

sub load_service {
    my $services;
    eval { $services = YAML::LoadFile($services_file) };
    return undef unless defined $services;
    if (-t STDIN) {
        diag "Z29.50 services available for testing:\n";
        my $i = 1;
        foreach (@$services) {
            diag "  [$i] $_->{'name'} ($_->{'databaseName'}) - $_->{'location'}\n";
            $i++;
        }
        while (1) {
            # Running interactively
            diag "Please choose a service on which to run tests: [1] ";
            my $k = <STDIN>;
            return undef unless defined $k;
            chomp $k;
            return $services->[0] if $k eq '';
            return $services->[$i-1]
                if $k >= 1 and $k <= scalar @$services;
        }
    }
    return $services->[0];
}



