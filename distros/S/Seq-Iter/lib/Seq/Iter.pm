package Seq::Iter;

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-11-21'; # DATE
our $DIST = 'Seq-Iter'; # DIST
our $VERSION = '0.001'; # VERSION

our @EXPORT_OK = qw(seq_iter);

our $BUFFER_SIZE = 10;

sub seq_iter {
    my @orig_seq = @_;

    my $index = -1;
    my $index_coderef;
    my @gen_seq;
    sub {
        $index++;
        splice @gen_seq, $BUFFER_SIZE-1 if @gen_seq > $BUFFER_SIZE;

      RETRY:
        if (defined $index_coderef) {
            my $item = $orig_seq[$index_coderef]->($index, \@orig_seq, \@gen_seq);
            return unless defined $item;
            unshift @gen_seq, $item;
            return $item;
        } elsif ($index >= @orig_seq) {
            return;
        } else {
            my $item = $orig_seq[$index];
            if (ref $item eq 'CODE') {
                $index_coderef = $index;
                goto RETRY;
            } else {
                unshift @gen_seq, $item;
                return $item;
            }
        }
    };
}

1;
# ABSTRACT: Generate a coderef iterator from a sequence of items, the last of which can be a coderef to produce more items

__END__

=pod

=encoding UTF-8

=head1 NAME

Seq::Iter - Generate a coderef iterator from a sequence of items, the last of which can be a coderef to produce more items

=head1 VERSION

This document describes version 0.001 of Seq::Iter (from Perl distribution Seq-Iter), released on 2023-11-21.

=head1 SYNOPSIS

  use Seq::Iter qw(seq_iter);

 # generate fibonacci sequence
 my $iter = seq_iter(1, 1, sub { my ($index, $orig_seq, $gen_seq) = @_; $gen_seq->[0] + $gen_seq->[1] }); # => 1, 1, 2, 3, 5, 8, ...
 # ditto, shorter
 my $iter = seq_iter(1, 1, sub { $_[2][0] + $_[2][1] });

 # generate 5 random numbers
 my $iter = seq_iter(sub { my ($index, $orig_seq, $gen_seq) = @_; $index >= 5 ? undef : sprintf("%.3f", rand()) }); # => 0.238, 0.932, 0.866, 0.841, 0.501, undef, ...

 # randomly decrease between 0.1 and 0.4 then always return 0 after it reaches <= 0
 my $iter = seq_iter(3, sub { my ($index, $orig_seq, $gen_seq) = @_; $gen_seq->[0] <= 0 ? 0 : $gen_seq->[1]-(rand()*0.3+0.1)));

=head1 DESCRIPTION

This module provides a simple (coderef) iterator which you can call repeatedly
to get numbers specified in a sequence specification (list). The last item of
the list can be a coderef which will be called to produce more items. The
coderef item will be called with:

 ($index, $orig_seq, $gen_buf)

where C<$index> is a incrementing number starting from 0 (for the first item of
the generated sequence), C<$orig_seq> is the original sequence arrayref, and
C<$gen_buf> is an array containing generated items (most recent items first),
capped at C<$BUFFER_SIZE> items (by default 10).

=for Pod::Coverage .+

=head1 VARIABLES

=head2 $BUFFER_SIZE

=head1 FUNCTIONS

=head2 seq_iter

Usage:

 $iter = seq_iter(LIST); # => coderef

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Seq-Iter>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Seq-Iter>.

=head1 SEE ALSO

For simpler number sequence, see L<NumSeq::Iter>. As of 0.006, the module
supports recognizing fibonacci sequence.

Other C<*::Iter> modules.

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

This software is copyright (c) 2023 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Seq-Iter>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
