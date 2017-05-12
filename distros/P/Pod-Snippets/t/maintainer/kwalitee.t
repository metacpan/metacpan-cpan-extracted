#!/usr/bin/perl -w

=head1 NAME

kwalitee.t - Applies L<Test::Kwalitee> on the module

=cut

use strict;
use Test::More;

eval "use Test::Kwalitee";

plan( skip_all => 'Test::Kwalitee not installed; skipping' ) if $@;

