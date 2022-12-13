package Terse::Headers;

our $VERSION = '0.01';

1;

__END__

=head1 NAME

Terse::Headers - Terse headers

=cut

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS


	package MyApp;

	use base 'Terse';
	use Terse::Plugin::Headers;

	sub build_app {
		$_[0]->headers = Terse::Plugin::Headers->new;
	}

	sub auth {
		my ($self, $context) = @_;
		if ($context->req) { # second run through of the auth sub routine
			$self->headers->set($context, %headers);
		}
	}

	1;

=cut

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-terse-headers at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Terse-Headers>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Terse::Headers

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Terse-Headers>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Terse-Headers>

=item * Search CPAN

L<https://metacpan.org/release/Terse-Headers>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2022 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1; # End of Terse::Headers
