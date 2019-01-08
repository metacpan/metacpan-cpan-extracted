package Struct::Diff;

use 5.006;
use strict;
use warnings FATAL => 'all';
use parent qw(Exporter);

use Algorithm::Diff qw(LCSidx);
use Carp qw(croak);
use Scalar::Util qw(looks_like_number);
use Storable 2.05 qw(freeze);

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

Version 0.98

=cut

our $VERSION = '0.98';

=head1 SYNOPSIS

    use Struct::Diff qw(diff list_diff split_diff patch valid_diff);

    $x = {one => [1,{two => 2}]};
    $y = {one => [1,{two => 9}],three => 3};

    $diff = diff($x, $y, noO => 1, noU => 1); # omit unchanged items and old values
    # $diff == {D => {one => {D => [{D => {two => {N => 9}},I => 1}]},three => {A => 3}}}

    @list_diff = list_diff($diff); # list (path and ref pairs) all diff entries
    # @list_diff == ({K => ['one']},[1],{K => ['two']}],\{N => 9},[{K => ['three']}],\{A => 3})

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
calculation. Disabling some or other types produce different diffs: diff with
only unchanged items is also possible (when all other types disabled).

=over 4

=item A

Stands for 'added' (exist only in second structure), it's value - added item.

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

Diff format: metadata alternates with data and, as a result, diff may
represent any structure of any data types. Simple types specified as is,
arrays and hashes contain subdiffs for their items with native for such types
addressing: indexes for arrays and keys for hashes.

Sample:

    old:  {one => [5,7]}
    new:  {one => [5],two => 2}
    opts: {noU => 1} # omit unchanged items

    diff:
    {D => {one => {D => [{I => 1,R => 7}]},two => {A => 2}}}
    ||    | |     ||    |||    | |    |     |     ||    |
    ||    | |     ||    |||    | |    |     |     ||    +- with value 2
    ||    | |     ||    |||    | |    |     |     |+- key 'two' was added (A)
    ||    | |     ||    |||    | |    |     |     +- subdiff for it
    ||    | |     ||    |||    | |    |     +- another key from top-level hash
    ||    | |     ||    |||    | |    +- what it was (item's value: 7)
    ||    | |     ||    |||    | +- what happened to item (R - removed)
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

Returns recursive diff for two passed things.

    $diff  = diff($x, $y, %opts);
    $patch = diff($x, $y, noU => 1, noO => 1, trimR => 1); # smallest diff

Beware changing diff: it's parts are references to substructures of passed
arguments.

=head3 Options

=over 4

=item freezer C<< <sub> >>

Serializer callback (redefines default serializer). L<Storable/freeze> is used
by default, see L</CONFIGURATION VARIABLES> for details.

=item noX C<< <true|false> >>

Where X is a status (C<A>, C<N>, C<O>, C<R>, C<U>); such status will be
omitted.

=item trimR C<< <true|false> >>

Drop removed item's data.

=back

=cut

our $FREEZER = sub {
    local $Storable::canonical = 1; # for equal snapshots for equal by data hashes
    local $Storable::Deparse = 1;   # for coderefs

    freeze \$_[0];
};

sub diff($$;@) {
    my ($x, $y, %opts) = @_;

    $opts{freezer} = $FREEZER unless (exists $opts{freezer});

    _diff($x, $y, %opts);
}

sub _diff($$;@);
sub _diff($$;@) {
    my ($x, $y, %opts) = @_;

    my $d = {};
    my $type = ref $x;

    if ($type ne ref $y) {
        $d->{O} = $x unless ($opts{noO});
        $d->{N} = $y unless ($opts{noN});
    } elsif ($type eq 'ARRAY' and $x != $y) {
        my ($lcs, $stat) = _lcs_diff($x, $y, $opts{freezer});

        if ($stat->{U} * 3 == @{$lcs}) {
            $d->{U} = $y unless ($opts{noU});
        } else {
            my ($I, $xi, $yi, $op, $sd) = 0;

            while (@{$lcs}) {
                ($op, $xi, $yi) = splice @{$lcs}, 0, 3;

                if ($op eq 'U') {
                    if ($opts{noU}) { $I++; next }
                    push @{$d->{D}}, { U => $y->[$yi] };
                } elsif ($op eq 'D') {
                    $sd = _diff($x->[$xi], $y->[$yi], %opts);
                    unless (keys %{$sd}) { $I++; next }
                    push @{$d->{D}}, $sd;
                } elsif ($op eq 'A') {
                    if ($opts{noA}) { $I++; next }
                    push @{$d->{D}}, { A => $y->[$yi] };
                } else {
                    if ($opts{noR}) { $I++; next }
                    push @{$d->{D}}, { R => $opts{trimR} ? undef : $x->[$xi] };
                }

                if ($I) {
                    $d->{D}->[-1]->{I} = $xi;
                    $I = 0;
                }
            }
        }
    } elsif ($type eq 'HASH' and $x != $y) {
        my @keys = keys %{{ %{$x}, %{$y} }}; # uniq keys for both hashes
        return $opts{noU} ? {} : { U => {} } unless (@keys);

        for my $k (@keys) {
            if (exists $x->{$k} and exists $y->{$k}) {
                if ($opts{freezer}($x->{$k}) eq $opts{freezer}($y->{$k})) {
                    $d->{U}->{$k} = $y->{$k} unless ($opts{noU});
                } else {
                    my $sd = _diff($x->{$k}, $y->{$k}, %opts);
                    $d->{D}->{$k} = $sd if (keys %{$sd});
                }
            } elsif (exists $x->{$k}) {
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
    } elsif ($type && $x == $y || $opts{freezer}($x) eq $opts{freezer}($y)) {
        $d->{U} = $x unless ($opts{noU});
    } else {
        $d->{O} = $x unless ($opts{noO});
        $d->{N} = $y unless ($opts{noN});
    }

    return $d;
}

sub _lcs_diff {
    my ($xm, $ym) = LCSidx(@_);
    my ($xi, $yi, @diff, %stat) = (0, 0);

    # additional unchanged items to collect trailing non-matched
    push @{$xm}, scalar @{$_[0]};
    push @{$ym}, scalar @{$_[1]};

    while (@{$xm}) {
        if ($xi == $xm->[0] and $yi == $ym->[0]) {
            push @diff, 'U', shift @{$xm}, shift @{$ym};
            $xi++; $yi++;
            $stat{U}++;
        } elsif ($xi < $xm->[0] and $yi < $ym->[0]) {
            push @diff, 'D', $xi++, $yi++;
            $stat{N}++;
        } elsif ($xi < $xm->[0]) {
            push @diff, 'R', $xi++, $yi;
            $stat{R}++;
        } else {
            push @diff, 'A', $xi, $yi++;
            $stat{A}++;
        }
    }

    $stat{O} = $stat{N} if (exists $stat{N});

    # remove added above trailing item
    splice @diff, -3, 3;
    $stat{U}--;

    return \@diff, \%stat;
}

=head2 list_diff

List all pairs (path-to-subdiff, ref-to-subdiff) for provided diff. See
L<Struct::Path/ADDRESSING SCHEME> for path format specification.

    @list = list_diff($diff);

=head3 Options

=over 4

=item depth C<< <int> >>

Don't dive deeper than defined number of levels; C<undef> used by default
(unlimited).

=item sort C<< <sub|true|false> >>

Defines how to handle hash subdiffs. Keys will be picked randomly (default
C<keys> behavior), sorted by provided subroutine (if value is a coderef) or
lexically sorted if set to some other true value.

=back

=cut

sub list_diff($;@) {
    my @stack = ([], \shift); # init: (path, diff)
    my %opts = @_;
    my ($diff, @list, $path, $I);

    while (@stack) {
        ($path, $diff) = splice @stack, -2, 2;

        if (!exists ${$diff}->{D} or $opts{depth} and @{$path} >= $opts{depth}) {
            unshift @list, $path, $diff;
        } elsif (ref ${$diff}->{D} eq 'ARRAY') {
            $I = 0;
            for (@{${$diff}->{D}}) {
                $I = $_->{I} if (exists $_->{I}); # use provided index
                push @stack, [@{$path}, [$I]], \$_;
                $I++;
            }
        } else { # HASH
            map {
                push @stack, [@{$path}, {K => [$_]}], \${$diff}->{D}->{$_}
            } $opts{sort}
                ? ref $opts{sort} eq 'CODE'
                    ? $opts{sort}(keys %{${$diff}->{D}})
                    : sort keys %{${$diff}->{D}}
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

            $out{a} = [] unless (exists $out{a});
            $out{b} = [] unless (exists $out{b});
        } else { # HASH
            for (keys %{$d->{D}}) {
                $sd = split_diff($d->{D}->{$_});
                $out{a}->{$_} = $sd->{a} if (exists $sd->{a});
                $out{b}->{$_} = $sd->{b} if (exists $sd->{b});
            }

            $out{a} = {} unless (exists $out{a});
            $out{b} = {} unless (exists $out{b});
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
            croak "Structure does not match" unless (ref ${$s} eq ref $d->{D});

            if (ref $d->{D} eq 'ARRAY') {
                my ($i, $j) = (0, 0); # target array idx, jitter

                for (@{$d->{D}}) {
                    $i = $_->{I} + $j if (exists $_->{I});

                    if (exists $_->{D} or exists $_->{N}) {
                        push @stack, \${$s}->[$i], $_;
                    } elsif (exists $_->{A}) {
                        splice @{${$s}}, $i, 0, $_->{A};
                        $j++;
                    } elsif (exists $_->{R}) {
                        splice @{${$s}}, $i, 1;
                        $j--;
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

Validate diff structure. In scalar context returns C<1> for valid diff,
C<undef> otherwise. In list context returns list of pairs (path, type) for
each error. See L<Struct::Path/ADDRESSING SCHEME> for path format
specification.

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
                    unshift @stack, [@{$path}, {K => [$_]}], $diff->{D}->{$_}
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

=head1 CONFIGURATION VARIABLES

=over 4

=item $Struct::Diff::FREEZER

Contains reference to default serialization function (C<diff()> rely on it
to determine data equivalency). L<Storable/freeze> with enabled
C<$Storable::canonical> and C<$Storable::Deparse> opts used by default.

L<Data::Dumper> is suitable for structures with regular expressions:

    use Data::Dumper;

    $Struct::Diff::FREEZER = sub {
        local $Data::Dumper::Deparse    = 1;
        local $Data::Dumper::Sortkeys   = 1;
        local $Data::Dumper::Terse      = 1;

        return Dumper @_;
    }

But comparing to L<Storable> it has two another issues: speed and unability
to distinguish numbers from their string representations.

=back

=head1 LIMITATIONS

Only arrays and hashes traversed. All other types compared by reference
addresses and serialized content.

L<Storable/freeze> (serializer used by default) will fail serializing compiled
regexps, so, consider to use other serializer if data contains regular
expressions. See L<CONFIGURATION VARIABLES> for details.

Struct::Diff will fail on structures with loops in references;
C<has_circular_ref> from L<Data::Structure::Util> can help to detect such
structures.

=head1 AUTHOR

Michael Samoglyadov, C<< <mixas at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-struct-diff at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Struct-Diff>. I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.

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
L<JSON::Patch>, L<JSON::MergePatch>, L<Struct::Diff::MergePatch>

L<Data::Structure::Util>, L<Struct::Path>, L<Struct::Path::PerlStyle>

=head1 LICENSE AND COPYRIGHT

Copyright 2015-2019 Michael Samoglyadov.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1; # End of Struct::Diff
