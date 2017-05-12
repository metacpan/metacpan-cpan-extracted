package Test::BSON;

use 5.006;
use strict;
use parent 'Test::Builder::Module';
use English qw( -no_match_vars );
use Carp;
use BSON;
use Test::Differences;

our $VERSION   = '0.01';
our @EXPORT    = qw( bson_ok bson_is );
our @EXPORT_OK = qw( is_valid_bson is_bson );

*is_valid_bson = \&bson_ok;
*is_bson       = \&bson_is;

sub bson_ok ($;$) {
    my ($input, $test_name) = @_;
    my $test = __PACKAGE__->builder;

    croak 'usage: bson_ok(input, test_name)'
        if !defined $input;

    eval { BSON::decode($input) };

    if (my $error = $EVAL_ERROR) {
        $test->ok(0, $test_name);
        $test->diag("Input was not valid BSON: $error");
        return;
    }

    $test->ok(1, $test_name);
    return 1;
}

sub bson_is ($$;$) {
    my ($input, $expected, $test_name) = @_;
    my $test = __PACKAGE__->builder;
    my %result_for;

    croak 'usage: bson_is(input, expected, test_name)'
        if !defined $input || !defined $expected;

    for my $item (
        { key => 'input',    value => $input    },
        { key => 'expected', value => $expected },
    ) {
        $result_for{ $item->{key} } = eval { BSON::decode( $item->{value} ) };

        if (my $error = $EVAL_ERROR) {
            $test->ok(0, $test_name);
            $test->diag(ucfirst "$item->{key} was not valid BSON: $error");
            return;
        }
    }

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    return eq_or_diff($result_for{input}, $result_for{expected}, $test_name);
}

1;

__END__

=encoding utf8

=head1 NAME

Test::BSON - Test BSON documents

=head1 VERSION

This document describes Test::BSON version 0.01.

=cut

=head1 SYNOPSIS

   use Test::BSON;

   bson_ok $bson,                 'BSON is valid';
   bson_is $bson, $expected_bson, 'BSON matches what we expected';

=head1 DESCRIPTION

BSON is a binary-encoded extension of JSON.  Test::BSON makes it easy to
verify that you have built a valid BSON document and that it matches what you
expected.

=head1 EXPORTED TESTS

=head2 bson_ok

Test passes if the BSON document is valid.

   bson_ok $bson, 'BSON is valid';

C<is_valid_bson> is provided as an alternative to C<bson_ok> using the same
naming convention as L<Test::JSON> but is not exported by default.

=head2 bson_is

Test passes if the two BSON documents are valid and evaluate to the same data
structure.

   bson_is $bson, $expected_bson, 'BSON matches what we expected';

L<Test::Differences> is used to provide easy diagnostics of why the BSON
documents did not match.  For example:

      Failed test 'BSON matches what we expected'
      in t/bson.t at line 10.
    +----+----------------+----------------+
    | Elt|Got             |Expected        |
    +----+----------------+----------------+
    |   0|{               |{               |
    |   1|  BSON => [     |  BSON => [     |
    *   2|    'AWSUM!!',  |    'awesome',  *
    |   3|    '5.05',     |    '5.05',     |
    *   4|    1984        |    1986        *
    |   5|  ]             |  ]             |
    |   6|}               |}               |
    +----+----------------+----------------+

C<is_bson> is provided as an alternative to C<bson_is> using the same naming
convention as L<Test::JSON> but is not exported by default.

=head1 SEE ALSO

This module uses L<BSON> and L<Test::Differences>, and is based on
L<Test::JSON>.  Learn more about BSON at L<http://bsonspec.org/>.

=head1 AUTHOR

Nick Patch <patch@cpan.org>

=head1 ACKNOWLEDGEMENTS

This module was forked from L<Test::JSYNC>, which was forked from
L<Test::JSON> authored by Curtis “Ovid” Poe.

=head1 COPYRIGHT & LICENSE

© 2011–2012 Nick Patch

© 2005–2007 Curtis “Ovid” Poe

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
