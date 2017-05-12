package POE::Component::Server::NRPE::Constants;
{
  $POE::Component::Server::NRPE::Constants::VERSION = '0.18';
}

#ABSTRACT: Defines constants required by POE::Component::Server::NRPE

require Exporter;
@ISA    = qw(Exporter);
@EXPORT = qw(NRPE_STATE_OK NRPE_STATE_WARNING NRPE_STATE_CRITICAL NRPE_STATE_UNKNOWN);

use strict;
use warnings;

use constant NRPE_STATE_OK	     => 0;
use constant NRPE_STATE_WARNING  => 1;
use constant NRPE_STATE_CRITICAL => 2;
use constant NRPE_STATE_UNKNOWN  => 3;

1;

__END__

=pod

=head1 NAME

POE::Component::Server::NRPE::Constants - Defines constants required by POE::Component::Server::NRPE

=head1 VERSION

version 0.18

=head1 SYNOPSIS

  use POE::Component::Server::NRPE::Constants;

=head1 DESCRIPTION

POE::Component::Server::NRPE::Constants defines constants required by L<POE::Component::Server::NRPE>.

=over 4

=item NRPE_STATE_OK - The NRPE plugin found no error.

=item NRPE_STATE_WARNING - The plugin detected a condition worthy of a warning.

=item NRPE_STATE_CRITICAL - The plugin detected a critical condition.

=item NRPE_STATE_UNKNOWN - Something else happened.  Used internally when the plugin couldn't be executed.

=back

=head1 SEE ALSO

L<POE::Component::Server::NRPE>

L<http://nagiosplug.sourceforge.net/developer-guidelines.html>

=head1 AUTHORS

=over 4

=item *

Chris Williams <chris@bingosnet.co.uk>

=item *

Rocco Caputo <rcaputo@cpan.org>

=item *

Olivier Raginel <github@babar.us>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Chris Williams, Rocco Caputo, Olivier Raginel and STIC GmbH.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
