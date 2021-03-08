#!/usr/bin/env perl

use strict;
use warnings;

use Test2::V0;
use RxPerl::Test;

use RxPerl::IOAsync ':all';

my $o = rx_of(10, 20, 30);
my $f;
my (@vals, @errs);

(@vals, @errs) = ();
$f = first_value_from($o);
$f->on_done(sub { push @vals, $_[0] });
$f->on_fail(sub { push @errs, $_[0] });
is [\@vals, \@errs], [[10], []], 'first_value_from w/ value';

(@vals, @errs) = ();
$f = last_value_from($o);
$f->on_done(sub { push @vals, $_[0] });
$f->on_fail(sub { push @errs, $_[0] });
is [\@vals, \@errs], [[30], []], 'last_value_from w/ value';

$o = rx_of();

(@vals, @errs) = ();
$f = first_value_from($o);
$f->on_done(sub { push @vals, $_[0] });
$f->on_fail(sub { push @errs, $_[0] });
is [\@vals, \@errs], [[], ['no elements in sequence']], 'first_value_from w/o value';

(@vals, @errs) = ();
$f = last_value_from($o);
$f->on_done(sub { push @vals, $_[0] });
$f->on_fail(sub { push @errs, $_[0] });
is [\@vals, \@errs], [[], ['no elements in sequence']], 'last_value_from w/o value';

done_testing;