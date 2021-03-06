package Range::HashIter;

our $DATE = '2019-05-12'; # DATE
our $VERSION = '0.001'; # VERSION

use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(range_hashiter);

sub range_hashiter($$;$) {
    my ($start, $end, $step) = @_;

    tie my %hash, 'Range::HashIter::Tie', $start, $end, $step;
    \%hash;
}

package # hide from PAUSE
    Range::HashIter::Tie;

use Scalar::Util qw(looks_like_number);

sub TIEHASH {
    my $class = shift;
    my ($start, $end, $step) = @_;
    $step //= 1;

    my $self = {
        start => $start,
        end   => $end,
        step  => $step,

        _ended => 0,
        _len   => 0,
        _cur   => $start,
        _buf   => [],
    };

    if (looks_like_number($start) && looks_like_number($end)) {
        $self->{_num}   = 1;
        $self->{_ended}++ if $start > $end;
    } else {
        die "Cannot specify step != 1 for non-numeric range" if $step != 1;
        $self->{_ended}++ if $start gt $end;
    }
    bless $self, $class;
}

sub _next {
    my $self = shift;

    if ($self->{_num}) {
        $self->{_ended}++ if $self->{_cur} > $self->{end};
        return if $self->{_ended};
        push @{ $self->{_buf} }, $self->{_cur};
        $self->{_cur} += $self->{step};
    } else {
        return if $self->{_ended};
        $self->{_ended}++ if $self->{_cur} ge $self->{end};
        push @{ $self->{_buf} }, $self->{_cur}++;
    }
}

sub FIRSTKEY {
    my $self = shift;
    $self->_next;
    if (@{ $self->{_buf} }) {
        $self->{_len}++;
        shift @{ $self->{_buf} };
    } else {
        undef;
    }
}

sub NEXTKEY {
    goto &FIRSTKEY;
}

sub FETCH {
    undef;
}

1;
# ABSTRACT: Generate a tied-hash iterator for range

__END__

=pod

=encoding UTF-8

=head1 NAME

Range::HashIter - Generate a tied-hash iterator for range

=head1 VERSION

This document describes version 0.001 of Range::HashIter (from Perl distribution Range-HashIter), released on 2019-05-12.

=head1 SYNOPSIS

  use Range::HashIter qw(range_hashiter);

  my $iter = range_hashiter(1, 10);
  while (my ($key, undef) = each %$iter) { ... } # 1, 2, 3, 4, 5, 6, 7, 8, 9, 10

You can add step:

 my $iter = range_hashiter(1, 10, 2); # 1, 3, 5, 7, 9

You can use alphanumeric strings too since C<++> has some extra builtin magic
(see L<perlop>):

 $iter = range_hashiter("zx", "aab"); # zx, zy, zz, aaa, aab

Infinite list:

 $iter = range_hashiter(1, Inf); # 1, 2, 3, ...

=head1 DESCRIPTION

B<PROOF OF CONCEPT.>

This module offers a tied-hash-based iterator that you can use using while() and
each(). It's most probably useful as a proof of concept only.

=for Pod::Coverage .+

=head1 FUNCTIONS

=head2 range_hashiter($start, $end [ , $step ]) => hashref

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Range-HashIter>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Range-HashIter>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Range-HashIter>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Range::Iter>

L<Range::Iterator>

L<Range::ArrayIter>

L<Range::HandleIter>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
