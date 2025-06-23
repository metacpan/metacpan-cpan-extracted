# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Gimp - GIMP Operationen

=head1 BASE CLASS

L<Quiq::Object>

=cut

# -----------------------------------------------------------------------------

package Quiq::Gimp;
use base qw/Quiq::Object/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

use Quiq::Path;
use Quiq::Shell;

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Klassenmethoden

=head3 edit() - Editiere Bilder mit GIMP

=head4 Synopsis

  $class->edit(@files);

=head4 Arguments

=over 4

=item @files

Pfade der Bilder, die editiert werden sollen.

=back

=head4 Description

Editiere die Bilddateien @files mit GIMP. Es findet eine Tilde-Expansion
statt und es wird die Existenz der Pfade geprüft. Existiert ein
Pfad nicht, wird eine Exception geworfen.

=cut

# -----------------------------------------------------------------------------

sub edit {
    my $class = shift;
    # @_: @files

    my $p = Quiq::Path->new;

    my @files;
    for (@_) {
        my $file = $p->expandTilde($_);
        if (!-f $file) {
            $class->throw(
                'GIMP-00001: File not found',
                File => $file,
            );
        }
        push @files,$file;
    }

    Quiq::Shell->exec("gimp @files");

    return;
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
