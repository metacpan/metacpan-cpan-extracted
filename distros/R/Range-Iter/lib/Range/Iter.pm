package Range::Iter;

our $DATE = '2019-04-23'; # DATE
our $VERSION = '0.002'; # VERSION

use strict;
use warnings;

use Scalar::Util qw(looks_like_number);

use Exporter qw(import);
our @EXPORT_OK = qw(range_iter);

sub range_iter($$;$) {
    my ($start, $end, $step) = @_;
    $step //= 1;

    my $value = $start;
    my $ended;

    if (looks_like_number($start) && looks_like_number($end)) {
        # numeric version
        $ended++ if $value > $end;
        sub {
            $ended++ if $value > $end;
            return undef if $ended;
            my $old = $value;
            $value+=$step;
            return $old;
        };
    } else {
        die "Cannot specify step != 1 for non-numeric range" if $step != 1;
        $ended++ if $value gt $end;
        sub {
            return undef if $ended;
            $ended++ if $value ge $end;
            $value++;
        };
    }
}

1;
# ABSTRACT: Generate a coderef iterator for range

__END__

=pod

=encoding UTF-8

=head1 NAME

Range::Iter - Generate a coderef iterator for range

=head1 VERSION

This document describes version 0.002 of Range::Iter (from Perl distribution Range-Iter), released on 2019-04-23.

=head1 SYNOPSIS

  use Range::Iter qw(range_iter);

  my $iter = range_iter(1, 10);
  while (my $val = $iter->()) { ... } # 1, 2, 3, 4, 5, 6, 7, 8, 9, 10

You can add step:

 my $iter = range_iter(1, 10, 2); # 1, 3, 5, 7, 9

You can use alphanumeric strings too since C<++> has some extra builtin magic
(see L<perlop>):

 $iter = range_iter("zx", "aab"); # zx, zy, zz, aaa, aab

Infinite list:

 $iter = range_iter(1, Inf); # 1, 2, 3, ...

=head1 DESCRIPTION

=for Pod::Coverage .+

=head1 FUNCTIONS

=head2 range_iter($start, $end) => coderef

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Range-Iter>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Range-Iter>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Range-Iter>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Array::Iter>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
