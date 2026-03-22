package Permute::Unnamed::Iter;

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2026-02-22'; # DATE
our $DIST = 'Permute-Unnamed-Iter'; # DIST
our $VERSION = '0.001'; # VERSION

our @EXPORT_OK = qw(
                    permute_unnamed_iter
            );

sub permute_unnamed_iter {
    my @args = @_;
    die "Please supply a non-empty list of arrayrefs" unless @args;

    my $state = [(0) x @args];
    my $state2 = 0; # 0,1,2
    my $iter = sub {
        if (!$state2) { # starting the first time, don't increment state yet
            $state2 = 1;
            goto L2;
        } elsif ($state2 == 2) { # all permutation exhausted
            return undef; ## no critic: Subroutines::ProhibitExplicitReturnUndef
        }
        my $i = $#{$state};
      L1:
        while ($i >= 0) {
            if ($state->[$i] >= $#{$args[$i]}) {
                if ($i == 0) {
                    $state2 = 2;
                    return undef; ## no critic: Subroutines::ProhibitExplicitReturnUndef
                }
                $state->[$i] = 0;
                my $j = $i-1;
                while ($j >= 0) {
                    if ($state->[$j] >= $#{$args[$j]}) {
                        if ($j == 0) { # all permutation exhausted
                            $state2 = 2;
                            return undef; ## no critic: Subroutines::ProhibitExplicitReturnUndef
                        }
                        $state->[$j] = 0;
                        $j--;
                    } else {
                        $state->[$j]++;
                        last L1;
                    }
                }
                $i--;
            } else {
                $state->[$i]++;
                last;
            }
        }
      L2:
        return [ map { $args[$_][ $state->[$_] ] } 0..$#{$state} ];
    };
    $iter;
}

1;
# ABSTRACT: Permute multiple-valued lists

__END__

=pod

=encoding UTF-8

=head1 NAME

Permute::Unnamed::Iter - Permute multiple-valued lists

=head1 VERSION

This document describes version 0.001 of Permute::Unnamed::Iter (from Perl distribution Permute-Unnamed-Iter), released on 2026-02-22.

=head1 SYNOPSIS

 use Permute::Unnamed::Iter qw(permute_unnamed_iter);

 my $iter = permute_unnamed_iter([ 0, 1 ], [qw(foo bar baz)]);
 while (my $ary = $iter->()) {
     # ...
 }

=head1 DESCRIPTION

This module is like L<Permute::Unnamed>, except that it offers an iterator
interface.

=head1 FUNCTIONS

=head2 permute_unnamed_iter(@list) => CODE

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Permute-Unnamed-Iter>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Permute-Unnamed-Iter>.

=head1 SEE ALSO

L<Permute::Unnamed>.

L<Set::CrossProduct>, L<Set::Product>, et al (see the POD of Set::Product for
more similar modules) and CLI L<cross>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Permute-Unnamed-Iter>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
