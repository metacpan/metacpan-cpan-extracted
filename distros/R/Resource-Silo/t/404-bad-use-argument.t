#!/usr/bin/env perl

=head1 DESCRIPTION

Don't allow unexpected arguments on use.

=cut

use strict;
use warnings;
use Test::More;

eval q{use Resource::Silo -foobar}; ## no critic # yes we want eval
like $@, qr/[Uu]nexpected.*'-foobar'/, 'correct error message';
note $@;

done_testing;
