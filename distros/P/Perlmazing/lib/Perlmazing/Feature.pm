package Perlmazing::Feature;
use strict;
use warnings;
use version;
our $VERSION = '1.2810';
our @ISA = qw(feature);

sub import {
	my $self = shift;
	strict->import;
	warnings->import;
	eval {
		require feature;
		$Perlmazing::Feature::{unknown_feature_bundle} = sub {} unless defined $Perlmazing::Feature::{unknown_feature_bundle};
		$self->SUPER::import(':'.substr version->new($])->normal, 1);
	};
}

1;

__END__
=pod
=head1 NAME

Perlmazing::Feature - Use strict and warnigns and enable all modern features from your Perl version in a single call.


=head1 SYNOPSIS

This aims to be the equivalent of:

	use strict;
	use warnings;
	use $]; # your Perl version - this doesn't work as written, by the way.
	
Instead of that, all you have to do is:

	use Perlmazing::Feature;
	
And, if you want the same thing for any module or scrit calling your module, then you can simply do this:

	use Perlmazing::Feature
	
	sub import {
		Perlmazing::Feature->import;
	}


=head1 AUTHOR

Francisco Zarabozo, C<< <zarabozo at cpan.org> >>


=head1 BUGS

Please report any bugs or feature requests to C<bug-perlmazing at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perlmazing>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Perlmazing::Engine


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Perlmazing>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Perlmazing>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Perlmazing>

=item * Search CPAN

L<http://search.cpan.org/dist/Perlmazing/>

=back



=head1 ACKNOWLEDGEMENTS

This module was inspired by L<latest> from Andy Armstrong. Some changes were made to accommodate the needs of L<Perlmazing>.


=head1 LICENSE AND COPYRIGHT

Copyright 2015 Francisco Zarabozo.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.


=cut
