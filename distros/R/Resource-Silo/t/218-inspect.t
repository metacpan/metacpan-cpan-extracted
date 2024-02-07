#!/usr/bin/env perl

=head1 DESCRIPTION

Primitives for container inspection

=cut

use strict;
use warnings;
use Test::More;

{
    package My::App;
    use Resource::Silo -class;

    resource conn => sub { {} };
    resource foo  =>
        argument    => qr(.*),
        init        => sub { $_[0]->conn->{$_[2]}++; $_[2]; };
}

my $app = My::App->new;

$app->foo(42);
$app->foo();

is_deeply [ $app->ctl->list_cached ]
    , [qw[conn foo foo/42]]
    , "allocated resources listed"
    ;

is_deeply scalar $app->ctl->list_cached
    , [qw[conn foo foo/42]]
    , "allocated resources listed (scalar context)"
    ;

done_testing;
