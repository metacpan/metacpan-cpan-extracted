package PERLANCAR::AppUtil::PerlStripper;

our $DATE = '2015-06-17'; # DATE
our $VERSION = '0.03'; # VERSION

use 5.010001;
use strict;
use warnings;

1;

# BEGIN_BLOCK: _add_stripper_args_to_meta
sub _add_stripper_args_to_meta {
    my $meta = shift;

    # already added
    $meta->{args}{stripper} and return [304];

    $meta->{args}{stripper} = {
        summary => 'Whether to strip included modules using Perl::Stripper',
        'summary.alt.bool.yes' => 'Strip included modules using Perl::Stripper',
        schema => ['bool' => default=>0],
        tags => ['category:stripping'],
    };

    $meta->{args}{stripper_maintain_linum} = {
        summary => "Set maintain_linum=1 in Perl::Stripper",
        schema => ['bool'],
        default => 0,
        tags => ['category:stripping'],
    };

    $meta->{args}{stripper_ws} = {
        summary => "Set strip_ws=1 (strip whitespace) in Perl::Stripper",
        'summary.alt.bool.not' => "Set strip_ws=0 (don't strip whitespace) in Perl::Stripper",
        schema => ['bool'],
        default => 1,
        tags => ['category:stripping'],
    };

    $meta->{args}{stripper_comment} = {
        summary => "Set strip_comment=1 (strip comments) in Perl::Stripper",
        'summary.alt.bool.not' => "Set strip_comment=0 (don't strip comments) in Perl::Stripper",
        schema => ['bool'],
        default => 1,
        tags => ['category:stripping'],
    };

    $meta->{args}{stripper_pod} = {
        summary => "Set strip_pod=1 (strip POD) in Perl::Stripper",
        'summary.alt.bool.not' => "Set strip_pod=0 (don't strip POD) in Perl::Stripper",
        schema => ['bool'],
        default => 1,
        tags => ['category:stripping'],
    };

    $meta->{args}{stripper_log} = {
        summary => "Set strip_log=1 (strip log statements) in Perl::Stripper",
        'summary.alt.bool.not' => "Set strip_log=0 (don't strip log statements) in Perl::Stripper",
        schema => ['bool'],
        default => 0,
        tags => ['category:stripping'],
    };

    # XXX strip_log_levels

    $meta->{args_rels} //= {};
    my $ar = $meta->{args_rels};
    my $prop;
    if ($ar->{'dep_any&'}) {
        $prop = $ar->{'dep_any&'};
    } elsif (ref($ar->{'dep_any'}) eq 'ARRAY' && ($ar->{'dep_any.op'} // '') eq 'and') {
        $prop = $ar->{'dep_any'};
    } elsif (!$ar->{'dep_any'}) {
        $ar->{'dep_any'} = [];
        $ar->{'dep_any.op'} = 'and';
        $prop = $ar->{'dep_any'};
    }
    if ($prop) {
        push @$prop, [stripper_maintain_linum => [qw/stripper/]];
        push @$prop, [stripper_ws             => [qw/stripper/]];
        push @$prop, [stripper_log            => [qw/stripper/]];
        push @$prop, [stripper_pod            => [qw/stripper/]];
        push @$prop, [stripper_comment        => [qw/stripper/]];
    }

    [200];
}
# END_BLOCK: _add_stripper_args_to_meta

1;
# ABSTRACT: Utilities for PERLANCAR's applications, related to Perl::Stripper

__END__

=pod

=encoding UTF-8

=head1 NAME

PERLANCAR::AppUtil::PerlStripper - Utilities for PERLANCAR's applications, related to Perl::Stripper

=head1 VERSION

This document describes version 0.03 of PERLANCAR::AppUtil::PerlStripper (from Perl distribution PERLANCAR-AppUtil-PerlStripper), released on 2015-06-17.

=for Pod::Coverage .+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/PERLANCAR-AppUtil-PerlStripper>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-PERLANCAR-AppUtil-PerlStripper>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=PERLANCAR-AppUtil-PerlStripper>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
