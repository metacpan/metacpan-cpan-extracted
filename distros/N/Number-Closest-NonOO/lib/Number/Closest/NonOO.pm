package Number::Closest::NonOO;

our $DATE = '2015-09-03'; # DATE
our $VERSION = '0.06'; # VERSION

use 5.010001;
use strict;
use warnings;

use Perinci::Sub::Util qw(gen_modified_sub);
use Scalar::Util 'looks_like_number';

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(find_closest_number find_farthest_number);
our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Find number(s) closest to a number in a list of numbers',
};

sub _find {
    my %args = @_;

    my $num = $args{number};
    my $nan = $args{nan} // 'nothing';
    my $inf = $args{inf} // 'nothing';
    my @nums = @{ $args{numbers} };
    if ($nan eq 'exclude' && $inf eq 'exclude') {
        @nums = grep {
            looks_like_number($_) && $_ != 'inf' && $_ != '-inf'
        } @nums;
    } elsif ($nan eq 'exclude') {
        @nums = grep {
            my $l = looks_like_number($_);
            $l &&
                $l != 36 && # nan
                    $l != 44; # -nan
        } @nums;
    }
    if ($inf eq 'exclude') {
        @nums = grep {
            !looks_like_number($_) ? 1 : ($_ != 'inf' && $_ != '-inf')
        } @nums;
    }

    my @mapped;
    my @res;
    if ($inf eq 'number') {
        @res =map {
            my $m = [$_];
            if    ($num ==  'inf' && $_ ==  'inf') { push @$m, 0, 0   }
            elsif ($num ==  'inf' && $_ == '-inf') { push @$m, 'inf', 'inf' }
            elsif ($num == '-inf' && $_ ==  'inf') { push @$m, 'inf', 'inf' }
            elsif ($num == '-inf' && $_ == '-inf') { push @$m, 0, 0   }
            elsif ($num ==  'inf') { push @$m,  $num, -$_ }
            elsif ($num == '-inf') { push @$m, -$num,  $_ }
            elsif ($_   ==  'inf') { push @$m,    $_, -$_ }
            elsif ($_   == '-inf') { push @$m,   -$_,  $_ }
            else  { push @$m, abs($_-$num), 0 }
            $m;
        } @nums;
        #use Data::Dump; dd \@res;
        @res = sort {$a->[1] <=> $b->[1] || $a->[2] <=> $b->[2] || $a->[0] <=> $b->[0] }
            @res;
    } else {
        @res = sort {$a->[1] <=> $b->[1] || $a->[0] <=> $b->[0]}
            map {[$_, abs($_-$num)]} @nums;
    }
    @res = map {$_->[0]} @res;

    my $items = $args{items} // 1;
    @res = reverse @res if $args{-farthest};
    splice @res, $items unless $items >= @res;

    if ($items == 1) {
        return $res[0];
    } else {
        return \@res;
    }
}

$SPEC{find_closest_number} = {
    v => 1.1,
    summary => 'Find number(s) closest to a number in a list of numbers',
    args => {
        number => {
            summary => 'The target number',
            schema => 'num*',
            req => 1,
        },
        numbers => {
            summary => 'The list of numbers',
            schema => 'array*',
            req => 1,
        },
        items => {
            summary => 'Return this number of closest numbers',
            schema => ['int*', min=>1, default=>1],
        },
        nan => {
            summary => 'Specify how to handle NaN and non-numbers',
            schema => ['str', in=>['exclude', 'nothing'], default=>'exclude'],
            description => <<'_',

`exclude` means the items will first be excluded from the list. `nothing` will
do nothing about it, meaning there will be warnings when comparing non-numbers.

_
        },
        inf => {
            summary => 'Specify how to handle Inf',
            schema => ['str', in=>['number', 'nothing', 'exclude'],
                       default=>'nothing'],
            description => <<'_',

`exclude` means the items will first be excluded from the list. `nothing` will
do nothing about it and will produce a warning if target number is an infinite,
`number` will treat Inf like a very large number, i.e. Inf is closest to Inf and
largest positive numbers, -Inf is closest to -Inf and after that largest
negative numbers.

I'd reckon that `number` is the behavior that most people want when dealing with
infinites. But since it's slower, it's not the default and you have to specify
it specifically. You should choose `number` if target number is infinite.

_
        },
    },
    result_naked => 1,
};
sub find_closest_number {
    my %args = @_;
    _find(%args);
}

gen_modified_sub(
    output_name => 'find_farthest_number',
    base_name   => 'find_closest_number',
    summary     => 'Find number(s) farthest to a number in a list of numbers',
    output_code => sub {
        my %args = @_;
        _find(%args, -farthest=>1);
    },
);

1;
# ABSTRACT: Find number(s) closest to a number in a list of numbers

__END__

=pod

=encoding UTF-8

=head1 NAME

Number::Closest::NonOO - Find number(s) closest to a number in a list of numbers

=head1 VERSION

This document describes version 0.06 of Number::Closest::NonOO (from Perl distribution Number-Closest-NonOO), released on 2015-09-03.

=head1 SYNOPSIS

 use Number::Closest::NonOO qw(find_closest_number find_farthest_number);
 my $nums = find_closest_number(number=>3, numbers=>[1, 3, 5, 10], items => 2); # => [3, 1]

 $nums = find_farthest_number(number=>3, numbers=>[1, 3, 5, 10]); # => 10

=head1 DESCRIPTION

=head1 FUNCTIONS


=head2 find_closest_number(%args) -> any

Find number(s) closest to a number in a list of numbers.

Arguments ('*' denotes required arguments):

=over 4

=item * B<inf> => I<str> (default: "nothing")

Specify how to handle Inf.

C<exclude> means the items will first be excluded from the list. C<nothing> will
do nothing about it and will produce a warning if target number is an infinite,
C<number> will treat Inf like a very large number, i.e. Inf is closest to Inf and
largest positive numbers, -Inf is closest to -Inf and after that largest
negative numbers.

I'd reckon that C<number> is the behavior that most people want when dealing with
infinites. But since it's slower, it's not the default and you have to specify
it specifically. You should choose C<number> if target number is infinite.

=item * B<items> => I<int> (default: 1)

Return this number of closest numbers.

=item * B<nan> => I<str> (default: "exclude")

Specify how to handle NaN and non-numbers.

C<exclude> means the items will first be excluded from the list. C<nothing> will
do nothing about it, meaning there will be warnings when comparing non-numbers.

=item * B<number>* => I<num>

The target number.

=item * B<numbers>* => I<array>

The list of numbers.

=back

Return value:  (any)


=head2 find_farthest_number(%args) -> any

Find number(s) farthest to a number in a list of numbers.

Arguments ('*' denotes required arguments):

=over 4

=item * B<inf> => I<str> (default: "nothing")

Specify how to handle Inf.

C<exclude> means the items will first be excluded from the list. C<nothing> will
do nothing about it and will produce a warning if target number is an infinite,
C<number> will treat Inf like a very large number, i.e. Inf is closest to Inf and
largest positive numbers, -Inf is closest to -Inf and after that largest
negative numbers.

I'd reckon that C<number> is the behavior that most people want when dealing with
infinites. But since it's slower, it's not the default and you have to specify
it specifically. You should choose C<number> if target number is infinite.

=item * B<items> => I<int> (default: 1)

Return this number of closest numbers.

=item * B<nan> => I<str> (default: "exclude")

Specify how to handle NaN and non-numbers.

C<exclude> means the items will first be excluded from the list. C<nothing> will
do nothing about it, meaning there will be warnings when comparing non-numbers.

=item * B<number>* => I<num>

The target number.

=item * B<numbers>* => I<array>

The list of numbers.

=back

Return value:  (any)

=head1 FAQ

=head2 How do I find closest numbers that are {smaller, larger} than specified number?

You can filter (grep) your list of numbers first, for example to find numbers
that are closest I<and smaller or equal to> 3:

 my @nums = grep {$_ <= 3} 1, 3, 5, 2, 4;
 my $res = find_closest_number(number => 3, numbers => \@nums);

=head2 How do I find unique closest number(s)?

Perform uniq() (see L<List::MoreUtils>) on the resulting numbers.

=head1 SEE ALSO

L<Number::Closest>. Number::Closest::NonOO is a non-OO version of
Number::Closest, with some additional features: customize handling NaN/Inf, find
farthest number.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Number-Closest-NonOO>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Number-Closest-NonOO>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Number-Closest-NonOO>

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
