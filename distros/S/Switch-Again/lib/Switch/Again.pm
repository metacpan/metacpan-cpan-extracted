package Switch::Again;

use 5.006;
use strict;
use warnings;
use base qw/Import::Export/;
our %EX = (
	'switch' => [qw/all/]
);

our $VERSION = '0.01';

our %SWITCH;
BEGIN {
	%SWITCH = (
		SCALAR => sub { ref $_[1] ? undef : $_[0] =~ m/^$_[1]$/; }
		# tbc
	);
}

sub switch {
	my ($value, $default, @cases);
	$value = shift if (scalar @_ % 2); 
	$_[0] eq 'default' ? do { shift; $default = shift } : do { push @cases, { case => shift, cb => shift } } 
		while (@_); # I could map to a hash but...
	my $evil = sub {
		my ($val, $ref, $result) = ($_[0], ref $_[0] || 'SCALAR');
		$SWITCH{$ref}($val, $_->{case}) && do { $result = ref $_->{cb} eq 'CODE' ? $_->{cb}->($val) : $_->{cb} } && last for @cases;	
		defined $result ? $result : $default ? $default->($val) : undef;
	};
	$value ? $evil->($value) : $evil;
}

__END__;

=head1 NAME

Switch::Again - Switch`ing

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

	use Switch::Again qw/switch/;
	my $switch = switch(
		a => sub {
			return 1;
		},
		b => sub {
			return 2;
		},
		c => sub {
			return 3;
		},
		default => sub {
			return 4;
		}
	);
	my $val = $switch->('a'); # 1

	...

	use Switch::Again qw/all/;
	my $val = switch('e', 
		d => sub {
			return 1;
		},
		e => sub {
			return 2;
		},
		f => sub {
			return 3;
		},
		default => sub {
			return 4;
		}
	); # 2

=cut

=head1 AUTHOR

LNATION, C<< <thisusedtobeanemail at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-switch-again at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Switch-Again>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Switch::Again

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Switch-Again>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Switch-Again>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Switch-Again>

=item * Search CPAN

L<http://search.cpan.org/dist/Switch-Again/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2018 Robert Acock.

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

1; # End of Switch::Again
