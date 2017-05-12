#!/usr/bin/env perl

use strict;
use warnings;

use lib 't/lib';
use MyTest::PPG ':all';
use Test::Most 'no_plan'; #tests => 1;
use Pod::Parser::Groffmom;

my $pod = <<'END';
=head1 Nested sequences

C<< <I<alias>=I<rulename>> >>

END

my $expected_body = <<'END';

.HEAD "Nested sequences"

\f[C]<\f[P]\f[CI]alias\f[P]\f[C]=\f[P]\f[CI]rulename\f[P]\f[C]>\f[P]

END

eq_or_diff body(get_mom($pod)), $expected_body,
    'Nested sequences should group codes correctly';
