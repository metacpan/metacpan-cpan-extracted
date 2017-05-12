#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dump qw( dump );
use Test::More qw( no_plan );
require_ok( 'Net::FreshBooks::API::InvoiceLine' );

my $line = Net::FreshBooks::API::InvoiceLine->new;

foreach my $method ( sort keys %{ $line->_fields() } ) {
    can_ok( $line, $method );
}

isa_ok( $line, 'Net::FreshBooks::API::InvoiceLine', );

diag( $line->node_name );
