#!/usr/bin/env perl

# Copyright (c) 2008-2009 George Nistorica
# All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.  See the LICENSE
# file that comes with this distribution for more details.

#	($rcs) = (' $Id: 030-transparency.t,v 1.4 2009/01/28 12:38:10 george Exp $ ' =~ /(\d+(\.\d+)+)/);

use strict;
use warnings;

# Check that the module is acting as POE::Filter::Line does
# and that it does basic transparency also
# (basic check)

my $DEBUG = 1;
my $EOL   = qq{\015\012};

use Test::More qw(no_plan);
use Data::Dumper;
use lib q{lib/};
use POE::Filter::Transparent::SMTP;

my ( $multiple_lines_string, $from_transparent_filter,
    $expected_from_transparent_filter,
    @raw_data_to_filter, $transparent_filter, $representation );

# use several line terminators
my @literals = ( qq{\015\012}, qq{\015}, qq{\012}, );

foreach my $literal (@literals) {

    ######################################
    # get_one_start() and get_one() test #
    ######################################

    $multiple_lines_string =
        q{.line one} 
      . $literal
      . q{line two}
      . $literal
      . q{...line tree}
      . $literal
      . q{line four}
      . $literal . q{.}
      . $literal;

    $transparent_filter = POE::Filter::Transparent::SMTP->new(
        q{InputLiteral}  => $literal,
        q{OutputLiteral} => $literal,
    );

    $transparent_filter->get_one_start(
        [ $multiple_lines_string, $multiple_lines_string ] );

    $representation = q{ascii } . join( q{,}, map( ord, split //, $literal ) );

    # loop two times
    for ( 1 .. 2 ) {

        # clients obeying the RFC shouldn't send lines starting with
        # a single dot. the filter should not remove the single starting
        # dot when being at the receiving end
        $from_transparent_filter = $transparent_filter->get_one();
        is( $from_transparent_filter->[0],
            q{.line one}, q{->get_one} . q{ for line end: } . $representation );
        $from_transparent_filter = $transparent_filter->get_one();
        is( $from_transparent_filter->[0],
            q{line two}, q{->get_one} . q{ for line end: } . $representation );
        $from_transparent_filter = $transparent_filter->get_one();
        is( $from_transparent_filter->[0],
            q{..line tree},
            q{->get_one} . q{ for line end: } . $representation );
        $from_transparent_filter = $transparent_filter->get_one();
        is( $from_transparent_filter->[0],
            q{line four}, q{->get_one} . q{ for line end: } . $representation );
        $from_transparent_filter = $transparent_filter->get_one();
        is( $from_transparent_filter->[0],
            q{.}, q{->get_one} . q{ for line end: } . $representation );
    }

    ##############
    # get() test #
    ##############

    $expected_from_transparent_filter = [
        q{.line one},
        q{line two},
        q{..line tree},
        q{line four},
        q{.},
        q{.line one},
        q{line two},
        q{..line tree},
        q{line four},
        q{.},
    ];
    $from_transparent_filter = $transparent_filter->get(
        [ $multiple_lines_string, $multiple_lines_string ] );
    is_deeply(
        $from_transparent_filter,
        $expected_from_transparent_filter,
        q{->get()} . q{ for line end: } . $representation
    );

    ##############
    # put() test #
    ##############

    @raw_data_to_filter =
      ( q{1st line}, q{..2nd line}, q{.3rd line}, q{4th line}, q{.}, );
    $expected_from_transparent_filter = [
        q{1st line} . $literal,
        q{...2nd line} . $literal,
        q{..3rd line} . $literal,
        q{4th line} . $literal,
        q{.} . $literal,
    ];

    $from_transparent_filter = $transparent_filter->put( \@raw_data_to_filter );
    is_deeply(
        $from_transparent_filter,
        $expected_from_transparent_filter,
        q{->put()} . q{ for line end: } . $representation
    );

}

