#!/usr/bin/env perl

=head1 DESCRIPTION

Ensure nullable resources don't die upon initialisation.

=cut

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $count = 0;

{
    package My::App;
    use Resource::Silo -class;

    resource nullable   =>
        nullable    => 1,
        init        => sub { $count++; return };

    resource nullable_with_arg =>
        argument    => qr(.*),
        nullable    => 1,
        init        => sub { $count++; return };
}

subtest 'simple nullable resource' => sub {
    my $app = My::App->new;

    lives_ok {
        is $app->nullable, undef, 'nullable resource returns undef';
        is $count, 1, 'initializer called once';
    } "Nullable resource is undef but that's fine";

    lives_ok {
        is $app->nullable, undef, 'nullable resource returns undef again';
        is $count, 1, 'initializer not called again';
    } "Nullable resource is still undef but that's still fine";
};

subtest 'nullable resource with argument' => sub {
    my $app = My::App->new;
    $count = 0;

    lives_ok {
        is $app->nullable_with_arg("foo"), undef, 'nullable resource with arg returns undef';
        is $count, 1, 'initializer called once more';
    } "Nullable resource with arg is undef but that's fine";

    lives_ok {
        is $app->nullable_with_arg("foo"), undef, 'nullable resource with arg returns undef again';
        is $count, 1, 'initializer not called again';
    } "Nullable resource with arg is still undef but that's still fine";

    lives_ok {
        is $app->nullable_with_arg("bar"), undef, 'nullable resource with different arg returns undef';
        is $count, 2, 'initializer called for new argument';
    } "Nullable resource with different arg is undef but that's still fine";
};

done_testing;