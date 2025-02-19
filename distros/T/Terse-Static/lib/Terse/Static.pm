package Terse::Static;

our $VERSION = '0.12';

1;

__END__;

=head1 NAME

Terse::Static - Serve static resources

=head1 VERSION

Version 0.12

=cut

=head1 SYNOPSIS

	package MyApp::View::Static;

	use base 'Terse::View::Static::Memory';

	1;

	package MyApp::Controller::Static;

	use base 'Terse::Controller::DelayedStatic';

	1;

	package MyApp::Controller::Web;

	use base 'Terse::Controller';

	sub web :get :delayed :view(static) :content_type(text/html);

	1;
	...

	GET localhost/static/js/app.js
	GET localhost/web

=cut

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-terse-static at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Terse-Static>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Terse::Static


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Terse-Static>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Terse-Static>

=item * Search CPAN

L<https://metacpan.org/release/Terse-Static>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2022 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1; # End of Terse::Static
