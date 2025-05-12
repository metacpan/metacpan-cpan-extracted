package Rope::Handles::Bool;

use strict;
use warnings;

sub new {
	my ($class, $str) = @_;
	bless \$str, __PACKAGE__;
}

sub set { ${$_[0]} = 1 }
 
sub unset { ${$_[0]} = 0 }
 
sub toggle { ${$_[0]} = ${$_[0]} ? 0 : 1; }
 
sub not { !${$_[0]} }

sub clear { $_[0]->unset }

1;

__END__

=head1 NAME

Rope::Handles::Bool - Rope handles booleans

=head1 VERSION

Version 0.44

=cut

=head1 SYNOPSIS

	package Church;

	use Rope;
	use Rope::Autoload;

	property singular => (
		initable => 1,
		handles_via => 'Rope::Handles::Bool'
	);

	property plural => (
		initable => 1,
		handles_via => 'Rope::Handles::Bool',
		handles => {
			plural_set => 'set',
			plural_unset => 'unset',
			plural_not => 'not',
		}
	);

	...

=head1 Methods

=head2 set

=head2 unset

=head2 toggle

=head2 not

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

