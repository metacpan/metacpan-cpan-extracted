#!/usr/bin/env perl

=head1 DESCRIPTION

Returning undef from resource initializer should be considered an error.

=cut

use strict;
use warnings;
use Test::More;
use Test::Exception;

use Resource::Silo;

my $count = 0;

resource bare   => sub { $count++; return };
resource param  =>
    argument        => qr(.*),
    init            => sub {};

my $no_reason = "declared at ".quotemeta(__FILE__)." line \\d+ "
    .".* for no apparent reason";

throws_ok {
    silo->bare;
} qr('bare' $no_reason), "undef return";

throws_ok {
    silo->bare;
} qr('bare' $no_reason), "undef return (on second try too)";

is $count, 2, "2 attempts to initialize";

throws_ok {
    silo->param("foo_42");
} qr('param.foo_42' $no_reason), "undef return with param";

throws_ok {
    silo->ctl->fresh("bare");
} qr('bare' $no_reason), "undef return via fresh";

throws_ok {
    silo->ctl->fresh(param => "foo_42");
} qr('param.foo_42' $no_reason), "undef return with param via fresh";

done_testing;
