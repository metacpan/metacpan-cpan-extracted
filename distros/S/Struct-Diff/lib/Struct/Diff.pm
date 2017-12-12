package Struct::Diff;

use 5.006;
use strict;
use warnings FATAL => 'all';
use parent qw(Exporter);

use Scalar::Util qw(looks_like_number);
use Storable 2.05 qw(freeze);
use Algorithm::Diff qw(sdiff);

our @EXPORT_OK = qw(
    diff
    list_diff
    patch
    split_diff
    valid_diff
);

=head1 NAME

Struct::Diff - Recursive diff for nested perl structures

=begin html

<a href="https://travis-ci.org/mr-mixas/Struct-Diff.pm"><img src="https://travis-ci.org/mr-mixas/Struct-Diff.pm.svg?branch=master" alt="Travis CI"></a>
<a href='https://coveralls.io/github/mr-mixas/Struct-Diff.pm?branch=master'><img src='https://coveralls.io/repos/github/mr-mixas/Struct-Diff.pm/badge.svg?branch=master' alt='Coverage Status'/></a>
<a href="https://badge.fury.io/pl/Struct-Diff"><img src="https://badge.fury.io/pl/Struct-Diff.svg" alt="CPAN version"></a>

=end html

=head1 VERSION

Version 0.93

=cut

our $VERSION = '0.93';

=head1 SYNOPSIS

    use Struct::Diff qw(diff list_diff split_diff patch valid_diff);

    $x = {one => [1,{two => 2}]};
    $y = {one => [1,{two => 9}],three => 3};

    $diff = diff($x, $y, noO => 1, noU => 1); # omit unchanged items and old values
    # $diff == {D => {one => {D => [{D => {two => {N => 9}},I => 1}]},three => {A => 3}}}

    @list_diff = list_diff($diff); # list (path and ref pairs) all diff entries
    # @list_diff == ({keys => ['one']},[1],{keys => ['two']}],\{N => 9},[{keys => ['three']}],\{A => 3})

    $splitted = split_diff($diff);
    # $splitted->{a} # does not exist
    # $splitted->{b} == {one => [{two => 9}],three => 3}

    patch($x, $diff); # $x now equal to $y by structure and data

    @errors = valid_diff($diff);

=head1 EXPORT

Nothing is exported by default.

=head1 DIFF FORMAT

Diff is simply a HASH whose keys shows status for each item in passed
structures. Every status type (except C<D>) may be omitted during the diff
calculation. Disabling some or other types produces different diffs: diff for
unchanged types only also possible (if all other types disabled).

=over 4

=item A

Stands for 'added' (exists only in second structure), it's value - added item.

=item D

Means 'different' and contains subdiff. The only status type which can't be
disabled.

=item I

Index for array item, used only when prior item was omitted.

=item N

Is a new value for changed item.

=item O

Alike C<N>, C<O> is a changed item's old value.

=item R

Similar for C<A>, but for removed items.

=item U

Represent unchanged items.

=back

Diff format: metadata alternates with data therefore diff may represent any
structure of any data types. Simple types specified as is, arrays and hashes,
if changed, contains subdiffs with original for represented items addresses:
indexes for arrays and keys for hashes.

Sample:

    old:  {one => [5,7]}
    new:  {one => [5],two => 2}
    opts: unchanged items (U) omitted

    diff:
    {D => {one => {D => [{I => 1,R => 7}]},two => {A => 2}}}
    ||    | |     ||    |||    | |    |     |     ||    |
    ||    | |     ||    |||    | |    |     |     ||    +- with value 2
    ||    | |     ||    |||    | |    |     |     |+- it says key was added
    ||    | |     ||    |||    | |    |     |     +- subdiff for it
    ||    | |     ||    |||    | |    |     +- another key from top-level hash
    ||    | |     ||    |||    | |    +- what it was (item value - 7)
    ||    | |     ||    |||    | +- shows what happened to item (removed)
    ||    | |     ||    |||    +- array item's actual index
    ||    | |     ||    ||+- prior item was omitted
    ||    | |     ||    |+- subdiff for array item
    ||    | |     ||    +- it's value - ARRAY
    ||    | |     |+- it is deeply changed
    ||    | |     +- subdiff for key 'one'
    ||    | +- it has key 'one'
    ||    +- top-level thing is a HASH
    |+- changes somewhere deeply inside
    +- diff is always a HASH

=head1 SUBROUTINES

=head2 diff

Returns hashref to recursive diff between two passed things. Beware when
changing diff: it's parts are links to original structures.

    $diff  = diff($x, $y, %opts);
    $patch = diff($x, $y, noU => 1, noO => 1, trimR => 1); # smallest possible diff

=head3 Options

=over 4

=item noX

Where X is a status (C<A>, C<N>, C<O>, C<R>, C<U>); such status will be omitted.

=item trimR

Drop removed item's data.

=back

=cut

sub diff($$;@);
sub diff($$;@) {
    my ($x, $y, %opts) = @_;

    my $d = {};
    local $Storable::canonical = 1; # for equal snapshots for equal by data hashes
    local $Storable::Deparse = 1;

    if (ref $x ne ref $y) {
        $d->{O} = $x unless ($opts{noO});
        $d->{N} = $y unless ($opts{noN});
    } elsif (ref $x eq 'ARRAY' and $x != $y) {
        return $opts{noU} ? {} : { U => [] } unless (@{$x} or @{$y});

        my ($i, $I) = (-1, -1);
        for (sdiff($x, $y, sub { freeze \$_[0] })) {
            $i++;

            if ($_->[0] eq 'u') {
                unless ($opts{noU}) {
                    if (exists $d->{D}) {
                        push @{$d->{D}}, { U => $_->[1] };
                    } else { # nobody else - fill U version
                        push @{$d->{U}}, $_->[1];
                    }
                }
                next;
            } elsif (exists $d->{U}) { # diff should be converted to D type
                map { push @{$d->{D}}, { U => $_ } } @{delete $d->{U}};
            }

            if ($_->[0] eq 'c') {
                my $sd = diff($_->[1], $_->[2], %opts);
                push @{$d->{D}}, $sd if (keys %{$sd});
            } elsif ($_->[0] eq '+') {
                push @{$d->{D}}, { A => $_->[2] } unless ($opts{noA});
            } else { # '-'
                push @{$d->{D}}, { R => $opts{trimR} ? undef : $_->[1] }
                    unless ($opts{noR});
            }

            $d->{D}->[-1]->{I} = $I = $i
                if (exists $d->{D} and $#{$d->{D}} != $i and ++$I != $i);
        }
    } elsif (ref $x eq 'HASH' and $x != $y) {
        my @keys = keys %{{ %{$x}, %{$y} }}; # uniq keys for both hashes
        return $opts{noU} ? {} : { U => {} } unless (@keys);

        for my $k (@keys) {
            if (exists $x->{$k} and exists $y->{$k}) {
                if (freeze(\$x->{$k}) eq freeze(\$y->{$k})) {
                    $d->{U}->{$k} = $y->{$k} unless ($opts{noU});
                } else {
                    my $sd = diff($x->{$k}, $y->{$k}, %opts);
                    $d->{D}->{$k} = $sd if (keys %{$sd});
                }
                next;
            }

            if (exists $x->{$k}) {
                $d->{D}->{$k}->{R} = $opts{trimR} ? undef : $x->{$k}
                    unless ($opts{noR});
            } else {
                $d->{D}->{$k}->{A} = $y->{$k} unless ($opts{noA});
            }
        }

        if (exists $d->{U} and exists $d->{D}) {
            map { $d->{D}->{$_}->{U} = $d->{U}->{$_} } keys %{$d->{U}};
            delete $d->{U};
        }
    } elsif (ref $x eq 'Regexp' and $x != $y) {
        if ($x eq $y) {
            $d->{U} = $x unless ($opts{noU});
        } else {
            $d->{O} = $x unless ($opts{noO});
            $d->{N} = $y unless ($opts{noN});
        }
    } elsif (ref $x ? $x == $y || freeze($x) eq freeze($y) : freeze(\$x) eq freeze(\$y)) {
        $d->{U} = $x unless ($opts{noU});
    } else {
        $d->{O} = $x unless ($opts{noO});
        $d->{N} = $y unless ($opts{noN});
    }

    return $d;
}

=head2 list_diff

List pairs (path, ref_to_subdiff) for provided diff. See
L<Struct::Path/ADDRESSING SCHEME> for path format specification.

    @list = list_diff($diff);

=head3 Options

=over 4

=item depth E<lt>intE<gt>

Don't dive deeper than defined number of levels. C<undef> used by default
(unlimited).

=item sort E<lt>sub|true|falseE<gt>

Defines how to handle hash subdiffs. Keys will be picked randomely (default
C<keys> behavior), sorted by provided subroutine (if value is a coderef) or
lexically sorted if set to some other true value.

=back

=cut

sub list_diff($;@) {
    my @stack = ([], \shift); # init: (path, diff)
    my %opts = @_;
    my ($diff, @list, $path);

    while (@stack) {
        ($path, $diff) = splice @stack, 0, 2;

        if (!exists ${$diff}->{D} or $opts{depth} and @{$path} >= $opts{depth}) {
            push @list, $path, $diff;
        } elsif (ref ${$diff}->{D} eq 'ARRAY') {
            map {
                unshift @stack,
                    [@{$path},
                        [exists ${$diff}->{D}->[$_]->{I}
                            ? ${$diff}->{D}->[$_]->{I} # use provided index
                            : $_
                        ]
                    ],
                    \${$diff}->{D}->[$_]
            } reverse 0 .. $#{${$diff}->{D}};
        } else { # HASH
            map {
                unshift @stack, [@{$path}, {keys => [$_]}], \${$diff}->{D}->{$_}
            } $opts{sort}
                ? ref $opts{sort} eq 'CODE'
                    ? reverse $opts{sort}(keys %{${$diff}->{D}})
                    : reverse sort keys %{${$diff}->{D}}
                : keys %{${$diff}->{D}};
        }
    }

    return @list;
}

=head2 split_diff

Divide diff to pseudo original structures.

    $structs = split_diff(diff($x, $y));
    # $structs->{a}: items from $x
    # $structs->{b}: items from $y

=cut

sub split_diff($);
sub split_diff($) {
    my $d = $_[0];
    my (%out, $sd);

    if (exists $d->{D}) {
        if (ref $d->{D} eq 'ARRAY') {
            for (@{$d->{D}}) {
                $sd = split_diff($_);
                push @{$out{a}}, $sd->{a} if (exists $sd->{a});
                push @{$out{b}}, $sd->{b} if (exists $sd->{b});
            }
        } else { # HASH
            for (keys %{$d->{D}}) {
                $sd = split_diff($d->{D}->{$_});
                $out{a}->{$_} = $sd->{a} if (exists $sd->{a});
                $out{b}->{$_} = $sd->{b} if (exists $sd->{b});
            }
        }
    } elsif (exists $d->{U}) {
        $out{a} = $out{b} = $d->{U};
    } elsif (exists $d->{A}) {
        $out{b} = $d->{A};
    } elsif (exists $d->{R}) {
        $out{a} = $d->{R};
    } else {
        $out{b} = $d->{N} if (exists $d->{N});
        $out{a} = $d->{O} if (exists $d->{O});
    }

    return \%out;
}

=head2 patch

Apply diff.

    patch($target, $diff);

=cut

sub patch($$) {
    my @stack = (\$_[0], $_[1]); # ref to alias - to be able to change passed scalar

    while (@stack) {
        my ($s, $d) = splice @stack, 0, 2; # struct, subdiff

        if (exists $d->{D}) {
            if (ref $d->{D} eq 'ARRAY') {
                my ($i, $r) = (0, 0); # struct array idx, removed items counter

                for (@{$d->{D}}) {
                    $i = $_->{I} - $r if (exists $_->{I});

                    if (exists $_->{D} or exists $_->{N}) {
                        push @stack, \${$s}->[$i], $_;
                    } elsif (exists $_->{A}) {
                        splice @{${$s}}, $i, 1,
                            (@{${$s}} > $i ? ($_->{A}, ${$s}->[$i]) : $_->{A});
                    } elsif (exists $_->{R}) {
                        splice @{${$s}}, $i, 1;
                        $r++;
                        next; # don't increment $i
                    }

                    $i++;
                }
            } else { # HASH
                while (my ($k, $v) = each %{$d->{D}}) {
                    if (exists $v->{D} or exists $v->{N}) {
                        push @stack, \${$s}->{$k}, $v;
                    } elsif (exists $v->{A}) {
                        ${$s}->{$k} = $v->{A};
                    } elsif (exists $v->{R}) {
                        delete ${$s}->{$k};
                    }
                }
            }
        } elsif (exists $d->{N}) {
            ${$s} = $d->{N};
        }
    }
}

=head2 valid_diff

Validate diff structure. In scalar context returns C<1> for valid diff, C<undef>
otherwise. In list context returns list of pairs (path, type) for each error. See
L<Struct::Path/ADDRESSING SCHEME> for path format specification.

    @errors_list = valid_diff($diff); # list context

or

    $is_valid = valid_diff($diff); # scalar context

=cut

sub valid_diff($) {
    my @stack = ([], shift); # (path, diff)
    my ($diff, @errs, $path);

    while (@stack) {
        ($path, $diff) = splice @stack, 0, 2;

        unless (ref $diff eq 'HASH') {
            return undef unless wantarray;
            push @errs, $path, 'BAD_DIFF_TYPE';
            next;
        }

        if (exists $diff->{D}) {
            if (ref $diff->{D} eq 'ARRAY') {
                map {
                    unshift @stack, [@{$path}, [$_]], $diff->{D}->[$_]
                } 0 .. $#{$diff->{D}};
            } elsif (ref $diff->{D} eq 'HASH') {
                map {
                    unshift @stack, [@{$path}, {keys => [$_]}], $diff->{D}->{$_}
                } sort keys %{$diff->{D}};
            } else {
                return undef unless wantarray;
                unshift @errs, $path, 'BAD_D_TYPE';
            }
        }

        if (exists $diff->{I}) {
            if (!looks_like_number($diff->{I}) or int($diff->{I}) != $diff->{I}) {
                return undef unless wantarray;
                unshift @errs, $path, 'BAD_I_TYPE';
            }

            if (keys %{$diff} < 2) {
                return undef unless wantarray;
                unshift @errs, $path, 'LONESOME_I';
            }
        }
    }

    return wantarray ? @errs : 1;
}

=head1 LIMITATIONS

Struct::Diff fails on structures with loops in references. C<has_circular_ref>
from L<Data::Structure::Util> can help to detect such structures.

Only arrays and hashes traversed. All other data types compared by reference
addresses and content.

=head1 AUTHOR

Michael Samoglyadov, C<< <mixas at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-struct-diff at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Struct-Diff>. I will be notified,
and then you'll automatically be notified of progress on your bug as I make
changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Struct::Diff

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Struct-Diff>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Struct-Diff>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Struct-Diff>

=item * Search CPAN

L<http://search.cpan.org/dist/Struct-Diff/>

=back

=head1 SEE ALSO

L<Algorithm::Diff>, L<Data::Deep>, L<Data::Diff>, L<Data::Difference>,
L<JSON::MergePatch>

L<Data::Structure::Util>, L<Struct::Path>, L<Struct::Path::PerlStyle>

=head1 LICENSE AND COPYRIGHT

Copyright 2015-2017 Michael Samoglyadov.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1; # End of Struct::Diff
