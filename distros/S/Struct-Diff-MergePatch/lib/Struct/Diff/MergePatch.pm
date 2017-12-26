package Struct::Diff::MergePatch;

use 5.006;
use strict;
use warnings FATAL => 'all';
use parent 'Exporter';

use Struct::Diff 0.93;

our @EXPORT_OK = qw(
    diff
    patch
);

=head1 NAME

Struct::Diff::MergePatch - JSON Merge Patch
(L<rfc7396|https://tools.ietf.org/html/rfc7396>) for perl structures

=begin html

<a href="https://travis-ci.org/mr-mixas/Struct-Diff-MergePatch.pm"><img src="https://travis-ci.org/mr-mixas/Struct-Diff-MergePatch.pm.svg?branch=master" alt="Travis CI"></a>
<a href='https://coveralls.io/github/mr-mixas/Struct-Diff-MergePatch.pm?branch=master'><img src='https://coveralls.io/repos/github/mr-mixas/Struct-Diff-MergePatch.pm/badge.svg?branch=master' alt='Coverage Status'/></a>
<a href="https://badge.fury.io/pl/Struct-Diff-MergePatch"><img src="https://badge.fury.io/pl/Struct-Diff-MergePatch.svg" alt="CPAN version"></a>

=end html

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use Struct::Diff::MergePatch qw(diff patch);

    $old = {a => {b => 1,c => [0],  d => 5},f => 2};
    $new = {a => {b => 1,c => [0,1],e => 6},f => 2};

    $diff = diff($old, $new);
    # {a => {c => [0,1],d => undef,e => 6}}

    patch($old, $diff);
    # $old now equal to $new

=head1 EXPORT

Nothing is exported by default.

=head1 SUBROUTINES

=head2 diff

Calculate patch for two arguments:

    $patch = diff($old, $new);

Convert L<Struct::Diff> diff to merge patch when single arg passed:

    $patch = diff(Struct::Diff::diff($old, $new));

=cut

sub diff($;$) {
    my $patch;
    my @stack = (\$patch, @_ == 2 ? Struct::Diff::diff($_[0], $_[1]) : $_[0]);

    while (@stack) {
        my ($p, $d) = splice @stack, 0, 2; # subpatch, subdiff

        if (exists $d->{D}) {
            if (ref $d->{D} eq 'ARRAY') {
                ${$p} = Struct::Diff::split_diff($d)->{b};
            } else { # HASH
                while (my ($k, $v) = each %{$d->{D}}) {
                    if (exists $v->{D} or exists $v->{N}) {
                        push @stack, \${$p}->{$k}, $v;
                    } elsif (exists $v->{A}) {
                        ${$p}->{$k} = $v->{A};
                    } elsif (exists $v->{R}) {
                        ${$p}->{$k} = undef;
                    }
                }
            }
        } elsif (exists $d->{N}) {
            ${$p} = $d->{N};
        }
    }

    return defined $patch ? $patch : $_[1];
}

=head2 patch

Apply patch.

    patch($target, $patch);

=cut

sub patch($$) {
    my @stack = (\$_[0], $_[1]); # ref to alias - to be able to change passed scalar

    while (@stack) {
        my ($t, $p) = splice @stack, 0, 2; # subtarget, subpatch

        if (ref $p eq 'HASH') {
            ${$t} = {} unless (ref ${$t} eq 'HASH');

            while (my ($k, $v) = each %{$p}) {
                if (not defined $v) {
                    delete ${$t}->{$k};
                } elsif (ref $v) {
                    push @stack, \${$t}->{$k}, $v;
                } else {
                    ${$t}->{$k} = $v;
                }
            }
        } else {
            ${$t} = $p;
        }
    }
}

=head1 AUTHOR

Michael Samoglyadov, C<< <mixas at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-struct-diff-mergepatch at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Struct-Diff-MergePatch>. I
will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Struct::Diff::MergePatch

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Struct-Diff-MergePatch>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Struct-Diff-MergePatch>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Struct-Diff-MergePatch>

=item * Search CPAN

L<http://search.cpan.org/dist/Struct-Diff-MergePatch/>

=back

=head1 SEE ALSO

L<Struct::Diff>, L<JSON::MergePatch>,
L<rfc7396|https://tools.ietf.org/html/rfc7396>

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Michael Samoglyadov.

This program is free software; you can redistribute it and/or modify it under
the terms of either: the GNU General Public License as published by the Free
Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1; # End of Struct::Diff::MergePatch
