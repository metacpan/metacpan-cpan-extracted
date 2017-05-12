#!/usr/bin/perl;

use strict;
use warnings;

package POW;

use Object::New;

sub init {
    my $self = shift;
    my ($name, $rank, $serial_number) = @_;
    $self->set_name($name);
    $self->set_rank($rank);
    $self->set_serial_number($serial_number);
}

my %fields = (name => undef, rank => undef, serial_number => undef);
sub AUTOLOAD {
    my $self = shift;
    my $method = our $AUTOLOAD;
    $method =~ s/.*://;
    return if ($method eq 'DESTROY');
    if (exists $fields{$method}) {
        return $fields{$method};
    }
    if ($method =~ /^set_/) {
        die "No value supplied" unless (@_);
        my $attr = substr($method, 4);
        if (exists $fields{$attr}) {
            return $fields{$attr} = shift;
        }
    }
    die "no method '$method' in class '" . ref($self) . "'";
}


sub interrogate {
    my $self = shift;
    return join(", ", $self->name, $self->rank, $self->serial_number) . "\n";
}

package main;

use Test::More tests => 6;

my $pow = POW->new("John", "Lt.", 127432);

isa_ok($pow, "POW");

is($pow->name, "John", "Getting name");
is($pow->rank, "Lt.", "Getting rank");
is($pow->serial_number, "127432", "Getting serial no");

can_ok($pow, "interrogate");

is($pow->interrogate(), "John, Lt., 127432\n", "Replies correctly");
