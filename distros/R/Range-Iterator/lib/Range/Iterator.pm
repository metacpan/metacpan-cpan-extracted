package Range::Iterator;

our $DATE = '2019-04-17'; # DATE
our $VERSION = '0.001'; # VERSION

use strict;
use warnings;

my $re_num = qr/\A[+-]?[0-9]+(\.[0-9]+)?\z/;

sub new {
    my $class = shift;
    my ($start, $end, $step) = @_;
    $step //= 1;

    my $self = {
        start => $start,
        end   => $end,
        step  => $step,

        _ended => 0,
        _cur   => $start,
    };

    if ($start =~ $re_num && $end =~ $re_num) {
        $self->{_num}   = 1;
        $self->{_ended}++ if $start > $end;
    } else {
        die "Cannot specify step != 1 for non-numeric range" if $step != 1;
        $self->{_ended}++ if $start gt $end;
    }
    bless $self, $class;
}

sub next {
    my $self = shift;

    if ($self->{_num}) {
        $self->{_ended}++ if $self->{_cur} > $self->{end};
        return undef if $self->{_ended};
        my $old = $self->{_cur};
        $self->{_cur} += $self->{step};
        return $old;
    } else {
        return undef if $self->{_ended};
        $self->{_ended}++ if $self->{_cur} ge $self->{end};
        $self->{_cur}++;
    }
}

1;
# ABSTRACT: Generate an iterator object for range

__END__

=pod

=encoding UTF-8

=head1 NAME

Range::Iterator - Generate an iterator object for range

=head1 VERSION

This document describes version 0.001 of Range::Iterator (from Perl distribution Range-Iterator), released on 2019-04-17.

=head1 SYNOPSIS

  use Range::Iterator;

  my $iter = Range::Iterator->new(1, 10);
  while (defined(my $val = $iter->next)) { ... } # 1, 2, 3, 4, 5, 6, 7, 8, 9, 10

You can add step:

 my $iter = Range::Iterator->new(1, 10, 2); # 1, 3, 5, 7, 9

Anything that can be incremented by Perl is game:

  $iter = Range::Iterator->new("a", "e"); # a, b, c, d, e

=head1 DESCRIPTION

This module offers an object-based iterator for range.

=for Pod::Coverage .+

=head1 METHODS

=head2 new

Usage:

 $obj = Range::Iterator->new($start, $end [ , $step ])

=head2 next

Usage:

 my $val = $obj->next

Return the next value, or undef if there is no more values.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Range-Iterator>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Range-Iterator>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Range-Iterator>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Range::Iter>

L<Range::ArrayIter>

L<Array::Iterator> & L<Array::Iter> offer iterators for list/array.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
