package Mojo::Server::CGI::LegacyMigrate;
use Mojo::Base 'Mojo::Server::CGI';

use strict;
use warnings;

our $VERSION = '0.01';

sub run {

  # We withhold headers if anything has written to
  # STDOUT. This is neccessary because some scripts, in-transition
  # to Mojo will still use `print`, and output headers
  if ( tell(*STDOUT) != 0 ) {
    return undef;
  }

	goto &Mojo::Server::CGI::run;

}

1;

__END__

=head1 NAME

Mojo::Server::CGI::LegacyMigrate - Migrate older Legacy CGI scripts

=head1 DESCRIPTION

L<Mojo::Server::CGI::LegacyMigrate> is a subclass of L<Mojo::Server::CGI>. It has one important modification.

=over 12

=item If something has been printed to STDOUT

This module assumes that you're migrating a legacy CGI application that uses
print. Put another way, that you're coming from a technology that doesn't use
Mojo to prepare response headers and the response body. If so, you're on your
own. Enjoy the mojo router.

=item If nothing has been printed to STDOUT

This module acts in every other way exactly like Mojo::Server::CGI and any
other deviaition is a bug.

=back

=head1 AUTHOR

Evan Carroll, C<< <me at evancarroll.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mojo-server-cgi-legacymigrate at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Mojo-Server-CGI-LegacyMigrate>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Mojo::Server::CGI::LegacyMigrate


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Mojo-Server-CGI-LegacyMigrate>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Mojo-Server-CGI-LegacyMigrate>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Mojo-Server-CGI-LegacyMigrate>

=item * Search CPAN

L<https://metacpan.org/release/Mojo-Server-CGI-LegacyMigrate>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2019 by Evan Carroll.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Mojo::Server::CGI::LegacyMigrate
