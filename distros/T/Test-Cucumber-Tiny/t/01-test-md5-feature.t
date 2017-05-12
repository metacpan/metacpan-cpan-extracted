use strict;
use warnings;
use Test::More tests => 1;
use Test::Cucumber::Tiny;

use Digest;

$ENV{CUCUMBER_VERBOSE} = "diag";

subtest "Simple tests of Digest.pm" => sub {
    ## As a developer planning to use Digest.pm
    ## I want to test the basic functionality of Digest.pm
    ## In order to have confidence in it

    ## Background: {Given a usable Digest class

    my @scenarios = (
        {
            Scenario => "Check MD5",
            Given    => "a Digest MD5 object",
            When     => [
                q{I've added "foo bar baz" to the object},
                q{I've added "bat ban shan" to the object},
            ],
            Then => [
                q{the hex output is "bcb56b3dd4674d5d7459c95e4c8a41d5"},
                q{Then the base64 output is "1B2M2Y8AsgTpgAmY7PhCfg"},
            ]
        },
        {
            Scenario => "Check SHA-1",
            Given    => "a Digest SHA-1 object",
            When     => [q{I've added "<data>" to the object}],
            Then     => [q{the hex output is "<output>"}],
            Examples => [
                {
                    data   => "foo",
                    output => "0beec7b5ea3f0fdbc95d0dd47f3c5bc275da8a33",
                },
                {
                    data   => "bar",
                    output => "62cdb7020ff920e5aa642c3d4066950dd1f01f4d",
                },
                {
                    data   => "baz",
                    output => "bbe960a25ea311d21d40669e93df2003ba9b90a2",
                },
            ],
        },
        {
            Scenario => "Empty data MD5",
            Given    => "a Digest MD5 object",
            When     => [],
            Then     => [ q{the hex output is "d41d8cd98f00b204e9800998ecf8427e"} ],
        },
        {
            Scenario => "MD5 longer data",
            Given    => "a Digest MD5 object",
            When     => [
                {
                    condition => "I've added the following to the object",
                    data      => "Here is a chunk of text that works a bit\n"
                      . "like a HereDoc. We'll split off indenting space from\n"
                      . "the lines in it up to the indentation of the first",
                }
            ],
            Then => [ q{the hex output is "ee86bacb965c2353a524f3b4b4da4700"}, ],
        }
    );

    my $cucumber = Test::Cucumber::Tiny->new( scenarios => \@scenarios );

    $cucumber->Given( qr/a usable (\S+) class/, sub { use_ok($1) } );

    $cucumber->Given(
        qr/a Digest (\S+) object/,
        sub {
            my $c       = shift;
            my $subject = shift;
            my $object  = Digest->new($1);
            ok( $object, $subject );
            $c->{object} = $object;
        }
    );

    $cucumber->When(
        qr/I've added "(.+)" to the object/,
        sub {
            my $c = shift;
            $c->{object}->add($1);
        }
    );

    $cucumber->When(
        "I've added the following to the object",
        sub {
            my $c       = shift;
            my $subject = shift;
            $c->{object}->add( $c->{data}, $subject );
        }
    );

    $cucumber->Then(
        qr/the (.+) output is "(.+)"/,
        sub {
            my $c       = shift;
            my $subject = shift;
            my $method  = { base64 => "b64digest", hex => "hexdigest" }->{$1};
            if ( !$method ) {
                fail("Unknown output type $1");
                return;
            }
            is( $c->{object}->$method, $2, $subject );
        }
    );

    $cucumber->Test;
};
