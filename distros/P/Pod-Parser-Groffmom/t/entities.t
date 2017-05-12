#!/usr/bin/env perl

use strict;
use warnings;

use lib 't/lib';
use MyTest::PPG ':all';
use Test::Most 'no_plan'; #tests => 1;
use Pod::Parser::Groffmom;

my $pod = <<'END';
=head1 NAME

E<ntilde> eq E<241>

=head2 Some stuff

L<Net::Ping>

L<Net::Ping|Net::Ping>

L<the Net::Ping module|Net::Ping>

L<support section|PPI/SUPPORT>

L<http://www.example.com/>

L<perlsyn/"For Loops">

L<perlsyn/For Loops>

This is a line which breaks.  I recommend you look at Salvador FandiE<ntilde>o's S<Language::Prolog::Yaswi>.

END

my $mom = get_mom($pod);
is head( $mom, 1 ), q{.TITLE "\\N'241' eq \\N'241'"},
  'E<> sequences should be parsed correctly';

my $expected_body = <<'END';

.SUBHEAD "Some stuff"

\f[C]Net::Ping\f[P]

\f[C]Net::Ping\f[P]

the Net::Ping module (\f[C]Net::Ping\f[P])

support section (\f[C]PPI/SUPPORT\f[P])

 (\f[C]http://www.example.com\f[P])

\[dq]For Loops\[dq] (\f[C]perlsyn\f[P])

For Loops (\f[C]perlsyn\f[P])

This is a line which breaks.  I recommend you look at Salvador Fandi\N'241'o's  \c
.HYPHENATE OFF
Language::Prolog::Yaswi\c
.HYPHENATE
\N'46'

END

eq_or_diff body($mom), $expected_body,
    '... and L<> seqeunces should be parsed correctly';
