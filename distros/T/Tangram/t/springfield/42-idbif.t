#!/usr/bin/perl -w

use strict;
use Test::More tests => 32;

use lib "t/springfield";
use Springfield;

for my $fairy ("FaerieHairy", "Faerie") {

#---------------------------------------------------------------------
# Test simple insertion of an explicitly listed field.
{
    my $storage = Springfield::connect_empty();

    my $bert = new $fairy( name => "Bert" );
    my $bob  = new $fairy( name => "Bob"  );
    $bert->{friends} = [ "Jesus" # everyone's friend
		       ];
    $bob->{friends} = { first => "Buddha" };
    $bob->{foo} = "bar";

    $storage->insert($bert, $bob);

    ok($storage->id($bert), "Bert got an ID ($fairy)");
    ok($storage->id($bob), "Bob got an ID ($fairy)");
}

is(leaked, 0, "leaktest");

# test update of an explicitly listed field, that contains a reference
# to another object.
{
    my $storage = Springfield::connect();
    my $pixie = $storage->remote($fairy);

    my ($bert) = $storage->select($pixie, $pixie->{name} eq "Bert");
    ok($bert, "Fetched Bert by name");
    is($bert->{friends}->[0], "Jesus", "Jesus still Bert's friend");

    my ($bob) = $storage->select($pixie, $pixie->{name} eq "Bob");
    ok($bob, "Fetched Bob by name");
    is($bob->{friends}->{first}, "Buddha",
       "The Buddha still on Bob's side");
    is($bob->{foo},
	 (($fairy eq "Faerie") ? "bar" : undef),
	 "Unknown attribute saved appropriately");

    push @{ $bert->{friends} }, $bob;
    $bob->{friends}->{second} = $bert;

    #local($Tangram::TRACE)=\*STDERR;
    $storage->update($bert, $bob);

    delete $bert->{friends};  # break cyclic reference...
}

is(leaked, 0, "leaktest");

# test that the above worked.
{
    my $storage = Springfield::connect();
    my $pixie = $storage->remote($fairy);

    my ($bert) = $storage->select($pixie, $pixie->{name} eq "Bert");
    ok($bert, "Fetched Bert by name");
    ok($bert->{friends}->[1], "Bert has another friend now");
    is($bert->{friends}->[1]->{name}, "Bob", "Bert's other friend is Bob");

    my ($bob) = $storage->select($pixie, $pixie->{name} eq "Bob");
    ok($bob, "Fetched Bob by name");
    ok($bob->{friends}->{second}, "Bob's has another friend now");
    is($bob->{friends}->{second}, $bert, "Bob's other friend is Bert");

    $storage->update($bert, $bob);

    delete $bert->{friends};  # break cyclic reference...
}

is(leaked, 0, "leaktest");

}
