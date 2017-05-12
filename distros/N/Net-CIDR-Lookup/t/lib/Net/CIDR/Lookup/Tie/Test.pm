package Net::CIDR::Lookup::Tie::Test;

use strict;
use warnings;

use base 'Test::Class';
use Test::More;
use Net::CIDR::Lookup::Tie;

sub check_tie : Test(startup => 1) {
    tie my %t, 'Net::CIDR::Lookup::Tie';
    ok((tied %t)->isa('Net::CIDR::Lookup::Tie'));
}

sub before : Test(setup) {
    my $self = shift;
    $self->{tree} = {};
	 tie %{$self->{tree}}, 'Net::CIDR::Lookup::Tie';
}

sub add : Tests(2) {
    my $self = shift;
    my $t = $self->{tree};
    $t->{'192.168.0.129/25'} = 42;
    $t->{'1.2.0.0/15'}       = 23;
    is($t->{'192.168.0.161'}, 42, "Block 192.168.0.129/25");
    is($t->{'1.3.123.234'},   23, "Block 1.2.0.0/15");
}

sub merger : Test {
    my $self = shift;
    my $t = $self->{tree};
    $t->{'192.168.0.128/25'} = 42;
    $t->{'192.168.0.0/25'}   = 42;
    is($t->{'192.168.0.23'}, 42, "Merged block");
}

1;

