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

Version 0.91

=cut

our $VERSION = '0.91';

=head1 SYNOPSIS

    use Struct::Diff qw(diff list_diff patch split_diff valid_diff);

    $a = {x => [7,{y => 4}]};
    $b = {x => [7,{y => 9}],z => 33};

    $diff = diff($a, $b, noO => 1, noU => 1); # omit unchanged items and old values
    # $diff == {D => {x => {D => [{I => 1,N => {y => 9}}]},z => {A => 33}}}

    @list_diff = list_diff($diff); # list (path and ref pairs) all diff entries
    # $list_diff == [[{keys => ['z']}],\{A => 33},[{keys => ['x']},[0]],\{I => 1,N => {y => 9}}]

    $splitted = split_diff($diff);
    # $splitted->{a} # not exists
    # $splitted->{b} == {x => [{y => 9}],z => 33}

    patch($a, $diff); # $a now equal to $b by structure and data

    @errors = valid_diff($diff);

=head1 EXPORT

Nothing is exported by default.

=head1 DIFF METADATA FORMAT

Diff is simply a HASH whose keys shows status for each item in passed structures.

=over 4

=item A

Stands for 'added' (exists only in second structure), it's value - added item.

=item D

Means 'different' and contains subdiff.

=item I

Index for changed array item.

=item N

Is a new value for changed item.

=item O

Alike C<N>, C<O> is a changed item's old value.

=item R

Similar for C<A>, but for removed items.

=item U

Represent unchanged items.

=back

=head1 SUBROUTINES

=head2 diff

Returns hashref to recursive diff between two passed things. Beware when
changing diff: some of it's substructures are links to original structures.

    $diff = diff($a, $b, %opts);
    $patch = diff($a, $b, noU => 1, noO => 1, trimR => 1); # smallest possible diff

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
    my ($a, $b, %opts) = @_;

    my $d = {};
    local $Storable::canonical = 1; # for equal snapshots for equal by data hashes
    local $Storable::Deparse = 1;

    if (ref $a ne ref $b) {
        $d->{O} = $a unless ($opts{noO});
        $d->{N} = $b unless ($opts{noN});
    } elsif (ref $a eq 'ARRAY' and $a != $b) {
        my @sd = sdiff($a, $b, sub { freeze \$_[0] });
        my ($s, $hidden, $item);

        for my $i (0 .. $#sd) {
            undef $item;
            if ($sd[$i]->[0] eq 'u') {
                $item->{U} = $sd[$i]->[1] unless ($opts{noU});
            } elsif ($sd[$i]->[0] eq 'c') {
                $item = diff($sd[$i]->[1], $sd[$i]->[2], %opts);
            } elsif ($sd[$i]->[0] eq '+') {
                $item->{A} = $sd[$i]->[2] unless ($opts{noA});
            } else { # '-'
                $item->{R} = $opts{trimR} ? undef : $sd[$i]->[1]
                    unless ($opts{noR});
            }

            if ($item) {
                map { $s->{$_} = 1 } keys %{$item};
                $item->{I} = $i if ($hidden);
                push @{$d->{D}}, $item;
            } else {
                $hidden = 1;
            }
        }

        if ((my @k = keys %{$s}) == 1 and not ($hidden or exists $s->{D})) { # all items have same status
            map { $_ = $_->{$k[0]} } @{$d->{D}};
            $d->{$k[0]} = delete $d->{D};
        }

        $d->{U} = $a unless ($hidden or keys %{$d});
    } elsif (ref $a eq 'HASH' and $a != $b) {
        my @keys = keys %{{ %{$a}, %{$b} }}; # uniq keys for both hashes
        return $opts{noU} ? {} : { U => {} } unless (@keys);

        my ($alt, $sd);
        for my $key (@keys) {
            if (exists $a->{$key} and exists $b->{$key}) {
                if (freeze(\$a->{$key}) eq freeze(\$b->{$key})) {
                    $d->{U}->{$key} = $alt->{D}->{$key}->{U} = $a->{$key}
                        unless ($opts{noU});
                } else {
                    $sd = diff($a->{$key}, $b->{$key}, %opts);
                    if (exists $sd->{D}) {
                        $d->{D}->{$key} = $alt->{D}->{$key} = $sd;
                    } else {
                        map {
                            $d->{$_}->{$key} = $alt->{D}->{$key}->{$_} = $sd->{$_}
                        } keys %{$sd};
                    }
                }
            } elsif (exists $a->{$key}) {
                $d->{R}->{$key} = $alt->{D}->{$key}->{R} =
                    $opts{trimR} ? undef : $a->{$key}
                        unless ($opts{noR});
            } else {
                $d->{A}->{$key} = $alt->{D}->{$key}->{A} = $b->{$key}
                    unless ($opts{noA});
            }
        }

        $d = $alt # return 'D' version of diff
            if (keys %{$d} > 1 or ($sd) = values %{$d} and keys %{$sd} != @keys);
    } elsif (ref $a eq 'Regexp' and $a != $b) {
        if ($a eq $b) {
            $d->{U} = $a unless ($opts{noU});
        } else {
            $d->{O} = $a unless ($opts{noO});
            $d->{N} = $b unless ($opts{noN});
        }
    } elsif (ref $a ? $a == $b || freeze($a) eq freeze($b) : freeze(\$a) eq freeze(\$b)) {
        $d->{U} = $a unless ($opts{noU});
    } else {
        $d->{O} = $a unless ($opts{noO});
        $d->{N} = $b unless ($opts{noN});
    }

    return $d;
}

=head2 list_diff

List pairs (path, ref_to_subdiff) for provided diff. See
L<Struct::Path/ADDRESSING SCHEME> for path format specification.

    @list = list_diff(diff($frst, $scnd);

=head3 Options

=over 4

=item depth E<lt>intE<gt>

Don't dive deeper than defined number of levels.

=item sort E<lt>sub|true|falseE<gt>

Defines how to handle hash subdiffs. Keys will be picked randomely (default
C<keys> behavior), sorted by provided subroutine (if value is a coderef) or
lexically sorted if set to some other true value.

=back

=cut

sub list_diff($;@) {
    my ($tmp, %opts) = @_;
    $opts{depth} = 0 unless ($opts{depth});

    my @stack = ([], \$tmp); # init: (path, diff)
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

    $structs = split_diff(diff($a, $b));
    # $structs->{a}: items originated from $a
    # $structs->{b}: same for $b

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

    patch($a, $diff);

=cut

sub patch($$) {
    my @stack = @_;
    my ($s, $d, $i);

    while (@stack) {
        ($s, $d) = splice @stack, 0, 2;

        if (exists $d->{D}) {
            if (ref $d->{D} eq 'ARRAY') {
                for (0 .. $#{$d->{D}}) {
                    $i = exists $d->{D}->[$_]->{I} ? $d->{D}->[$_]->{I} : $_; # use provided index
                    if (exists $d->{D}->[$_]->{D} or exists $d->{D}->[$_]->{N}) {
                        push @stack,
                            (ref $s->[$i] ? $s->[$i] : \$s->[$i]), $d->{D}->[$_];
                    } elsif (exists $d->{D}->[$_]->{A}) {
                        splice @{$s}, $i, 1, (@{$s} > $i
                            ? ($d->{D}->[$_]->{A}, $s->[$i])
                            : $d->{D}->[$_]->{A});
                    } elsif (exists $d->{D}->[$_]->{R}) {
                        splice @{$s}, $i, 1;
                    }
                }
            } else { # HASH
                for (keys %{$d->{D}}) {
                    if (exists $d->{D}->{$_}->{D} or exists $d->{D}->{$_}->{N}) {
                        push @stack,
                            (ref $s->{$_} ? $s->{$_} : \$s->{$_}), $d->{D}->{$_};
                    } elsif (exists $d->{D}->{$_}->{A}) {
                        $s->{$_} = $d->{D}->{$_}->{A};
                    } elsif (exists $d->{D}->{$_}->{R}) {
                        delete $s->{$_};
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

Only arrays and hashes traversed. All other data types compared by their
references or content.

No object oriented interface provided.

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
