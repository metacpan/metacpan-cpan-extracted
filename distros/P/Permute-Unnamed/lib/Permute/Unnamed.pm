package Permute::Unnamed;

use 5.010001;
use strict 'subs', 'vars';
use warnings;

use Exporter qw(import);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2026-02-21'; # DATE
our $DIST = 'Permute-Unnamed'; # DIST
our $VERSION = '0.001'; # VERSION

our @EXPORT = qw(
                    permute_unnamed
            );

sub permute_unnamed {
    my @args = @_;
    die "Please supply a non-empty list of arrayrefs" unless @args;

    for my $i (0 .. $#args) {
        die "arg[$i] cannot contain empty values" unless @{ $args[$i] };
    }
    my @res;
    my $code = '{ my @j;';
    for my $i (0..$#args) {
        $code .= " local \$main::_j$i;";
    }
    for my $i (0..$#args) {
        $code .= " for \$main::_j$i (0..". $#{$args[$i]} . ") {";
    }
    $code .= " my \$ary = []; for my \$i (0..". $#args . ") { \$ary->[\$i] = \$args[\$i][ \${\"main::_j\$i\"} ]; } push \@res, \$ary;";
    for my $i (0..$#args) {
        $code .= ' }';
    }
    $code .= " }";
    #say $code;
    eval $code; if ($@) { warn "$code\n"; die } ## no critic: BuiltinFunctions::ProhibitStringyEval
    wantarray ? @res : \@res;
}

1;
# ABSTRACT: Permute multiple-valued lists

__END__

=pod

=encoding UTF-8

=head1 NAME

Permute::Unnamed - Permute multiple-valued lists

=head1 VERSION

This document describes version 0.001 of Permute::Unnamed (from Perl distribution Permute-Unnamed), released on 2026-02-21.

=head1 SYNOPSIS

 use Permute::Unnamed;

 my @p = permute_unnamed([ 0, 1 ], [qw(foo bar baz)]);
 # => (
 #   [0, "foo"],
 #   [0, "bar"],
 #   [0, "baz"],
 #   [1, "foo"],
 #   [1, "bar"],
 #   [1, "baz"],
 # )

=head1 DESCRIPTION

This module is like L<Set::CrossProduct>, except that it allows only a single
argument.

=head1 FUNCTIONS

=head2 permute_unnamed(@list) => @list | $arrayref

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Permute-Unnamed>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Permute-Unnamed>.

=head1 SEE ALSO

L<Set::CrossProduct>

L<Permute::Named>, L<PERLANCAR::Permute::Named>, L<Permute::Named::Iter>

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Permute-Unnamed>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
