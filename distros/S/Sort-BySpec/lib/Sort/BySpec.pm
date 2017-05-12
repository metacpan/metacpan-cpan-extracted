package Sort::BySpec;

our $DATE = '2017-02-17'; # DATE
our $VERSION = '0.03'; # VERSION

use 5.010001;
use strict 'subs', 'vars';
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(sort_by_spec cmp_by_spec);

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Sort array (or create a list sorter) according to '.
        'specification',
};

$SPEC{sort_by_spec} = {
    v => 1.1,
    summary => 'Sort array (or create a list sorter) according to '.
        'specification',
    description => <<'_',


_
    args => {
        spec => {
            schema => 'array*',
            req => 1,
            pos => 0,
        },
        xform => {
            schema => 'code*',
            summary => 'Code to return sort keys from data elements',
            description => <<'_',

This is just like `xform` in `Sort::ByExample`.

_
        },
        reverse => {
            summary => 'If set to true, will reverse the sort order',
            schema => ['bool*', is=>1],
        },
        array => {
            schema => 'array*',
        },
    },
    result => {
        summary => 'Sorted array, or sort coderef',
        schema => ['any*', of=>['array*','code*']],
        description => <<'_',

If array is specified, will returned the sorted array. If array is not specified
in the argument, will return a sort subroutine that can be used to sort a list
and return the sorted list.

_
    },
    result_naked => 1,
    examples => [
        {
            summary => 'Sort according to a sequence of scalars (like Sort::ByExample)',
            args => {
                spec => ['foo', 'bar', 'baz'],
                array => [1, 2, 3, 'bar', 'a', 'b', 'c', 'baz'],
            },
        },
        {
            summary => 'Like previous example, but reversed',
            args => {
                spec => ['foo', 'bar', 'baz'],
                array => [1, 2, 3, 'bar', 'a', 'b', 'c', 'baz'],
                reverse => 1,
            },
        },
        {
            summary => 'Put integers first (in descending order), then '.
                'a sequence of scalars, then others (in ascending order)',
            args => {
                spec => [
                    qr/\A\d+\z/ => sub { $_[1] <=> $_[0] },
                    'foo', 'bar', 'baz',
                    qr// => sub { $_[0] cmp $_[1] },
                ],
                array => ["qux", "b", "a", "bar", "foo", 1, 10, 2],
            },
        },
    ],
};
sub sort_by_spec {
    my %args = @_;

    my $spec  = $args{spec};
    my $xform = $args{xform};

    my $code_get_rank = sub {
        my $val = shift;

        my $j;
        for my $which (0..2) { # 0=scalar, 1=regexp, 2=code
            $j = -1;
            while ($j < $#{$spec}) {
                $j++;
                my $spec_elem = $spec->[$j];
                my $ref = ref($spec_elem);
                if (!$ref) {
                    if ($which == 0 && $val eq $spec_elem) {
                        return($j);
                    }
                } elsif ($ref eq 'Regexp') {
                    my $sortsub;
                    if ($j < $#{$spec} && ref($spec->[$j+1]) eq 'CODE') {
                        $sortsub = $spec->[$j+1];
                    }
                    if ($which == 1 && $val =~ $spec_elem) {
                        return($j, $sortsub);
                    }
                    $j++ if $sortsub;
                } elsif ($ref eq 'CODE') {
                    my $sortsub;
                    if ($j < $#{$spec} && ref($spec->[$j+1]) eq 'CODE') {
                        $sortsub = $spec->[$j+1];
                    }
                    if ($which == 2 && $spec_elem->($val)) {
                        return($j, $sortsub);
                    }
                    $j++ if $sortsub;
                } else {
                    die "Invalid spec[$j]: not a scalar/Regexp/code";
                }
            } # loop element of spec
        } # which
        return($j+1);
    };

    if ($args{_return_cmp}) {
        my $cmp = sub {
            my ($a, $b);

            if (@_ >= 2) {
                $a = $_[0];
                $b = $_[1];
            } else {
                my $caller = caller();
                $a = ${"caller\::a"};
                $b = ${"caller\::b"};
            }

            if ($xform) {
                $a = $xform->($a);
                $b = $xform->($b);
            }

            if ($args{reverse}) {
                ($a, $b) = ($b, $a);
            }

            my ($rank_a, $sortsub) = $code_get_rank->($a);
            my ($rank_b          ) = $code_get_rank->($b);

            if ($rank_a != $rank_b) {
                return $rank_a <=> $rank_b;
            }
            return 0 unless $sortsub;
            return $sortsub->($a, $b);
        };
        return $cmp;
    } else {
        # use schwartzian transform to speed sorting longer lists
        my $sorter = sub {
            return map { $_->[0] }
                sort {
                    $a->[2] <=> $b->[2] ||
                        ($a->[3] ? $a->[3]($a->[1], $b->[1]) : 0) }
                    map {
                        my $x = $xform ? $xform->($_) : $_;
                        [$_, $x, $code_get_rank->($x)]
                    } @_;
        };

        if ($args{array}) {
            return [$sorter->(@{ $args{array} })];
        }
        return $sorter;
    }
}

$SPEC{cmp_by_spec} = do {
    # poor man's "clone"
    my $meta = { %{ $SPEC{sort_by_spec} } };
    $meta->{summary} = 'Create a compare subroutine to be used in sort()';
    $meta->{args} = { %{$meta->{args}} };
    delete $meta->{args}{array};
    $meta->{result} = {
        schema => ['code*'],
    };
    delete $meta->{examples};
    $meta;
};
sub cmp_by_spec {
    sort_by_spec(
        @_,
        _return_cmp => 1,
    );
}

1;
# ABSTRACT: Sort array (or create a list sorter) according to specification

__END__

=pod

=encoding UTF-8

=head1 NAME

Sort::BySpec - Sort array (or create a list sorter) according to specification

=head1 VERSION

This document describes version 0.03 of Sort::BySpec (from Perl distribution Sort-BySpec), released on 2017-02-17.

=head1 SYNOPSIS

 use Sort::BySpec qw(sort_by_spec cmp_by_spec);

 my $sorter = sort_by_spec(spec => [
     # put odd numbers first, in ascending order
     qr/[13579]\z/ => sub { $_[0] <=> $_[1] },

     # then put specific numbers here, in this order
     4, 2, 42,

     # put even numbers last, in descending order
     sub { $_[0] % 2 == 0 } => sub { $_[1] <=> $_[0] },
 ]);

 my @res = $sorter->(1..15, 42);
 # => (1,3,5,7,9,11,13,15,  4,2,42,   14,12,10,8,6)

=head1 DESCRIPTION

This package provides a more powerful alternative to L<Sort::ByExample>. Unlike
in `Sort::ByExample` where you only provide a single array of example, you can
specify multiple examples as well as regex or matcher subroutine coupled with
sort rules. With this, you can more precisely specify how elements of your list
should be ordered. If your needs are not met by Sort::ByExample, you might want
to consider this package. The downside is performance penalty, especially when
your list is large.

To sort using Sort::BySpec, you provide a "spec" which is an array of strings,
regexes, or coderefs to match against elements of your list to be sorted. In the
simplest form, the spec contains only a list of examples:

 my $sorter = sort_by_spec(spec => ["foo", "bar", "baz"]); # [1]

and this is equivalent to Sort::ByExample:

 my $sorter = sbe(["foo", "bar", "baz"]);

You can also specify regex to match elements. This is evaluated after strings,
so this work:

 my $sorter = sort_by_spec(spec => [qr/o/, "foo", "bar", "baz", qr/a/]);
 my @list = ("foo", "food", "bar", "back", "baz", "fool", "boat");
 my @res = $sorter->(@list);
 # => ("food","boat","fool",   "foo","bar","baz",   "back")

Right after a regex, you can optionally specify a sort subroutine to tell how to
sort elements matching that regex, for example:

 my $sorter = sort_by_spec(spec => [
     qr/o/ => sub { $_[0] cmp $_[1] },
     "foo", "bar", "baz",
     qr/a/
 ]);

 # the same list @list above will now be sorted into:
 # => ("boat","food","fool",   "foo","bar","baz",   "back")

Note that instead of C<$a> and C<$b>, you should use C<$_[0]> and C<$_[1]>
respectively. This avoids the package scoping issue of C<$a> and C<$b>, making
your sorter subroutine works everywhere without any special workaround.

Finally, aside from strings and regexes, you can also specify a coderef matcher
for more complex matching:

 my $sorter = sort_by_spec(spec => [
     # put odd numbers first, in ascending order
     sub { $_[0] % 2 } => sub { $_[0] <=> $_[1] },

     # then put specific numbers here, in this order
     4, 2, 42,

     # put even numbers last, in descending order
     sub { $_[0] % 2 == 0 } => sub { $_[1] <=> $_[0] },
 ]);

 my @res = $sorter->(1..15, 42);
 # => (1,3,5,7,9,11,13,15,  4,2,42,   14,12,10,8,6)

=head1 FUNCTIONS


=head2 cmp_by_spec

Usage:

 cmp_by_spec(%args) -> code

Create a compare subroutine to be used in sort().

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<reverse> => I<bool>

If set to true, will reverse the sort order.

=item * B<spec>* => I<array>

=item * B<xform> => I<code>

Code to return sort keys from data elements.

This is just like C<xform> in C<Sort::ByExample>.

=back

Return value:  (code)


=head2 sort_by_spec

Usage:

 sort_by_spec(%args) -> array|code

Sort array (or create a list sorter) according to specification.

Examples:

=over

=item * Sort according to a sequence of scalars (like Sort::ByExample):

 sort_by_spec(
 spec  => ["foo", "bar", "baz"],
   array => [1, 2, 3, "bar", "a", "b", "c", "baz"]
 );

Result:

 ["bar", "baz", 1, 2, 3, "a", "b", "c"]

=item * Like previous example, but reversed:

 sort_by_spec(
 spec    => ["foo", "bar", "baz"],
   array   => [1, 2, 3, "bar", "a", "b", "c", "baz"],
   reverse => 1
 );

Result:

 ["bar", "baz", 1, 2, 3, "a", "b", "c"]

=item * Put integers first (in descending order), then a sequence of scalars, then others (in ascending order):

 sort_by_spec(
 spec  => [
              qr/\A\d+\z/,
              sub { $_[1] <=> $_[0] },
              "foo",
              "bar",
              "baz",
              qr//,
              sub { $_[0] cmp $_[1] },
            ],
   array => ["qux", "b", "a", "bar", "foo", 1, 10, 2]
 );

Result:

 [10, 2, 1, "foo", "bar", "a", "b", "qux"]

=back

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<array> => I<array>

=item * B<reverse> => I<bool>

If set to true, will reverse the sort order.

=item * B<spec>* => I<array>

=item * B<xform> => I<code>

Code to return sort keys from data elements.

This is just like C<xform> in C<Sort::ByExample>.

=back

Return value: Sorted array, or sort coderef (array|code)


If array is specified, will returned the sorted array. If array is not specified
in the argument, will return a sort subroutine that can be used to sort a list
and return the sorted list.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sort-BySpec>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sort-BySpec>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sort-BySpec>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Sort::ByExample>

L<Bencher::Scenario::SortBySpec>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
