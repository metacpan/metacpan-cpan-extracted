#!/usr/bin/env perl

=head1 DESCRIPTION

Returning undef from resource initializer should be considered an error.

=cut

use strict;
use warnings;
use Test::More;
use Test::Exception;

use Resource::Silo;

resource bare   => sub {};
resource param  =>
    argument        => qr(.*),
    init            => sub {};

throws_ok {
    silo->bare;
} qr('bare' failed for no .* reason), "undef return = no go";

throws_ok {
    silo->param("foo_42");
} qr('param.foo_42' failed for no .* reason), "undef return = no go";

throws_ok {
    silo->ctl->fresh("bare");
} qr('bare' failed for no .* reason), "undef return = no go";

throws_ok {
    silo->ctl->fresh(param => "foo_42");
} qr('param.foo_42' failed for no .* reason), "undef return = no go";

done_testing;
