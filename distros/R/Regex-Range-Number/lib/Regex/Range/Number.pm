package Regex::Range::Number;

use 5.006;
use strict;
use warnings;
use Array::Merge::Unique qw/unique_array/;
use base qw/Import::Export/;
our $VERSION = '0.04';
our (%helper, %cache);
BEGIN {
	%helper = (
		zip => sub {
			[ map {
				[substr( $_[0], $_ , 1 ), substr($_[1], $_, 1)]
			} 0 .. (length($_[0]) - 1) ]
		},
		compare => sub {
			$_[0] > $_[1] ? 1 : $_[1] > $_[0] ? -1 : 0;
		},
		push => sub {
			unique_array($_[0], $_[1]);
		},
		contains => sub {
			my (%u);
			grep { !$u{$_->{$_[1]}} && do { $u{$_->{$_[1]}} = 1 } && $_ } @{ $_[0] };
			$u{$_[2]};
		},
		nines => sub {
			substr($_[0], 0, (0 - $_[1])) . ('9' x $_[1]);
		},
		zeros => sub {
			$_[0] - $_[0] % 10 ^ $_[1];
		},
		quantifier => sub {
			my ($s, $st) = ($_[0]->[0], ($_[0]->[1] ? (',' . $_[0]->[1]) : ''));
			return '' if (!$s || $s == 1);
			return '{' . $s . $st . '}';
		},
		character => sub {
			sprintf '[%s%s%s]', $_[0], (($_[1] - $_[0]) == 1 ? '' : '-'), $_[1];
		},
		padding => sub {
			$_[0] =~ m/^-?(0+)\d/;
		},
		padz => sub {
			if ($_[1]->{isPadded}) {
				my $d = $_[1]->{maxLen} - length $_[0];
				return ! $d ? $d == 0 ? '' : '0{' . $d . '}' : '0';
			}
			$_[0];
		},
		min => sub {
			$_[0] < $_[1] ? $_[0] : $_[1];
		},
		max => sub {
			$_[0] < $_[1] ? $_[1] : $_[0];
		},
		capture => sub {
			sprintf "(%s)", $_[0];
		},
		sift => sub {
			return join '|', $helper{filter}($_[0]->{negatives}, $_[0]->{positives}, '-', 0, $_[1]), $helper{filter}($_[0]->{positives}, $_[0]->{negatives}, '', 0, $_[1]), $helper{filter}($_[0]->{negatives}, $_[0]->{positives}, '-?', 1, $_[1]);
		},
		ranges => sub {
			my ($m, $mx, $n, $z, $s) = (($_[0] + 0), ($_[1] + 0), 1, 1, [($_[1] + 0)]);
			my $st = $helper{nines}($m, $n);
			while ($m <= $st && $st <= $mx) {
				$s = $helper{push}($s, $st);
				$n += 1;
				$st = $helper{nines}($m, $n);
			}
			$st = $helper{zeros}($mx + 1, $z) - 1;
			while ($m < $st && $st <= $mx) {
				$s = $helper{push}($s, $st);
				$z += 1;
				$st = $helper{zeros}($mx + 1, $z) - 1;
			}
			return [sort { $a <=> $b } @{ $s }];
		},
		pattern => sub {
			my ($s, $st) = @_;
			return {
				pattern => $s,
				digits => []
			} if ($s == $st);
			my ($z, $p, $d) = ($helper{zip}($s, $st), '', 0);
			for my $n (@{$z}) {
				($n->[0] == $n->[1])
					? do { $p .= $n->[0] }
					: ($n->[0] != 0 || $n->[1] != 9)
						? do {$p .= $helper{character}(@{$n})}
						: do { $d += 1 };
			}
			$p .= '[0-9]' if ($d);
			return { pattern => $p, digits => [$d] };
		},
		split => sub {
			my ($m, $mx, $tok) = @_;
			my ($r, $t, $s, $p) = ($helper{ranges}($m, $mx), [], $m);
			for my $rr (@{$r}) {
				my $o = $helper{pattern}($s, $rr);
				my $zeros = '';
				if ( !$tok->{isPadded} && $p && $p->{pattern} eq $o->{pattern}) {
					pop @{ $p->{digits} } if (scalar @{ $p->{digits} } > 1);
					push @{ $p->{digits} }, $o->{digits};
					$p->{string} = $p->{pattern} . $helper{quantifier}($p->{digits});
					$s = $rr . 1;
					next;
				}
				$zeros = $helper{padz}($rr, $tok) if $tok->{isPadded};
				$o->{string} = $zeros . $o->{pattern} . $helper{quantifier}($o->{digits});
				push @{$t}, $o;
				$s = $rr + 1;
				$p = $o;
			}
			return $t;
		},
		filter => sub {
			my ($arr, $c, $p, $i, $o) = @_;
			my @r = ();
			foreach my $tok ( @{ $arr }) {
				my $e = $tok->{string};
				if (!$i && !$helper{contains}($c, 'string', $e)) {
					push @r, $p . $e;
				}
				elsif ($i && $helper{contains}($c, 'string', $e)) {
					push @r, $p . $e;
				}
			}
			return @r;
		}
	);
}

our %EX = (
	number_range => [qw/all/],
	'%helper' => [qw/all/]
);

sub new { bless {}, $_[0] }

sub helpers {
	return %helper;
}

sub number_range {
	ref $_[0] eq 'Regex::Range::Number' and shift @_;
	my ($start, $max, $options) = @_;

	if (ref $start eq 'ARRAY') {
		$max = {} unless ref $max eq 'HASH';
		map { 
			return $max->{capture} 
				? sprintf('(%s)', $_) 
				: $_ 
		} join '|', 
			map { number_range($_->[0], $_->[1], $max->{individual} ? {capture => 1, %{$max}} : ()) }
			grep { ref $_ eq 'ARRAY' } 
		@{$start};
	}

	return $start if (not defined $max || $start == $max);

	$options ||= {};
	my $capture = $options->{capture} || '';
	
	my $key = sprintf('%s:%s=%s', $start, $max, $capture);
	return $cache{$key}->{result} if $cache{$key};

	my ($a, $b) = ($helper{min}($start, $max), $helper{max}($start, $max));

	if ( ($b - $a) == 1 ) {
		my $result = $start . '|' . $max;
		$result = $helper{capture}($result) if ($options->{capture});
		$cache{$key} = { result => $result };
		return $result;
	}

	my $tok = {
		min => $a,
		max => $b,
		positives => [],
		negatives => [],
		($helper{padding}($a) || $helper{padding}($b) ? (
			isPadded => 1,
			maxLen => length $max
		) : ())
	};

	if ( $a < 0 ) {
		my $newMin = $b < 0 ? $b : 1;
		$tok->{negatives} = $helper{split}($newMin, $a, $tok, $options);
		$a = $tok->{a} = 0;
	}

	$tok->{positives} = $helper{split}($a, $b, $tok, $options) if ($b >= 0);
	$tok->{result} = $helper{sift}($tok, $options);
	$tok->{result} = $helper{capture}($tok->{result}) if $capture;

	$cache{$key} = $tok;
	return $tok->{result};
}

=head1 NAME

Regex::Range::Number - Generate number matching regexes

=head1 VERSION

Version 0.04

=cut

=head1 SYNOPSIS

	use Regex::Range::Number;

	my $gene = Regex::Range::Number->new();
	my $reg = $gene->number_range(100, 1999); # 10[0-9]|1[1-9][0-9]|[2-9][0-9]{2}|1[0-9]{3}
	1234 =~ m@$reg@;

	...

	use Regex::Range::Number qw/number_range/;
	my $reg = number_range(100, 1999, { capture => 1 }); # (10[0-9]|1[1-9][0-9]|[2-9][0-9]{2}|1[0-9]{3})
	1234 =~ m?$reg?; 

	my $range = number_range([[55, 56], [75, 89], [92, 100]], {capture => 1}); # (55|56|7[5-9]|8[0-9]|9[2-9]|100)'

=cut

=head1 AUTHOR

LNATION, C<< <thisusedtobeanemail at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-regex-range-number at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Regex-Range-Number>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Regex::Range::Number


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Regex-Range-Number>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Regex-Range-Number>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Regex-Range-Number>

=item * Search CPAN

L<http://search.cpan.org/dist/Regex-Range-Number/>

=back

=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2018 LNATION.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Regex::Range::Number
