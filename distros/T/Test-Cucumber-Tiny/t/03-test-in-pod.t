use strict;
use warnings;
use Test::More tests => 1;
use Test::Cucumber::Tiny;

subtest "Feature Test - Calculator" => sub {
    ## In order to avoid silly mistake
    ## As a math idiot
    ## I want to be told a sum of 2 numbers

    $ENV{CUCUMBER_VERBOSE} = "diag";

    Test::Cucumber::Tiny->Scenarios(
        {
            Scenario => "Add 2 numbers",
            Given    => [
                "first, I entered 50 into the calculator",
                "second, I entered 70 into the calculator",
            ],
            When => [ "I press add", ],
            Then => [ "The result should be 120 on the screen", ]
        },
        {
            Scenario => "Add numbers in examples",
            Given    => [
                "first, I entered <1st> into the calculator",
                "second, I entered <2nd> into the calculator",
            ],
            When     => [ "I press add", ],
            Then     => [ "The result should be <answer> on the screen", ],
            Examples => [
                {
                    '1st'  => 5,
                    '2nd'  => 6,
                    answer => 11,
                },
                {
                    '1st'  => 100,
                    '2nd'  => 200,
                    answer => 300,
                }
            ],
        },
        {
            Scenario => "Add numbers using data",
            Given    => [
                {
                    condition => "first, I entered number of",
                    data      => 45,
                },
                {
                    condition => "second, I entered number of",
                    data      => 77,
                }
            ],
            When => [ "I press add", ],
            Then => [
                {
                    condition => "The result is",
                    data      => 122,
                }
            ],
        }
      )

      ->Given(
        qr/^(.+),.+entered (\d+)/ => sub {
            my $c       = shift;
            my $subject = shift;
            my $key     = $1;
            my $num     = $2;
            $c->{$key} = $num;
            $c->Log( $subject );
        }
      )

      ->Given(
        qr/^(.+),.+entered number of/ => sub {
            my $c       = shift;
            my $subject = shift;
            my $key     = $1;
            $c->{$key} = $c->{data};
            $c->Log( $subject );
        }
      )

      ->When(
        qr/press add/ => sub {
            my $c       = shift;
            my $subject = shift;
            $c->Log( $subject );
            $c->{answer} = $c->{first} + $c->{second};
        }
      )

      ->Then(
        qr/result.+should be (\d+)/ => sub {
            my $c = shift;
            is $1, $c->{answer}, shift;
        }
      )

      ->Then(
        qr/result is/ => sub {
            my $c = shift;
            is $c->{data}, $c->{answer}, shift;
        }
      )

      ->Test;
};
