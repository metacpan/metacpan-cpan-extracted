# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Digest - Erzeuge Digest

=head1 BASE CLASS

L<Quiq::Object>

=cut

# -----------------------------------------------------------------------------

package Quiq::Digest;
use base qw/Quiq::Object/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

use Digest::MD5 ();

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Klassenmethoden

=head3 md5() - MD5 Digest

=head4 Synopsis

  $md5 = $class->md5(@data);

=head4 Arguments

=over 4

=item @data

Skalare Werte beliebiger Anzahl und Länge.

=back

=head4 Returns

32 Zeichen Hex-String.

=head4 Description

Erzeuge einen MD5 Message Digest für die Daten @data und liefere diesen
als 32 Zeichen langen Hex-String zurück.

=cut

# -----------------------------------------------------------------------------

sub md5 {
    my $class = shift;
    # @_: @data
    return Digest::MD5::md5_hex(@_);
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
