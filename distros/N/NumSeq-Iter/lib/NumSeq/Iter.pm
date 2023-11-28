package NumSeq::Iter;

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-11-21'; # DATE
our $DIST = 'NumSeq-Iter'; # DIST
our $VERSION = '0.008'; # VERSION

our @EXPORT_OK = qw(numseq_iter numseq_parse);

my $re_num = qr/(?:[+-]?[0-9]+(?:\.[0-9]+)?)/;

sub _numseq_parse_or_iter {
    my $which = shift;
    my $opts = ref($_[0]) eq 'HASH' ? shift : {};
    my $numseq = shift;

    my @nums;
    while ($numseq =~ s/\A(\s*,\s*)?($re_num)//) {
        die "Number sequence must not start with comma" if $1 && !@nums;
        push @nums, $2;
    }
    die "Please specify one or more number in number sequence: '$numseq'" unless @nums;

    my $has_ellipsis = 0;
    if ($numseq =~ s/\A\s*,\s*\.\.\.//) {
        die "Please specify at least three number in number sequence before ellipsis" unless @nums >= 3;
        $has_ellipsis++;
    }

    my $last_num;
    if ($numseq =~ s/\A\s*,\s*($re_num|[+-]?Inf)//) {
        $last_num = $1;
    }
    die "Extraneous token in number sequence: $numseq, please only use 'a,b,c, ...' or 'a,b,c,...,z'" if length $numseq;

    my $type = '';
    my $inc;
  CHECK_SEQ_TYPE: {
        last unless $has_ellipsis;

      CHECK_ARITHMETIC: {
            my $inc0;
            for (1..$#nums) {
                if ($_ == 1) { $inc0 = $nums[1] - $nums[0] }
                elsif ($inc0 != ($nums[$_] - $nums[$_-1])) {
                    last CHECK_ARITHMETIC;
                }
            }
            $type = 'arithmetic';
            $inc = $inc0;
            last CHECK_SEQ_TYPE;
        }

      CHECK_GEOMETRIC: {
            last if $nums[0] == 0;
            my $inc0;
            for (1..$#nums) {
                if ($_ == 1) { $inc0 = $nums[1] / $nums[0] }
                else {
                    last CHECK_GEOMETRIC if $nums[$_-1] == 0;
                    if ($inc0 != ($nums[$_] / $nums[$_-1])) {
                        last CHECK_GEOMETRIC;
                    }
                }
            }
            $type = 'geometric';
            $inc = $inc0;
            last CHECK_SEQ_TYPE;
        }

      CHECK_FIBONACCI: {
            last if @nums < 3;
            last if defined $last_num; # currently not supported
            for (2..$#nums) {
                last unless $nums[$_] == $nums[$_-1]+$nums[$_-2];
            }
            $type = 'fibonacci';
            last CHECK_SEQ_TYPE;
        }

        die "Can't determine the pattern from number sequence: ".join(", ", @nums);
    }

    if ($which eq 'parse') {
        return {
            numbers => \@nums,
            has_ellipsis => $has_ellipsis,
            ($has_ellipsis ? (last_number => $last_num) : ()),
            type => $type || 'itemized',
            (defined $inc ? (inc => $inc) : ()),
        };
    }

    my $i = 0;
    my $cur;
    my $ends;
    my @buf;
    return sub {
        return undef if $ends; ## no critic: Subroutines::ProhibitExplicitReturnUndef
        return $nums[$i++] if $i <= $#nums;
        if (!$has_ellipsis) { $ends++; return undef } ## no critic: Subroutines::ProhibitExplicitReturnUndef

        $cur //= $nums[-1];
        if ($type eq 'arithmetic') {
            $cur += $inc;
            if (defined $last_num) {
                if ($inc >= 0 && $cur > $last_num || $inc < 0 && $cur < $last_num) {
                    $ends++;
                    return undef; ## no critic: Subroutines::ProhibitExplicitReturnUndef
                }
            }
            return $cur;
        } elsif ($type eq 'geometric') {
            $cur *= $inc;
            if (defined $last_num) {
                if ($inc >= 1 && $cur > $last_num || $inc < 1 && $cur < $last_num) {
                    $ends++;
                    return undef; ## no critic: Subroutines::ProhibitExplicitReturnUndef
                }
            }
            return $cur;
        } elsif ($type eq 'fibonacci') {
            @buf = ($nums[-1], $nums[-2]) unless @buf;
            $cur = $buf[1] + $buf[0];
            unshift @buf, $cur; pop @buf;
            return $cur;
        } else {
            die "BUG: Can't generate items for sequence of type '$type'";
        }
    };
}

sub numseq_iter {
    _numseq_parse_or_iter('iter', @_);
}

sub numseq_parse {
    my $res;
    eval {
        $res = _numseq_parse_or_iter('parse', @_);
    };
    if ($@) {
        my $errmsg = $@;
        $errmsg =~ s/(.+) at .+/$1/s; # ux: remove file+line number information from error message
        return [400, "Parse fail: $errmsg"];
    }
    [200, "OK", $res];
}

1;
# ABSTRACT: Generate a coderef iterator from a number sequence specification (e.g. '1,3,5,...,101')

__END__

=pod

=encoding UTF-8

=head1 NAME

NumSeq::Iter - Generate a coderef iterator from a number sequence specification (e.g. '1,3,5,...,101')

=head1 VERSION

This document describes version 0.008 of NumSeq::Iter (from Perl distribution NumSeq-Iter), released on 2023-11-21.

=head1 SYNOPSIS

  use NumSeq::Iter qw(numseq_parse numseq_iter);

  my $iter = numseq_iter('1,3,5,...,13');
  while (my $val = $iter->()) { ... } # 1,3,5,7,9,11,13

  $iter = numseq_iter('1,3,5,...,10');
  while (my $val = $iter->()) { ... } # 1,3,5,7,9

  my $res = numseq_parse('');             # [400, "Parse fail: Please specify one or more number in number sequence: ''"]
  my $res = numseq_parse('1,5,2');        # [200, "OK", {numbers=>[1,5,2], has_ellipsis=>0, type=>'itemized', inc=>undef}]
  my $res = numseq_parse('1,2,3');        # [200, "OK", {numbers=>[1,2,3], has_ellipsis=>0, type=>'itemized', inc=>undef}]
  my $res = numseq_parse('1,2,3,...');    # [200, "OK", {numbers=>[1,2,3], has_ellipsis=>1, type=>'arithmetic', inc=>1, last_number=>undef}]
  my $res = numseq_parse('1,3,9,...');    # [200, "OK", {numbers=>[1,3,9], has_ellipsis=>1, type=>'geometric',  inc=>3, last_number=>undef}]
  my $res = numseq_parse('1,3,5,...,13'); # [200, "OK", {numbers=>[1,3,5], has_ellipsis=>1, type=>'arithmetic', inc=>2, last_number=>13}]
  my $res = numseq_parse('2,3,5,...');    # [200, "OK", {numbers=>[1,3,5], has_ellipsis=>1, type=>'fibonacci'}]
  my $res = numseq_parse('2,3,7,...');    # [400, "Parse fail: Can't determine the pattern from number sequence: 2, 3, 7"]

=head1 DESCRIPTION

This module provides a simple (coderef) iterator which you can call repeatedly
to get numbers specified in a number sequence specification (string). When the
numbers are exhausted, the coderef will return undef. No class/object involved.

A number sequence is a comma-separated list of numbers (either integer like 1,
-2 or decimal number like 1.3, -100.70) with at least one number. It can contain
an ellipsis (e.g. '1,2,3,...' or '1, 3, 5, ..., 10').

When the sequence has an ellipsis, there must be at least three numbers before
the ellipsis. There can optionally be another number after the ellipsis to make
the sequence finite; but the last number can also be Inf, +Inf, or -Inf.

Currently these sequences are recognized:

=over

=item * simple arithmetic sequence ('1,3,5')

=item * simple geometric sequence ('2,6,18')

=item * fibonacci ('2,3,5')

=back

=for Pod::Coverage .+

=head1 FUNCTIONS

=head2 numseq_iter

Usage:

 $iter = numseq_iter([ \%opts ], $spec); # coderef

Options:

=over

=back

=head2 numseq_parse

 my $res = numseq_parse([ \%opts ], $spec); # enveloped response

See L</numseq_iter> for list of known options.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/NumSeq-Iter>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-NumSeq-Iter>.

=head1 SEE ALSO

Other iterators: L<IntRange::Iter>, L<Range::Iter>

CLI for this module: L<seq-numseq> (from L<App::seq::numseq>). There's another
CLI named L<numseq> (from L<App::numseq>), but it is only tangentially related.

L<Sah::Schemas::NumSeq>

Raku's lazy lists.

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=NumSeq-Iter>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
