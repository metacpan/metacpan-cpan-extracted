use 5.20.0;
use strict;
use warnings;
use utf8;
use open ':std', ':encoding(utf8)';

use Test::More;
use Test::Synopsis::Expectation;
use Unicode::Normalize;

require_ok('Software::Copyright::Owner');

synopsis_ok('lib/Software/Copyright/Owner.pm');

subtest "just a name" => sub {
    my $owner = Software::Copyright::Owner->new("Marcel");

    is("$owner", "Marcel", "check simple owner");
    is($owner->name, "Marcel", "check name");
};

subtest "just an unicode name" => sub {
    my $owner = Software::Copyright::Owner->new(NFD("Éric"));

    is("$owner", NFC("Éric"), "check unicode owner");
    is($owner->name, NFC("Éric"), "check name");
};

subtest "just a number" => sub {
    my $owner = Software::Copyright::Owner->new("2021");

    is("$owner", "2021", "check owner string when a number was given");
    is($owner->name, undef, "check owner name when a number was given");
    is($owner->record, "2021", "check owner name when a number was given");
};

subtest "combined owners" => sub {
    my $str = "Blaine Bublitz, Eric Schoffstall and other contributors";
    my $owner = Software::Copyright::Owner->new($str);

    is("$owner", $str, "check owner string");
    is($owner->name, undef, "check owner name");
    is($owner->record, $str, "check owner name");
    is($owner->identifier, $str, "check owner identifier");
};

subtest "combined owners and email" => sub {
    my $str = 'Blaine Bublitz <blaine.bublitz@gmail.com>,'
        . ' Eric Schoffstall <yo@contra.io> and other contributors';
    my $owner = Software::Copyright::Owner->new($str);

    is("$owner", $str, "check owner string");
    is($owner->name, undef, "check owner name");
    is($owner->record, $str, "check owner record");
    is($owner->identifier, $str, "check owner identifier");
    is($owner->email, undef, "check owner email");
};

subtest "name and email" => sub {
    my $owner = Software::Copyright::Owner->new("Marcel");

    $owner->email( 'marcel@example.com' );

    is("$owner", 'Marcel <marcel@example.com>', "check owner and email");
};

subtest "create with name and email" => sub {
    my @tests = (
        ['Marcel <marcel@example.com>', Marcel => 'marcel@example.com'],
        ['Marcel <marcel2015@example.com>', Marcel => 'marcel2015@example.com'],
    );

    foreach my $test (@tests) {
        my ($in, $name, $email, $out) = $test->@*;
        my $owner = Software::Copyright::Owner->new($in);

        is($owner->name, $name, "check name");
        is($owner->email, $email, "check email");

        is("$owner", $out // $in, "check owner and email");
    }
};

subtest "invalid owners" => sub {
    my $owner = Software::Copyright::Owner->new('**');

    is($owner->name, undef, "check name");
    is($owner->email, undef, "check email");
    is($owner->record, "**", "check record");
};

done_testing;
