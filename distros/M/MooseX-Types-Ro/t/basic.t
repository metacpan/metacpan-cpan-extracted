#!perl
# -*- indent-tabs-mode: nil -*-

use strict;
use warnings;

{
    package Class;
    use Moose;
    use MooseX::Types -declare => [qw(RoIntArray RoIntHash)];
    use MooseX::Types::Ro qw(RoArrayRef RoHashRef);
    use MooseX::Types::Moose qw(ArrayRef HashRef Int);

    subtype RoIntArray,
        as RoArrayRef[Int];
    coerce RoIntArray,
        from ArrayRef[Int],
        via { to_RoArrayRef($_) };

    subtype RoIntHash,
        as RoHashRef[Int];
    coerce RoIntHash,
        from HashRef[Int],
        via { to_RoHashRef($_) };

    foreach (
        [array => RoArrayRef, RoIntArray],
        [hash  => RoHashRef, RoIntHash],
    ) {
        my ($type, $plain, $parametrised) = @{$_};
        has "plain_$type" => (is => 'ro', isa => $plain);
        has "parametrised_$type" => (is => 'ro', isa => $parametrised);

        has "coerced_plain_$type" => (is => 'ro', isa => $plain, coerce => 1);
        has "coerced_parametrised_$type" => (is => 'ro', isa => $parametrised, coerce => 1);
    }
}

package main;

use Test::More;
use Test::Exception;

use MooseX::Types::Ro qw(RoArrayRef);
use Internals qw(SetReadOnly IsWriteProtected);

my $array = [ 1, 2, 3 ];
my $ro_array = [ @{$array} ];
SetReadOnly($ro_array);
SetReadOnly(\$_) foreach @{$ro_array};

my $hash = { foo => 1, bar => 2, baz => 3 };
my $ro_hash = { %{$hash} };
SetReadOnly($ro_hash);
SetReadOnly(\$_) foreach values %{$ro_hash};

foreach (
    [array => $array, $ro_array],
    [hash => $hash, $ro_hash],
) {
    my ($type, $plain, $readonly) = @{$_};
    foreach my $variant (qw(plain parametrised)) {
        my $strict = "${variant}_${type}";
        my $coerced = "coerced_${variant}_${type}";
        lives_and { is_deeply( Class->new($strict => $readonly)->$strict, $plain ) } "readonly strict $variant $type";
        throws_ok { Class->new($strict => $plain) } qr/does not pass/, "writable strict $variant $type throws";
        lives_and { is_deeply( Class->new($coerced => $readonly)->$coerced, $plain ) } "readonly coerced $variant $type";
        lives_and { is_deeply( Class->new($coerced => $plain)->$coerced, $plain ) } "writable coerced $variant $type";
        ok( !IsWriteProtected($plain), "original $type still writable" );
    }
}

done_testing;
