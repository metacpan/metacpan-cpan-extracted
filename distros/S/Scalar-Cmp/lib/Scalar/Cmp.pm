package Scalar::Cmp;

use 5.010001;
use strict 'subs', 'vars';
use warnings;

use Scalar::Util qw(looks_like_number);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-09-07'; # DATE
our $DIST = 'Scalar-Cmp'; # DIST
our $VERSION = '0.003'; # VERSION

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(
                       cmp_scalar
                       cmpnum_scalar
                       cmpstrornum_scalar
               );

sub cmp_scalar {
    my ($d1, $d2) = @_;

    my $def1 = defined $d1;
    my $def2 = defined $d2;
    if    ( $def1 && !$def2) { return 1 }
    elsif (!$def1 &&  $def2) { return -1 }
    elsif (!$def1 && !$def2) { return 0 }

    # so both are defined ...

    my $ref1 = ref $d1;
    my $ref2 = ref $d2;
    if ($ref1 xor $ref2) { return 2 }
    elsif ($ref1) { return $d1 == $d2 ? 0 : 2 }

    # so both are not references ...

    $d1 cmp $d2;
}

sub cmpnum_scalar {
    my ($d1, $d2) = @_;

    my $def1 = defined $d1;
    my $def2 = defined $d2;
    if    ( $def1 && !$def2) { return 1 }
    elsif (!$def1 &&  $def2) { return -1 }
    elsif (!$def1 && !$def2) { return 0 }

    # so both are defined ...

    my $ref1 = ref $d1;
    my $ref2 = ref $d2;
    if ($ref1 xor $ref2) { return 2 }
    elsif ($ref1) { return $d1 == $d2 ? 0 : 2}

    # so both are not references ...

    $d1 <=> $d2;
}

sub cmpstrornum_scalar {
    my ($d1, $d2) = @_;

    my $def1 = defined $d1;
    my $def2 = defined $d2;
    if    ( $def1 && !$def2) { return 1 }
    elsif (!$def1 &&  $def2) { return -1 }
    elsif (!$def1 && !$def2) { return 0 }

    # so both are defined ...

    my $ref1 = ref $d1;
    my $ref2 = ref $d2;
    if ($ref1 xor $ref2) { return 2 }
    elsif ($ref1) { return $d1 == $d2 ? 0 : 2 }

    # so both are not references ...

    my $llnum1 = looks_like_number($d1);
    my $llnum2 = looks_like_number($d2);
    $llnum1 && $llnum2 ? ($d1 <=> $d2) : ($d1 cmp $d2);
}

1;
# ABSTRACT: Compare two scalars

__END__

=pod

=encoding UTF-8

=head1 NAME

Scalar::Cmp - Compare two scalars

=head1 VERSION

This document describes version 0.003 of Scalar::Cmp (from Perl distribution Scalar-Cmp), released on 2021-09-07.

=head1 SYNOPSIS

 use Scalar::Cmp qw(cmp_scalar cmpnum_scalar cmpstrornum_scalar);

 # undef
 say cmp_scalar(undef, undef); # => 0
 say cmp_scalar(undef, 1);     # => -1

 # references
 say cmp_scalar(1, []);        # => 2
 say cmp_scalar([], 1);        # => 2
 say cmp_scalar([], []);       # => 2
 my $r = []; say cmp_scalar($r, $r);  # => 0

 # cmp_scalar always uses cmp (mnemonic: "cmp" operator)
 say cmpstr_scalar("1.0", 1);  # => 1

 # cmpnum_scalar always uses <=>
 say cmpnum_scalar("1.0", 1);  # => 0
 say cmpnum_scalar("a", "0");  # => 0, but emit warnings

 # cmpstrornum_scalar uses <=> if both scalars look like number, or cmp otherwise
 say cmpstrornum_scalar(1, 1);         # => 0
 say cmpstrornum_scalar(1, 2);         # => -1
 say cmpstrornum_scalar(2, 1);         # => -1
 say cmpstrornum_scalar("1.0", 1);     # => 0
 say cmpstrornum_scalar("a", "0");     # => 1

=head1 DESCRIPTION

This module provides L</cmp_scalar> (and L</cmpnum_scalar> and
L</cmpstrornum_scalar> which are convenient routines to compare two scalar
values (ii.e. check if they are the same, or find out who is "greater than" the
other). The routines can handle C<undef> and references, so you don't have to
manually check for these.

The routines return -1, 0, 1 like Perl's C<cmp> and C<< <=> >> operators, but
also possibly C<2> when the two scalars are different but there is no sensible
notion of which one is larger than the other (e.g. C<1> vs C<[1]>). The
following is the rule:

=over

=item 1. Defined value is greater than undef.

 cmp_scalar(undef, 0); # => -1

=item 2. undef is the same as itself.

 cmp_scalar(undef, undef); # => 0

Note: This might not be what you want if you expect C<undef> to act like C<NULL>
in relational databases, where C<NULL> is not equal to itself.

=item 2. References cannot be compared with non-references.

 cmp_scalar(1, []); # => 2
 cmp_scalar([], 1); # => 2

=item 3. A reference is only the same as itself, otherwise it cannot be compared.

 cmp_scalar([], []); # => 2

 my $ary = [];
 cmp_scalar($ary, $ary); # => 0, same "address"

=item 4. Non-references are compared with C<cmp> or C<< <=> >>

L</cmp_scalar> always uses C<cmp>. L</cmpnum_scalar> always uses C<< <=> >>.
L</cmpstrornum_scalar> uses C<< <=> >> if both scalars look like number, or
C<cmp> otherwise.

=back

=head1 FUNCTIONS

=head2 cmp_scalar

=head2 cmpnum_scalar

=head2 cmpstrornum_scalar

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Scalar-Cmp>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Scalar-Cmp>.

=head1 SEE ALSO

The Perl's C<cmp> and C<< <=> >> operators.

L<Data::Cmp> which uses similar comparison rules but recurse into array and hash
elements.

L<Syntax::Operator::Equ> introduces several operators/functions which also have
a rule to equate two undefs.

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Scalar-Cmp>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
