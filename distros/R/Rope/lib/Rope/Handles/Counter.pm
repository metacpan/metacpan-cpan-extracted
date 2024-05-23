package Rope::Handles::Counter;

use strict;
use warnings;

sub new {
	my ($class, $str) = @_;
	bless \$str, __PACKAGE__;
}

sub increment { ${$_[0]} += ($_[1] ? $_[1] : 1) }
 
sub decrement { ${$_[0]} -= ($_[1] ? $_[1] : 1) }
 
sub reset { ${$_[0]} = 0 }

sub clear { $_[0]->reset }

1;

__END__

=head1 NAME

Rope::Handles::Counter - Rope handles counters

=head1 VERSION

Version 0.37

=cut

=head1 SYNOPSIS

	package Church;

	use Rope;
	use Rope::Autoload;

	property singular => (
		initable => 1,
		handles_via => 'Rope::Handles::Counter'
	);

	property plural => (
		initable => 1,
		handles_via => 'Rope::Handles::Counter',
		handles => {
			plural_inc => 'increment',
			plural_dec => 'decrement',
			plural_res => 'reset',
		}
	);

	...

=head1 Methods

=head2 increment

=head2 decrement

=head2 reset

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

