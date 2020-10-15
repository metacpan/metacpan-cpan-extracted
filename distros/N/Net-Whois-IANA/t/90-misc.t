#!/bin/env perl

use strict;
use warnings;

use Test2::V0;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Net::Whois::IANA;

use Test::MockModule;

my @args_cidrlookup;
my $cidrlookup_answer;

my $mocked_cidr = Test::MockModule->new('Net::CIDR')    # .
  ->redefine(
    cidrlookup => sub {
        @args_cidrlookup = @_;
        note "mocked: cidrlookup : ", join( ', ', @args_cidrlookup ), " => ", $cidrlookup_answer;
        return $cidrlookup_answer;
    }
  );

my $iana = Net::Whois::IANA->new;
my $ip   = '193.0.0.135';
$iana->whois_query( -ip => $ip );

$cidrlookup_answer = 1;
ok( $iana->is_mine('193.0.1.1') );
is \@args_cidrlookup, [qw{193.0.1.1 193.0.0.0/21}], "cidrlookup called with expected args";

$cidrlookup_answer = 0;
ok( !$iana->is_mine('193.0.8.1') );
is \@args_cidrlookup, [qw{193.0.8.1 193.0.0.0/21}], "cidrlookup called with expected args";

$cidrlookup_answer = 1;
ok( $iana->is_mine( '193.0.1.1', "193.0.1.0/25" ) );
is \@args_cidrlookup, [qw{193.0.1.1 193.0.1.0/25}], "cidrlookup called with expected args";

$cidrlookup_answer = 0;
ok( !$iana->is_mine( '193.0.1.1', "193.0.1.128/25" ) );
is \@args_cidrlookup, [qw{193.0.1.1 193.0.1.128/25}], "cidrlookup called with expected args";

done_testing;
