package Number::Equation::XS;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.05';

require XSLoader;

XSLoader::load('Number::Equation::XS', $VERSION);

1;

__END__

=head1 NAME

Number::Equation::XS - Track how a number is calculated progamically.

=head1 VERSION

Version 0.05

=cut

=head1 SYNOPSIS

	use Number::Equation;
	my $foo = Number::Equation->new(42);
	my $n = Number::Equation->new(42);
	$n = $n - 2;
	$n /= 10;
	$n *= 3;
	$n += 1;
	my $m = 1 / $n;
	print $m->equation; # (1 / ((((42 - 2) / 10) * 3) + 1)) = 0.0769230769230769

	my $n = Number::Equation->new(42, .01);
	$n = $n - 2;
	$n /= 10;
	$n *= 3;
	$n += 1;
	my $m = 1 / $n;
	print $m->equation; # (1 / ((((42 - 2) / 10) * 3) + 1)) ≈ 0.08

	my $n = Number::Equation->new(211, 0);
	$n = $n ** 2;
	print $n->equation; # (211 ** 2) = 44521
	$n = $n % 2;
	print $n->equation; # ((211 ** 2) % 7) = 1

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-number-equation-xs at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Number-Equation-XS>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Number::Equation::XS


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Number-Equation-XS>

=item * Search CPAN

L<https://metacpan.org/release/Number-Equation-XS>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2025 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Number::Equation::XS
