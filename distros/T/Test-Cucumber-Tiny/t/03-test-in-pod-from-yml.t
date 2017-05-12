use strict;
use warnings;
use Test::More tests => 8;
use Test::Cucumber::Tiny;

$ENV{CUCUMBER_VERBOSE} = "diag";

## subtest "Feature Test - Calculator" => sub {
## In order to avoid silly mistake
## As a math idiot
## I want to be told a sum of 2 numbers

eval { Test::Cucumber::Tiny->ScenariosFromYML };

like $@, qr/Missing YAML file/, "Detect missing file argument";

eval { Test::Cucumber::Tiny->ScenariosFromYML("t/example_yml/foobar.yml") };

like $@, qr/YAML file is not found/, "Detect invalid file path";

eval { Test::Cucumber::Tiny->ScenariosFromYML("t/example_yml/empty.yml") };

like $@, qr/YAML file has no scenarios/, "Detect missing scenarios in yml file";

eval { Test::Cucumber::Tiny->ScenariosFromYML("t/example_yml/hashref.yml") };

like $@, qr/expecting array/, "Detect invalid data format in the yml file";

Test::Cucumber::Tiny->

  ScenariosFromYML("t/example_yml/test-in-pod-add-2-num.yml")->

  ScenariosFromYML("t/example_yml/test-in-pod-use-data.yml")->

  Given(
    qr/^(.+),.+entered (\d+)/,
    sub {
        my $c = shift;
        $c->Log(shift);
        $c->{$1} = $2;
    }
  )->

  Given(
    qr/^(.+),.+entered number of/,
    sub {
        my $c = shift;
        $c->Log(shift);
        $c->{$1} = $c->{data},;
    }
  )->

  When(
    qr/press add/,
    sub {
        my $c = shift;
        $c->Log(shift);
        $c->{answer} = $c->{first} + $c->{second};
    }
  )->

  When(
    qr/press subtract/,
    sub {
        my $c = shift;
        $c->Log(shift);
        $c->{answer} = $c->{first} - $c->{second};
    }
  )->

  Then(
    qr/result.+should be (\d+)/,
    sub {
        my $c = shift;
        is $1, $c->{answer}, shift;
    }
  )->

  Then(
    qr/result is/,
    sub {
        my $c = shift;
        is $c->{data}, $c->{answer}, shift;
    }
  )->

  Test;

## };
