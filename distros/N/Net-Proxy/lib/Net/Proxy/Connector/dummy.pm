package Net::Proxy::Connector::dummy;
$Net::Proxy::Connector::dummy::VERSION = '0.13';
use strict;
use warnings;

use Net::Proxy::Connector;
our @ISA = qw( Net::Proxy::Connector );

# IN
sub listen { }

sub accept_from { }

# OUT
sub connect { }

# READ
sub read_from { return '' }

# WRITE
sub write_to { }

1;

__END__

=head1 NAME

Net::Proxy::Connector::dummy - Dummy Net::Proxy connector

=head1 DESCRIPTION

C<Net::Proxy::Connecter::dummy> is a C<Net::Proxy::Connector>
that does I<nothing>. It doesn't listen for incoming connections
and does connect to other hosts.

Future connectors may have their C<accept_from()> method also
handle the connection to a remote host. In this case, C<dummy>
may be used as an 'out' connector.

You could also use the source code of this module as a template
for writing new C<Net::Proxy::Connector> classes.

=head1 CONNECTOR OPTIONS

None.

=head1 AUTHOR

Philippe 'BooK' Bruhat, C<< <book@cpan.org> >>.

=head1 COPYRIGHT

Copyright 2006 Philippe 'BooK' Bruhat, All Rights Reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

