# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Net - Allgemeine Netzwerkfunktionalität

=cut

# -----------------------------------------------------------------------------

package Quiq::Net;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

use IO::Socket::INET ();

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Klassenmethoden

=head3 checkPort() - Prüfe, ob Port belegt ist

=head4 Synopsis

  $bool = $class->checkPort($host,$port,@opt);

=head4 Arguments

=over 4

=item $host

Name oder IP-Adresse des Host.

=item $port

Portnummer.

=back

=head4 Returns

Bool

=head4 Description

Prüfe, ob Port $port auf Host $host belegt, also von einem Prozess
geöffnet ist. Falls ja, lefere I<wahr>, andernfalls I<falsch>.

=cut

# -----------------------------------------------------------------------------

sub checkPort {
    my ($self,$host,$port) = splice @_,0,3;

    my $sock = IO::Socket::INET->new(
       PeerAddr => $host,
       PeerPort => $port,
       Proto => 'tcp', # 'tcp', 'udp', ...
       Timeout => 10,
    );

    return $sock? 1: 0;
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.228

=head1 AUTHOR

Frank Seitz, L<http://fseitz.de/>

=head1 COPYRIGHT

Copyright (C) 2025 Frank Seitz

=head1 LICENSE

This code is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# -----------------------------------------------------------------------------

1;

# eof
