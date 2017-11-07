package Struct::Path;

use 5.006;
use strict;
use warnings FATAL => 'all';
use parent 'Exporter';

use Carp 'croak';

our @EXPORT_OK = qw(
    is_implicit_step
    slist
    spath
    spath_delta
);

=head1 NAME

Struct::Path - Path for nested structures where path is also a structure

=begin html

<a href="https://travis-ci.org/mr-mixas/Struct-Path.pm"><img src="https://travis-ci.org/mr-mixas/Struct-Path.pm.svg?branch=master" alt="Travis CI"></a>
<a href='https://coveralls.io/github/mr-mixas/Struct-Path.pm?branch=master'><img src='https://coveralls.io/repos/github/mr-mixas/Struct-Path.pm/badge.svg?branch=master' alt='Coverage Status'/></a>
<a href="https://badge.fury.io/pl/Struct-Path"><img src="https://badge.fury.io/pl/Struct-Path.svg" alt="CPAN version"></a>

=end html

=head1 VERSION

Version 0.73

=cut

our $VERSION = '0.73';

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

    @list = slist($s);                              # list paths and values
    # @list == (
    #     [[0]], \0,
    #     [[1]], \1,
    #     [[2],{keys => ['2a']},{keys => ['2aa']}], \'2aav',
    #     [[2],{keys => ['2a']},{keys => ['2ab']}], \'2abv',
    #     [[3]], \undef
    # )

    @r = spath($s, [ [3,0,1] ]);                    # get refs to values
    # @r == (\undef, \0, \1)

    @r = spath($s, [ [2],{keys => ['2a']},{} ]);    # another example
    # @r == (\'2aav', \'2abv')

    @r = spath($s, [ [2],{},{regs => [qr/^2a/]} ]); # using regular expressions
    # @r == (\'2aav', \'2abv')

    ${$r[0]} =~ s/2a/blah-blah-/;                   # replace value
    # $s->[2]{2a}{2aa} eq "blah-blah-av"

    @d = spath_delta([[0],[4],[2]], [[0],[1],[3]]); # get steps delta
    # @d == ([1],[3])

=head1 DESCRIPTION

Struct::Path provides functions to access/match/expand/list nested data
structures.

Why L<existed Path modules|/"SEE ALSO"> is not enough? This module has no
conflicts for paths like '/a/0/c', where C<0> may be an array index or a key
for hash (depends on passed structure). In some cases this is important, for
example, when one need to define exact path in structure, but unable to
validate it's schema or when structure itself doesn't yet exist (see
L</spath/Options/expand> for example).

=head1 EXPORT

Nothing is exported by default.

=head1 ADDRESSING SCHEME

Path is a list of 'steps', each represents nested level in structure.

Arrayref as a step stands for ARRAY in the structure and must contain desired
indexes or be empty (means "all items"). Sequence for indexes is important
and defines result sequence.

Hashref represent HASH in the structure and may contain keys C<keys>, C<regs>
or be empty. C<keys> may contain list of desired keys, C<regs> must contain
list of regular expressions. Empty hash or empty list for C<keys> means all
keys. Sequence in C<keys> and C<regs> lists defines result sequence. C<keys>
have higher priority than C<regs>.

Coderef step is a hook - subroutine which may filter and/or modify
structure. Path as first argument and a stack (arrayref) of refs to traversed
subsstructures as second passed to it when executed, $_ set to current
substructure. Some true (match) value or false (doesn't match) value expected
as output.

Sample:

    $spath = [
        [1,7],                      # first spep
        {regs => qr/foo/}           # second step
        sub { exists $_->{bar} }    # third step
    ];

See L<Struct::Path::PerlStyle> if you're looking for human friendly path
definition method.

=head1 SUBROUTINES

=head2 is_implicit_step

    $implicit = is_implicit_step($step);

Returns true value if step contains hooks or specified 'all' items or regexp
match.

=cut

sub is_implicit_step {

    if (ref $_[0] eq 'ARRAY') {
        return 1 unless (@{$_[0]});
    } elsif (ref $_[0] eq 'HASH') {
        return 1 if (exists $_[0]->{regs} and @{$_[0]->{regs}});
        return 1 unless (exists $_[0]->{keys});
        return 1 unless (@{$_[0]->{keys}});
    } else { # hooks
        return 1;
    }

    return undef;
}

=head2 slist

Returns list of paths and references to their values from structure.

    @list = slist($struct, %opts)

=head3 Options

=over 4

=item depth C<< <N> >>

Don't dive into structure deeper than defined level.

=back

=cut

sub slist($;@) {
    my @stack = ([], \shift); # init: (path, ref)
    my %opts = @_;

    my (@out, $path, $ref);
    my $depth = defined $opts{depth} ? $opts{depth} : -1;

    while (@stack) {
        ($path, $ref) = splice @stack, 0, 2;

        if (ref ${$ref} eq 'HASH' and @{$path} != $depth and keys %{${$ref}}) {
            map { unshift @stack, [@{$path}, {keys => [$_]}], \${$ref}->{$_} }
                reverse sort keys %{${$ref}};
        } elsif (ref ${$ref} eq 'ARRAY' and @{$path} != $depth and @{${$ref}}) {
            map { unshift @stack, [@{$path}, [$_]], \${$ref}->[$_] }
                reverse 0 .. $#{${$ref}}
        } else {
            push @out, $path, $ref;
        }
    }

    return @out;
}

=head2 spath

Returns list of references from structure.

    @list = spath($struct, $path, %opts)

=head3 Options

=over 4

=item assign C<< <value> >>

Assign provided value to substructures pointed by path.

=item delete C<< <true|false> >>

Delete specified by path items from structure.

=item deref C<< <true|false> >>

Dereference result items.

=item expand C<< <"append"|true|false> >>

Expand structure if specified in path items doesn't exist. All newly created
items initialized by C<undef>. Arrays will be growed smoothly if C<append> as
value used (experimental).

=item paths C<< <true|false> >>

Return path for each result.

=item stack C<< <true|false> >>

Return stack of references to substructures.

=item strict C<< <true|false> >>

Croak if at least one element, specified by path, absent in the structure.

=back

All options are disabled (C<undef>) by default.

=cut

sub spath($$;@) {
    my ($struct, $spath, %opts) = @_;

    croak "Reference expected for structure" unless (ref $struct);
    croak "Arrayref expected for path" unless (ref $spath eq 'ARRAY');
    croak "Unable to remove passed thing entirely (empty path passed)"
        if ($opts{delete} and not @{$spath});

    my @level = ([], [(ref $struct eq 'SCALAR' or ref $struct eq 'REF') ? $struct : \$struct]);
    my $sc = 0; # step counter
    my ($items, @next, $path, $refs, @types);

    for my $step (@{$spath}) {
        while (@level) {
            ($path, $refs) = splice @level, 0, 2;

            if (ref $step eq 'ARRAY') {
                if (ref ${$refs->[-1]} ne 'ARRAY') {
                    croak "ARRAY expected on step #$sc, got " . ref ${$refs->[-1]}
                        if ($opts{strict});
                    next unless ($opts{expand});
                    ${$refs->[-1]} = [];
                }

                $items = @{$step} ? $step : [0 .. $#${$refs->[-1]}];
                for (@{$items}) {
                    unless (
                        $opts{expand} or
                        @{${$refs->[-1]}} > ($_ >= 0 ? $_ : abs($_ + 1))
                    ) {
                        croak "[$_] doesn't exist, step #$sc" if ($opts{strict});
                        next;
                    }
                    $_ = @{${$refs->[-1]}} if ($opts{expand} and
                        $_ > @{${$refs->[-1]}} and $opts{expand} eq 'append');
                    push @next, [@{$path}, [$_]], [@{$refs}, \${$refs->[-1]}->[$_]];
                }

                if ($opts{delete} and $sc == $#{$spath}) {
                    map { splice(@{${$refs->[-1]}}, $_, 1) if ($_ <= $#{${$refs->[-1]}}) }
                        reverse sort @{$items};
                }
            } elsif (ref $step eq 'HASH') {
                if (ref ${$refs->[-1]} ne 'HASH') {
                    croak "HASH expected on step #$sc, got " . ref ${$refs->[-1]}
                        if ($opts{strict});
                    next unless ($opts{expand});
                    ${$refs->[-1]} = {};
                }

                @types = grep { exists $step->{$_} } qw(keys regs);
                croak "Unsupported HASH definition, step #$sc" if (@types != keys %{$step});
                undef $items;

                for my $t (@types) {
                    croak "Unsupported HASH $t definition, step #$sc"
                        unless (ref $step->{$t} eq 'ARRAY');

                    if ($t eq 'keys') {
                        for (@{$step->{keys}}) {
                            unless ($opts{expand} or exists ${$refs->[-1]}->{$_}) {
                                croak "{$_} doesn't exist, step #$sc" if $opts{strict};
                                next;
                            }
                            push @{$items}, $_;
                        }
                    } else {
                        for my $g (@{$step->{regs}}) {
                            push @{$items}, grep { $_ =~ $g } keys %{${$refs->[-1]}};
                        }
                    }
                }

                for (@types ? @{$items} : keys %{${$refs->[-1]}}) {
                    push @next, [@{$path}, {keys => [$_]}], [@{$refs}, \${$refs->[-1]}->{$_}];
                    delete ${$refs->[-1]}->{$_} if ($opts{delete} and $sc == $#{$spath});
                }
            } elsif (ref $step eq 'CODE') {
                local $_ = ${$refs->[-1]};
                $step->($path, $refs) and push @next, $path, $refs;
            } else {
                croak "Unsupported thing in the path, step #$sc";
            }
        }

        @level = splice @next;
        $sc++;
    }

    my @out;
    while (@level) {
        ($path, $refs) = splice @level, 0, 2;
        ${$refs->[-1]} = $opts{assign} if (exists $opts{assign});
        if ($opts{stack}) {
            map { $_ = ${$_} } @{$refs} if ($opts{deref});
        } else {
            $refs = $opts{deref} ? ${pop @{$refs}} : pop @{$refs};
        }
        push @out, ($opts{paths} ? ($path, $refs) : $refs);
    }

    return @out;
}

=head2 spath_delta

Returns delta for two passed paths. By delta means steps from the second path
without beginning common steps for both.

    @delta = spath_delta($path1, $path2)

=cut

sub spath_delta($$) {
    my ($frst, $scnd) = @_;

    croak "Second path must be an arrayref" unless (ref $scnd eq 'ARRAY');
    return @{$scnd} unless (defined $frst);
    croak "First path may be undef or an arrayref" unless (ref $frst eq 'ARRAY');

    require B::Deparse;
    my $deparse = B::Deparse->new();
    my $i = 0;

    MAIN:
    while ($i < @{$frst} and ref $frst->[$i] eq ref $scnd->[$i]) {
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
        } elsif (ref $frst->[$i] eq 'CODE') {
            last unless (
                $deparse->coderef2text($frst->[$i]) eq
                $deparse->coderef2text($scnd->[$i])
            );
        } else {
            croak "Unsupported thing in the path, step #$i";
        }
        $i++;
    }

    return @{$scnd}[$i .. $#{$scnd}];
}

=head1 LIMITATIONS

Struct::Path will fail on structures with loops in references.

No object oriented interface provided.

=head1 AUTHOR

Michael Samoglyadov, C<< <mixas at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-struct-path at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Struct-Path>. I will be
notified, and then you'll automatically be notified of progress on your bug
as I make changes.

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

L<Data::Diver> L<Data::DPath> L<Data::DRef> L<Data::Focus> L<Data::Hierarchy>
L<Data::Nested> L<Data::PathSimple> L<Data::Reach> L<Data::Spath> L<JSON::Path>
L<MarpaX::xPathLike> L<Sereal::Path> L<Data::Find>

L<Struct::Diff> L<Struct::Path::PerlStyle>

=head1 LICENSE AND COPYRIGHT

Copyright 2016,2017 Michael Samoglyadov.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1; # End of Struct::Path
