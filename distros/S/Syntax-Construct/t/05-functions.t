#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 5;

use Syntax::Construct ();

is(Syntax::Construct::introduced('//'), '5.010', 'introduced-arg');

my @introduced = Syntax::Construct::introduced();
is(@introduced, 65, 'introduced all');

is(Syntax::Construct::removed('auto-deref'), '5.024', 'removed-arg');
is(Syntax::Construct::removed(), 3, 'removed all');

my $in_old = 'SOMETHING_IN_OLD';

if ('SOMETHING_IN_OLD' eq $in_old && ! Syntax::Construct::_is_old_empty()) {
    fail('Use a real construct introduced in old');

} else {
    is(Syntax::Construct::introduced($in_old),
       undef, 'old not introduced');
}
