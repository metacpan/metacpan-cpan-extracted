package Struct::Match;
use 5.006; use strict; use warnings; no warnings qw(void); use utf8; our $VERSION = '0.07';
use Combine::Keys qw/combine_keys/;
use base 'Import::Export';
our %STRUCT;
our %EX = ('match' => ['all'], '%STRUCT' => ['struct', 'all']);

BEGIN {
	%STRUCT = (
		SCALAR => sub {
			$STRUCT{SAME}($_[1], 'SCALAR')
				and do {
					my $s = quotemeta($_[1]);
					$_[0] =~ m†^($s)$†;
				};
		},
		HASH => sub {
			$STRUCT{SAME}($_[1], 'HASH')
				and ! $STRUCT{ADDR}($_[0], $_[1])
					? do {
						exists $_[0]->{$_} && exists $_[1]->{$_} && match($_[0]->{$_}, $_[1]->{$_})
							or return for combine_keys($_[0], $_[1]);
						1;
					}
					: 1;
		},
		ARRAY => sub {
			$STRUCT{SAME}($_[1], 'ARRAY')
				and ! $STRUCT{ADDR}($_[0], $_[1])
					? (((
							grep {
								exists $_[0][$_] && match($_[0][$_], $_[1][$_])
							} 0 .. $#{$_[1]}
						) == @{$_[0]}
					) && $#{$_[0]} == $#{$_[1]})
					: 1;
		},
		ADDR => sub {
			0 + $_[0] == 0 + $_[1];
		}, # thou shall not pass/work if the object has + overloaded
		CHECK => sub {
			my $t = $STRUCT{REFTYPE}($_[0]);
			$STRUCT{SAME}($_[1], $t) && $STRUCT{$t}($_[0], $_[1]);
		},
		REFTYPE => sub {
			eval { $_[0]->[0] }
				? 'ARRAY'
				: eval { $_[0]->{shamed}; 1 }
						? 'HASH'
						: 'ADDR';
		},
		REF => sub {
			my $r = ref($_[0]);
			$r and ((exists $STRUCT{$r} && $r) || 'CHECK') or 'SCALAR';
		},
		SAME => sub {
			my $s = $STRUCT{REF}($_[0]);
			$s eq 'CHECK' && do { $s = $STRUCT{REFTYPE}($_[0]) };
			$s eq $_[1];
		},
		# currently we do not care about CODE|GLOB|REF|LVALUE|FORMAT|IO|VSTRING|Regexp.. other than doing ref address check hushh
	);
}

sub match { my $o = $STRUCT{REF}($_[0]); $STRUCT{$o}($_[0], $_[1]) or $_[2] && $o eq 'CHECK' && 1 or 0; }

__END__

=head1 NAME

Struct::Match - Exact Match (SCALAR|HASH|ARRAY)'s.

=head1 VERSION

Version 0.07

=cut

=head1 SYNOPSIS

	use Struct::Match qw/match/;

	my $bool = match $airport, $code; # 1

=cut

=head2 Upsetting

Currently when passed a CODE|GLOB|REF|LVALUE|FORMAT|IO|VSTRING|Regexp match will likely return false. unless you pass a third parameter to bypass this.

=cut

=head2 match

Accepts two variables and checks whether they match. Is $variable1 == $variable2 if true then this function returns 1 if false then this function will return 0.

=cut

=head1 extending

Sometimes you may need custom match behaviour or will want to expand to handle more than just (SCALAR|HASH|ARRAY)'s, to do this you can simply import and append the %STRUCT variable.

	package Custom::Match;
	use Struct::Match qw/struct/;

	BEGIN {
		@STRUCT{qw/Regexp CODE/} = (
			sub { $_[1] =~ $_[0]; },
			sub { my $v = eval { $_[0]->($_[1]) }; }
		);
	}

=head1 AUTHOR

LNATION, C<< <thisusedtobeanemail at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-struct-match at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Struct-Match>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Struct::Match

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Struct-Match>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Struct-Match>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Struct-Match>

=item * Search CPAN

L<http://search.cpan.org/dist/Struct-Match/>

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

1; # End of Struct::Match
