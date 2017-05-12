#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More;

use Search::Z3950;
use YAML;

sub test {
    my ($svc_abbrev) = @_;
    my $services = YAML::LoadFile('services.yml');
    my ($service) = grep { $_->{'abbrev'} eq $svc_abbrev } @$services;
    
    die "Bad service abbreviation provided"
        unless defined $service;
    
    my $z = Search::Z3950->new(%$service, 'delay' => 0.5);
    
    unless (defined $z) {
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
                    ok( $rs->record(1), 'first matching record' );
                }
            }
        };
        my $err = $@;
        
        eval { $z->disconnect };
        is( $@, '', 'disconnect' );
        
        die $err if $err;
    }
}


1;

