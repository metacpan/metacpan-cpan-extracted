package Struct::Path;

use 5.006;
use strict;
use warnings FATAL => 'all';
use parent qw(Exporter);
use Carp qw(croak);

our @EXPORT_OK = qw(
    is_implicit_step
    slist
    spath
    spath_delta
);

=head1 NAME

Struct::Path - Path for nested structures where path is also a structure

=head1 VERSION

Version 0.65

=cut

our $VERSION = '0.65';

=head1 SYNOPSIS

    use Struct::Path qw(slist spath spath_delta);

    $s = [
        0,
        1,
        {
            '2a' => {
                '2aa' => '2aav',
                '2ab' => '2abv'
            }
        },
        undef
    ];

    @list = slist($s);                              # get all paths and their values
    # @list == (
    #    [[[0]],\0],
    #    [[[1]],\1],
    #    [[[2],{keys => ['2a']},{keys => ['2aa']}],\'2aav'],
    #    [[[2],{keys => ['2a']},{keys => ['2ab']}],\'2abv'],
    #    [[[3]],\undef]
    # )

    @r = spath($s, [ [3,0,1] ]);                    # get refs to values by paths
    # @r == (\undef, \0, \1)

    @r = spath($s, [ [2],{keys => ['2a']},{} ]);    # same, another example
    # @r == (\'2aav', \'2abv')

    @r = spath($s, [ [2],{},{regs => [qr/^2a/]} ]); # or using regular expressions
    # @r == (\'2aav', \'2abv')

    ${$r[0]} =~ s/2a/blah-blah-/;                   # replace substructire by path
    # $s->[2]{2a}{2aa} eq "blah-blah-av"

    @d = spath_delta([[0],[4],[2]], [[0],[1],[3]]); # new steps relatively for first path
    # @d == ([1],[3])

=head1 DESCRIPTION

Struct::Path provides functions to access/match/expand/list nested data structures.

Why existed *Path* modules (L</"SEE ALSO">) is not enough? Used scheme has no collisions
for paths like '/a/0/c' ('0' may be an ARRAY index or a key for HASH, depends on passed
structure). In some cases this is important, for example, when you want to define exact
path in structure, but unable to validate it's schema or when structure doesn't exists
yet (see L</expand> for example).

=head1 EXPORT

Nothing is exported by default.

=head1 ADDRESSING SCHEME

Path is a list of 'steps', each represents nested level in structure.

Arrayref as a step stands for ARRAY in structure and must contain desired indexes or be
empty (means "all items"). Sequence for indexes is important and defines result sequence.

Hashref represents HASH in the structure and may contain keys C<keys>, C<regs> or be
empty. C<keys> may contain list of desired keys, C<regs> must contain list of regular
expressions. Empty hash or empty list for C<keys> means all keys. Sequence in C<keys>
and C<regs> lists defines result sequence. C<keys> have higher priority than C<regs>.

Sample:

    $spath = [
        [1,7],
        {regs => qr/foo/}
    ];

Since v0.50 coderefs (filters) as steps supported as well. Path as first argument and stack
of references (arrayref) as second passed to it when executed. Some true (match) value or
false (doesn't match) value expected as output.

See L<Struct::Path::PerlStyle> if you're looking for human friendly path definition method.

=head1 SUBROUTINES

=head2 is_implicit_step

    $implicit = is_implicit_step($step);

Returns true value if step contains filter or specified all keys/items or key regexp match.

=cut

sub is_implicit_step {

    if (ref $_[0] eq 'ARRAY') {
        return 1 unless (@{$_[0]});
    } elsif (ref $_[0] eq 'HASH') {
        return 1 if (exists $_[0]->{regs} and @{$_[0]->{regs}});
        return 1 unless (exists $_[0]->{keys});
        return 1 unless (@{$_[0]->{keys}});
    } else { # coderefs
        return 1;
    }

    return undef;
}

=head2 slist

Returns list of paths and references to their values from structure.

    @list = slist($struct, %opts)

=head3 Available options

=over 4

=item depth C<< <N> >>

Don't dive into structure deeper than defined level.

=back

=cut

sub slist($;@) {
    my ($struct, %opts) = @_;

    my @in = [[], \$struct]; # init: [path, ref]
    return @in if (defined $opts{depth} and $opts{depth} < 1);

    my (@out, $p, @unres);

    while ($p = shift @in) {
        if (ref ${$p->[1]} eq 'HASH' and keys %{${$p->[1]}}) {
            for (sort keys %{${$p->[1]}}) {
                push @unres, [
                    [@{$p->[0]}, {keys => [$_]}],   # path
                    \${$p->[1]}->{$_}               # ref
                ];
            }
        } elsif (ref ${$p->[1]} eq 'ARRAY' and @{${$p->[1]}}) {
            for (0 .. $#{${$p->[1]}}) {
                push @unres, [
                    [@{$p->[0]}, [$_]],             # path
                    \${$p->[1]}->[$_]               # ref
                ];
            }
        } else {
            push @out, $p;
        }

        if (@unres) {
            if ($opts{depth} and @{$unres[0]->[0]} >= $opts{depth}) {
                push @out, splice @unres;
            } else {
                unshift @in, splice @unres; # iterate deeper
            }
        }
    }

    return @out;
}

=head2 spath

Returns list of references from structure.

    @list = spath($struct, $path, %opts)

=head3 Available options

=over 4

=item delete C<< <true|false> >>

Delete specified by path items from structure.

=item deref C<< <true|false> >>

Dereference result items.

=item expand C<< <true|false> >>

Expand structure if specified in path items does't exists. All newly created items initialized by C<undef>.

=item strict C<< <true|false> >>

Croak if at least one element, specified in path, absent in the struct.

=back

=cut

sub spath($$;@) {
    my ($struct, $path, %opts) = @_;

    croak "Path must be arrayref" unless (ref $path eq 'ARRAY');

    my @out = [[], [(ref $struct eq 'ARRAY' or ref $struct eq 'HASH' or not ref $struct) ? \$struct : $struct]];
    my $sc = 0; # step counter

    for my $step (@{$path}) {
        my @new;
        if (ref $step eq 'ARRAY') {
            while (my $r = shift @out) {
                unless (ref ${$r->[1]->[-1]} eq 'ARRAY') {
                    if ($opts{strict} or ($opts{expand} and defined ${$r->[1]->[-1]})) {
                        croak "Passed struct doesn't match provided path (array expected on step #$sc)";
                    } elsif (not $opts{expand}) {
                        next;
                    }
                }
                if (@{$step}) {
                    for my $i (@{$step}) {
                        unless ($opts{expand} or @{${$r->[1]->[-1]}} > $i) {
                            croak "[$i] doesn't exists (step #$sc)" if $opts{strict};
                            next;
                        }
                        push @new, [ [@{$r->[0]}, [$i]], [@{$r->[1]}, \${$r->[1]->[-1]}->[$i]] ];
                    }
                    if ($opts{delete} and $sc == $#{$path}) {
                        for my $i (reverse sort @{$step}) {
                            next if ($i > $#{${$r->[1]->[-1]}}); # skip out of range indexes (strict not enabled)
                            splice(@{${$r->[1]->[-1]}}, $i, 1);
                        }
                    }
                } else { # [] in the path
                    for (my $i = $#${$r->[1]->[-1]}; $i >= 0; $i--) {
                        unshift @new, [ [@{$r->[0]}, [$i]], [@{$r->[1]}, \${$r->[1]->[-1]}->[$i]] ];
                        splice(@{${$r->[1]->[-1]}}, $i) if ($opts{delete} and $sc == $#{$path});
                    }
                }
            }
        } elsif (ref $step eq 'HASH') {
            while (my $r = shift @out) {
                unless (ref ${$r->[1]->[-1]} eq 'HASH') {
                    if ($opts{strict} or ($opts{expand} and defined ${$r->[1]->[-1]})) {
                        croak "Passed struct doesn't match provided path (hash expected on step #$sc)";
                    } elsif (not $opts{expand}) {
                        next;
                    }
                }
                if (keys %{$step}) {
                    my (@keys, %stat);
                    for my $t ('keys', 'regs') {
                        next unless (exists $step->{$t});
                        croak "Unsupported HASH $t definition (step #$sc)"
                            unless (ref $step->{$t} eq 'ARRAY');
                        $stat{$t} = 1;

                        if ($t eq 'keys') {
                            for my $k (@{$step->{keys}}) {
                                unless ($opts{expand} or exists ${$r->[1]->[-1]}->{$k}) {
                                    croak "{$k} doesn't exists (step #$sc)" if $opts{strict};
                                    next;
                                }
                                push @keys, $k;
                            }
                        } else {
                            for my $g (@{$step->{regs}}) {
                                push @keys, grep { $_ =~ $g } keys %{${$r->[1]->[-1]}};
                            }
                        }
                    }
                    croak "Unsupported HASH definition (step #$sc)"
                        unless (keys %stat == keys %{$step});
                    for my $k (@keys) {
                        push @new, [ [@{$r->[0]}, {keys => [$k]}], [@{$r->[1]}, \${$r->[1]->[-1]}->{$k}] ];
                        delete ${$r->[1]->[-1]}->{$k} if ($opts{delete} and $sc == $#{$path});
                    }
                } else { # {} in the path
                    for my $k (keys %{${$r->[1]->[-1]}}) {
                        push @new, [ [@{$r->[0]}, {keys => [$k]}], [@{$r->[1]}, \${$r->[1]->[-1]}->{$k}] ];
                        delete ${$r->[1]->[-1]}->{$k}
                            if ($opts{delete} and $sc == $#{$path} and exists ${$r->[1]->[-1]}->{$k});
                    }
                }
            }
        } elsif (ref $step eq 'CODE') {
            map { $step->($_->[0], $_->[1]) and push(@new, $_) } @out;
        } else {
            croak "Unsupported thing in the path (step #$sc)";
        }
        @out = @new;
        $sc++;
    }

    map {
        $_->[1] = $opts{deref} ? ${pop @{$_->[1]}} : pop @{$_->[1]};
        $_ = $_->[1] unless ($opts{paths});
    } @out;

    return @out;
}

=head2 spath_delta

Returns delta for two passed paths. By delta means steps from the second path without beginning common steps for both.

    @delta = spath_delta($path1, $path2)

=cut

sub spath_delta($$) {
    my ($frst, $scnd) = @_;

    croak "Second path must be an arrayref" unless (ref $scnd eq 'ARRAY');
    return @{$scnd} unless (defined $frst);
    croak "First path may be undef or an arrayref" unless (ref $frst eq 'ARRAY');

    my $i = 0;

    MAIN:
    while ($i < @{$frst}) {
        last unless (ref $frst->[$i] eq ref $scnd->[$i]);
        if (ref $frst->[$i] eq 'ARRAY') {
            last unless (@{$frst->[$i]} == @{$scnd->[$i]});
            for my $j (0 .. $#{$frst->[$i]}) {
                last MAIN unless ($frst->[$i]->[$j] == $scnd->[$i]->[$j]);
            }
        } elsif (ref $frst->[$i] eq 'HASH') {
            last unless (@{$frst->[$i]->{keys}} == @{$scnd->[$i]->{keys}});
            for my $j (0 .. $#{$frst->[$i]->{keys}}) {
                last MAIN unless ($frst->[$i]->{keys}->[$j] eq $scnd->[$i]->{keys}->[$j]);
            }
        } else {
            croak "Unsupported thing in the path (step #$i)";
        }
        $i++;
    }

    return @{$scnd}[$i..$#{$scnd}];
}

=head1 LIMITATIONS

Struct::Path will fail on structures with loops in references.

No object oriented interface provided.

=head1 AUTHOR

Michael Samoglyadov, C<< <mixas at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-struct-path at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Struct-Path>. I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Struct::Path

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Struct-Path>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Struct-Path>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Struct-Path>

=item * Search CPAN

L<http://search.cpan.org/dist/Struct-Path/>

=back

=head1 SEE ALSO

L<Data::Diver> L<Data::DPath> L<Data::DRef> L<Data::Focus> L<Data::Hierarchy> L<Data::Nested> L<Data::PathSimple>
L<Data::Reach> L<Data::Spath> L<JSON::Path> L<MarpaX::xPathLike> L<Sereal::Path> L<Data::Find>

L<Struct::Diff> L<Struct::Path::PerlStyle>

=head1 LICENSE AND COPYRIGHT

Copyright 2016,2017 Michael Samoglyadov.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1; # End of Struct::Path
