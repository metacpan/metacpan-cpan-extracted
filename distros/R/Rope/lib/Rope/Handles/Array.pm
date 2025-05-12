package Rope::Handles::Array;

use strict;
use warnings;
use base qw/Data::LnArray/;

1;

__END__

=head1 NAME

Rope::Handles::Array - Rope handles arrays

=head1 VERSION

Version 0.44

=cut

=head1 SYNOPSIS

	package Church;

	use Rope;
	use Rope::Autoload;

	property singular => (
		initable => 1,
		handles_via => 'Rope::Handles::Array'
	);

	property plural => (
		initable => 1,
		handles_via => 'Rope::Handles::Array',
		handles => {
			get_thing => 'get',
			set_thing => 'set',
			push_thing => 'push',
			length_thing => 'length'
		}
	);

	...

See L<Data::LnArray> for documentation

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

