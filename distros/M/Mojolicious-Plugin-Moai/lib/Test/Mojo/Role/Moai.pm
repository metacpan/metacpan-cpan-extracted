package Test::Mojo::Role::Moai;
our $VERSION = '0.013';
# ABSTRACT: Test::Mojo role to test UI components

#pod =head1 SYNOPSIS
#pod
#pod     my $t = Test::Mojo->with_roles( '+Moai' )->new;
#pod     $t->get_ok( '/' )
#pod       ->table_is(
#pod         '#mytable',
#pod         [
#pod             [ '1BDI' => 'Turanga Leela' ],
#pod             [ 'TJAM' => 'URL' ],
#pod         ],
#pod         'NNY officers are listed',
#pod       );
#pod
#pod =head1 DESCRIPTION
#pod
#pod This module provides component tests for web pages: Instead of selecting
#pod individual elements and testing their parts, these methods test complete
#pod components in a way that allows for cosmetic, non-material changes to be
#pod made without editing the test.
#pod
#pod These methods are designed for L<Mojolicious::Plugin::Moai> components, but
#pod do not require Mojolicious::Plugin::Moai to function. Use them on any web
#pod site you want!
#pod
#pod =head1 TODO
#pod
#pod =over
#pod
#pod =item qr// for text
#pod
#pod Element text and attribute values should allow regex matching in addition
#pod to complete equality.
#pod
#pod =item list_is / list_has
#pod
#pod Test a list
#pod
#pod =item dict_is / dict_has
#pod
#pod Test a dictionary list
#pod
#pod =item elem_is / elem_has
#pod
#pod Test an individual element (using L<Mojo::DOM/at>).
#pod
#pod =item all_elem_is / all_elem_has
#pod
#pod Test a collection of elements (using L<Mojo::DOM/find>).
#pod
#pod =item link_to named route
#pod
#pod Elements should be able to test whether they are a link to a named route
#pod with certain stash values set. This allows for the route's URL to change
#pod without needing to change the test.
#pod
#pod =item Methods for Moai components
#pod
#pod Any Moai components that have special effects or contain multiple testable
#pod elements should be given their own method, with C<_is> and C<_has> variants.
#pod
#pod =back
#pod
#pod =head1 SEE ALSO
#pod
#pod L<Mojolicious::Plugin::Moai>, L<Mojolicious::Guides::Testing>
#pod
#pod =cut

use Mojo::Base '-role';
use Mojo::Util qw( trim );
use Test::More;

#pod =method table_is
#pod
#pod     # <table>
#pod     # <thead><tr><th>ID</th><th>Name</th></tr></thead>
#pod     # <tbody><tr><td>1</td><td>Doug</td></tr></tbody>
#pod     # </table>
#pod     $t = $t->table_is( '#mytable', [ [ 1, 'Doug' ] ] );
#pod     $t = $t->table_is( '#mytable', [ [ 1, 'Doug' ] ], 'user table' );
#pod     $t = $t->table_is( '#mytable', [ { ID => 1, Name => 'Doug' } ] );
#pod
#pod Check data in a table is complete and correct. Data can be tested as
#pod arrays (ordered) or hashes (unordered).
#pod
#pod If a table contains a C<< <tbody> >> element, this method will test the
#pod data inside. If not, it will test all rows in the table.
#pod
#pod     # <table><tr><td>1</td><td>Doug</td></tr></table>
#pod     $t = $t->table_is( '#mytable', [ [ 1, 'Doug' ] ] );
#pod
#pod To test attributes and elements inside the table cells, values can be
#pod hashrefs with a C<text> attribute (for the cell text), an C<elem>
#pod attribute to test descendant elements, and other keys for the cell's
#pod attributes.
#pod
#pod     # <table><tr>
#pod     # <td class="center">1</td>
#pod     # <td><a href="/user/doug">Doug</a> <em>(admin)</em></td>
#pod     # </tr></table>
#pod     $t = $t->table_is( '#mytable', [
#pod         [
#pod             { text => 1, class => 'center' },
#pod             { elem => {
#pod                 'a' => {
#pod                     text => 'Doug',
#pod                     href => '/user/doug',
#pod                 },
#pod                 'em' => '(admin)',
#pod             } },
#pod         ],
#pod     ] );
#pod
#pod =cut

sub table_is {
    my ( $t, $selector, $rows, $name ) = @_;
    $name ||= 'table ' . $selector . ' data is correct';
    my $el = $t->_test_find_el( $selector, $name ) || return;

    my @columns = $t->_table_cols( $el );

    my @fails;
    my $tbody = $el->at( 'tbody' ) // $el;
    # ; use Data::Dumper;
    # ; say Dumper $el;
    for my $i ( 0..$#$rows ) {
        my @row_data
            = ref $rows->[ $i ] eq 'HASH'
            ? ( map { $rows->[ $i ]{ $_ } } @columns )
            : @{ $rows->[ $i ] };
        my $row_el = $tbody->children->[ $i ];
        for my $c ( 0..$#row_data ) {
            my $expect_data = $row_data[ $c ];

            my $expect_text
                = ref $expect_data eq 'HASH'
                ? delete $expect_data->{text}
                : $expect_data;
            my $cell_el = $row_el->children->[ $c ];
            # ; say Dumper $cell_el;
            my $got_text = trim( $cell_el->all_text );
            if ( defined $expect_text && ( !defined $got_text || $expect_text ne $got_text ) ) {
                #; say sprintf "%s,%s: Exp: %s; Got: %s", $i, $c, $expect_text, $got_text;
                $got_text //= '<undef>';
                push @fails, {
                    row => $i + 1,
                    col => $c + 1,
                    got => qq{"$got_text"},
                    expect => qq{"$expect_text"},
                };
            }

            if ( ref $expect_data eq 'HASH' ) {
                # We've got more tests to run!
                if ( my $elem_test = delete $expect_data->{elem} ) {
                    for my $selector ( sort keys %$elem_test ) {
                        my $el = $cell_el->at( $selector );
                        if ( !$el ) {
                            push @fails, {
                                row => $i + 1,
                                col => $c + 1,
                                got => '<undef>',
                                expect => qq{elem "$selector"},
                            };
                            next;
                        }

                        my $expect_data = $elem_test->{ $selector };
                        my $expect_text
                            = ref $expect_data eq 'HASH'
                            ? delete $expect_data->{text}
                            : $expect_data;
                        my $got_text = trim( $el->all_text );
                        if ( defined $expect_text && ( !defined $got_text || $expect_text ne $got_text ) ) {
                            #; say sprintf "%s,%s: Exp: %s; Got: %s", $i, $c, $expect_text, $got_text;
                            $got_text //= '<undef>';
                            push @fails, {
                                row => $i + 1,
                                col => $c + 1,
                                got => qq{$selector: "$got_text"},
                                expect => qq{$selector: "$expect_text"},
                            };
                        }

                        # Everything that remains is an attribute
                        if ( ref $expect_data eq 'HASH' ) {
                            for my $attr_name ( sort keys %$expect_data ) {
                                my $expect_attr = $expect_data->{ $attr_name };
                                my $got_attr = $el->attr( $attr_name );
                                if ( !defined $got_attr || $expect_attr ne $got_attr ) {
                                    $got_attr //= '<undef>';
                                    #; say sprintf "%s,%s: Exp: %s: %s = %s; Got: %s: %s = %s", $i, $c, $selector, $attr_name, $expect_attr, $selector, $attr_name, $got_attr;
                                    push @fails, {
                                        row => $i + 1,
                                        col => $c + 1,
                                        got => "$selector: $attr_name = $got_attr",
                                        expect => "$selector: $attr_name = $expect_attr",
                                    };
                                }
                            }
                        }
                    }
                }

                # Everything that remains is an attribute
                for my $attr_name ( sort keys %$expect_data ) {
                    my $expect_attr = $expect_data->{ $attr_name };
                    my $got_attr = $cell_el->attr( $attr_name );
                    if ( !defined $got_attr || $expect_attr ne $got_attr ) {
                        $got_attr //= '<undef>';
                        #; say sprintf "%s,%s: Exp: %s = %s; Got: %s = %s", $i, $c, $attr_name, $expect_attr, $attr_name, $got_attr;
                        push @fails, {
                            row => $i + 1,
                            col => $c + 1,
                            got => "$attr_name = $got_attr",
                            expect => "$attr_name = $expect_attr",
                        };
                    }
                }
            }
        }
    }

    if ( @fails ) {
        Test::More::fail( $name );
        Test::More::diag(
            join "\n",
            map {
                sprintf qq{Row: %d - Col: %d\nExpected: %s\nGot: %s},
                    @{$_}{qw( row col expect got )},
            }
            @fails
        );
        return $t->success( 0 );
    }

    Test::More::pass( $name );
    return $t->success( 1 );
}

#pod =method table_has
#pod
#pod     # <table>
#pod     # <thead><tr><th>ID</th><th>Name</th></tr></thead>
#pod     # <tbody><tr><td>1</td><td>Doug</td></tr></tbody>
#pod     # </table>
#pod     $t = $t->table_has( '#mytable', [ { ID => 1, Name => 'Doug' } ] );
#pod     $t = $t->table_has( '#mytable', [ { Name => 'Doug' } ] );
#pod
#pod Check a subset of rows/columns of data in a table.
#pod
#pod =cut

sub table_has {
    my ( $t, $selector, $expects, $name ) = @_;
    $name ||= 'table ' . $selector . ' data is correct';
    my $el = $t->_test_find_el( $selector, $name ) || return $t;
    my @columns = $t->_table_cols( $el );

    my ( @fails, @matches, %count );
    my $tbody = $el->at( 'tbody' ) // $el;
    # ; use Data::Dumper;
    # ; say Dumper $el;
    EXPECT: for my $i ( 0..$#$expects ) {
        my $expect = $expects->[$i];
        # Try to find rows that match in the table. Prefer more columns
        # matching to fewer. Later we will determine if every row of
        # the table can be assigned to a single unique row of input.
        ROW_EL: for my $row_i ( 0 .. @{ $tbody->children }-1 ) {
            my $row_el = $tbody->children->[ $row_i ];
            for my $c ( 0..$#columns ) {
                next unless exists $expect->{ $columns[ $c ] };
                # ; say sprintf 'Expect: %s; Got: %s',
                #     $expect->{ $columns[ $c ] },
                #     $row_el->children->[ $c ]->all_text,
                #     ;
                my $col_el = $row_el->children->[ $c ];
                next ROW_EL if $expect->{ $columns[ $c ] } ne $col_el->all_text;
            }
            # All columns expected have matching values, so this row
            # matches
            #; say sprintf 'Matched %d with %s', $i, $row_i;
            push @{ $matches[ $i ] }, $row_i;
            $count{ $row_i }++;
            next EXPECT;
        }
        # No row elements match this expect, so this row fails
        push @fails, { input => $i };
    }

    # Starting from the input rows that matched the fewest table rows,
    # assign a single table row match to each input row match. Any input
    # row that is left without a table row is now a failure.
    my %used_rows;
    for my $i ( sort { @{ $matches[ $a ] } <=> @{ $matches[ $b ] } } 0..$#matches ) {
        my $match = $matches[ $i ];
        my @possible = grep { !$used_rows{ $_ } } @$match;
        # If there are no possible rows for this input, we've failed
        if ( !@possible ) {
            push @fails, {
                input => $i,
            };
        }
        # If there's only one possible row for this input, we have to
        # use it
        elsif ( @possible == 1 ) {
            $used_rows{ $possible[0] } = $i;
        }
        # Multiple possibilities exist, so find the one with the least
        # amount of other uses
        else {
            my ( $choice ) = sort { $count{ $a } <=> $count{ $b } } @possible;
            $used_rows{ $choice } = $i;
        }
    }

    if ( @fails ) {
        Test::More::fail( $name );
        my @fail_strs;
        for my $fail ( @fails ) {
            my $expect = $expects->[ $fail->{input} ];
            push @fail_strs,
                join ', ',
                map { sprintf '%s="%s"', $_, $expect->{ $_ } }
                sort keys %$expect;
        }
        Test::More::diag(
            join "\n",
            map {
                sprintf qq{Missing: Row with %s}, $_
            }
            @fail_strs
        );
        return $t->success( 0 );
    }

    Test::More::pass( $name );
    return $t->success( 1 );
}

# Find the element with the given selector and return it. If not found,
# fail the test and return empty. If the test failed, you should return
# the $t object (to allow the Test::Mojo convention of chaining).
#
#   my $el = $t->_test_find_el( $selector, $test_name ) || return $t;
#
sub _test_find_el {
    my ( $t, $selector, $name ) = @_;
    $name ||= 'element ' . $selector . ' exists';

    my $el = $t->tx->res->dom->at( $selector );
    if ( !$el ) {
        Test::More::fail( $name );
        Test::More::diag( 'Element ' . $selector . ' not found' );
        $t->success( 0 );
        return;
    }
    return $el;
}

# Get the columns in the given table. The table columns must be in
# a <thead> element. Returns a list of columns.
#
#   my @columns = $t->_table_cols( $table_el );
#
sub _table_cols {
    my ( $t, $el ) = @_;
    my @columns;
    if ( my $thead = $el->at( 'thead' ) ) {
        @columns = $thead->at( 'tr' )->children( 'td,th' )
            ->map( 'all_text' )
            ->map( sub { trim( $_ ) } )
            ->each;
        #; say "Cols: " . join ', ', @columns;
    }
    return @columns;
}

1;

__END__

=pod

=head1 NAME

Test::Mojo::Role::Moai - Test::Mojo role to test UI components

=head1 VERSION

version 0.013

=head1 SYNOPSIS

    my $t = Test::Mojo->with_roles( '+Moai' )->new;
    $t->get_ok( '/' )
      ->table_is(
        '#mytable',
        [
            [ '1BDI' => 'Turanga Leela' ],
            [ 'TJAM' => 'URL' ],
        ],
        'NNY officers are listed',
      );

=head1 DESCRIPTION

This module provides component tests for web pages: Instead of selecting
individual elements and testing their parts, these methods test complete
components in a way that allows for cosmetic, non-material changes to be
made without editing the test.

These methods are designed for L<Mojolicious::Plugin::Moai> components, but
do not require Mojolicious::Plugin::Moai to function. Use them on any web
site you want!

=head1 METHODS

=head2 table_is

    # <table>
    # <thead><tr><th>ID</th><th>Name</th></tr></thead>
    # <tbody><tr><td>1</td><td>Doug</td></tr></tbody>
    # </table>
    $t = $t->table_is( '#mytable', [ [ 1, 'Doug' ] ] );
    $t = $t->table_is( '#mytable', [ [ 1, 'Doug' ] ], 'user table' );
    $t = $t->table_is( '#mytable', [ { ID => 1, Name => 'Doug' } ] );

Check data in a table is complete and correct. Data can be tested as
arrays (ordered) or hashes (unordered).

If a table contains a C<< <tbody> >> element, this method will test the
data inside. If not, it will test all rows in the table.

    # <table><tr><td>1</td><td>Doug</td></tr></table>
    $t = $t->table_is( '#mytable', [ [ 1, 'Doug' ] ] );

To test attributes and elements inside the table cells, values can be
hashrefs with a C<text> attribute (for the cell text), an C<elem>
attribute to test descendant elements, and other keys for the cell's
attributes.

    # <table><tr>
    # <td class="center">1</td>
    # <td><a href="/user/doug">Doug</a> <em>(admin)</em></td>
    # </tr></table>
    $t = $t->table_is( '#mytable', [
        [
            { text => 1, class => 'center' },
            { elem => {
                'a' => {
                    text => 'Doug',
                    href => '/user/doug',
                },
                'em' => '(admin)',
            } },
        ],
    ] );

=head2 table_has

    # <table>
    # <thead><tr><th>ID</th><th>Name</th></tr></thead>
    # <tbody><tr><td>1</td><td>Doug</td></tr></tbody>
    # </table>
    $t = $t->table_has( '#mytable', [ { ID => 1, Name => 'Doug' } ] );
    $t = $t->table_has( '#mytable', [ { Name => 'Doug' } ] );

Check a subset of rows/columns of data in a table.

=head1 TODO

=over

=item qr// for text

Element text and attribute values should allow regex matching in addition
to complete equality.

=item list_is / list_has

Test a list

=item dict_is / dict_has

Test a dictionary list

=item elem_is / elem_has

Test an individual element (using L<Mojo::DOM/at>).

=item all_elem_is / all_elem_has

Test a collection of elements (using L<Mojo::DOM/find>).

=item link_to named route

Elements should be able to test whether they are a link to a named route
with certain stash values set. This allows for the route's URL to change
without needing to change the test.

=item Methods for Moai components

Any Moai components that have special effects or contain multiple testable
elements should be given their own method, with C<_is> and C<_has> variants.

=back

=head1 SEE ALSO

L<Mojolicious::Plugin::Moai>, L<Mojolicious::Guides::Testing>

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
