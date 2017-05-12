#!/usr/bin/env perl

# Copyright (c) 2008-2009 George Nistorica
# All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.  See the LICENSE
# file that comes with this distribution for more details.

# 	($rcs) = (' $Id: 020-filter_line_compat.t,v 1.6 2009/01/28 12:38:29 george Exp $ ' =~ /(\d+(\.\d+)+)/);

use strict;
use warnings;

# Check that the module is acting as POE::Filter::Line does
# (basic check)

use Test::More;
use POE::Filter::Line;
use lib q{lib/};
use POE::Filter::Transparent::SMTP;

my (
    $multiple_lines_string, $from_transparent_filter,
    $from_line_filter,      @raw_data_to_filter
);
my ( $transparent_filter, $line_filter );

# use several line terminators
my @literals = ( qq{\015\012}, qq{\015}, qq{\012}, );

# for each literal there are 4 tests
plan tests => 4 * scalar @literals;

foreach my $literal (@literals) {
    $multiple_lines_string =
        q{line one} . qq{\n}
      . q{line two} . qq{\n}
      . q{line tree} . qq{\n}
      . q{line four} . qq{\n};

    $transparent_filter = POE::Filter::Transparent::SMTP->new(
        q{InputLiteral}  => $literal,
        q{OutputLiteral} => $literal,
    );
    $line_filter = POE::Filter::Line->new( q{Literal} => $literal, );

    $transparent_filter->get_one_start( [$multiple_lines_string] );
    $line_filter->get_one_start(        [$multiple_lines_string] );

    $from_transparent_filter = $transparent_filter->get_one();
    $from_line_filter        = $line_filter->get_one();
    is_deeply( $from_transparent_filter, $from_line_filter, q{->get_one()} );

    $from_transparent_filter =
      $transparent_filter->get( [$multiple_lines_string] );
    $from_line_filter = $line_filter->get( [$multiple_lines_string] );
    is_deeply( $from_transparent_filter, $from_line_filter, q{->get()} );

    @raw_data_to_filter = (
        q{first thing(no new line)},
        qq{second thing (with new line)\n},
        q{third thing (no new line},
    );
    $from_transparent_filter = $transparent_filter->put( \@raw_data_to_filter );
    $from_line_filter        = $line_filter->put( \@raw_data_to_filter );
    is_deeply( $from_transparent_filter, $from_line_filter, q{->put()} );

    $from_transparent_filter = $transparent_filter->get_pending();
    $from_line_filter        = $line_filter->get_pending();
    is_deeply( $from_transparent_filter, $from_line_filter,
        q{->get_pending()} );

}

