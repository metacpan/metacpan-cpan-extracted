package Rope::Handles::Number;

use strict;
use warnings;

sub new {
	my ($class, $str) = @_;
	bless \$str, __PACKAGE__;
}

sub add { ${$_[0]} = ${$_[0]} + $_[1] }
 
sub subtract { ${$_[0]} = ${$_[0]} - $_[1] }
 
sub multiply { ${$_[0]} = ${$_[0]} * $_[1] }
 
sub divide { ${$_[0]} = ${$_[0]} / $_[1] }
 
sub modulus { ${$_[0]} = ${$_[0]} % $_[1] }
 
sub absolute { ${$_[0]} = abs(${$_[0]}) }

sub increment { ${$_[0]} += ($_[1] ? $_[1] : 1) }
 
sub decrement { ${$_[0]} -= ($_[1] ? $_[1] : 1) }

sub clear { ${$_[0]} = 0 }

1;

__END__

=head1 NAME

Rope::Handles::Number - Rope handles numbers

=head1 VERSION

Version 0.38

=cut

=head1 SYNOPSIS

	package Church;

	use Rope;
	use Rope::Autoload;

	property singular => (
		initable => 1,
		handles_via => 'Rope::Handles::Number'
	);

	property plural => (
		initable => 1,
		handles_via => 'Rope::Handles::Number',
		handles => {
			plural_add => 'add',
			plural_sub => 'subtract',
			plural_mul => 'multiply',
		}
	);

	...

=head1 Methods

=head2 add

=head2 subtract

=head2 multiply

=head2 divide

=head2 modulus

=head2 absolute

=head2 increment

=head2 decrement

=head2 clear

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-rope at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Rope>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Rope

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Rope>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Rope>

=item * Search CPAN

L<https://metacpan.org/release/Rope>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

