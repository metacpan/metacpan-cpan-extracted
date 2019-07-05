package Quiq::Excel::Writer;
use base qw/Excel::Writer::XLSX/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.149';

use Quiq::Path;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Excel::Writer - Erzeuge Datei im Excel 2007+ XLSX Format

=head1 BASE CLASS

Excel::Writer::XLSX

=head1 DESCRIPTION

Diese Klasse ist abgeleitet von Excel::Writer::XLSX.
Sie erweitert die Basisklasse um

=over 2

=item *

Tilde-Expansion im Dateinamen

=item *

Exceptions im Fehlerfall

=back

Dokumentation siehe Basisklasse.

=head1 METHODS

=head2 Klassenmethoden

=head3 new() - Konstruktor

=head4 Synopsis

    $wkb = $class->new($file);
    $wkb = $class->new($fh);

=head4 Arguments

=over 4

=item $file

Name der .xslx Datei.

=item $fh

Filehandle, auf die geschrieben wird, z.B. \*STDOUT.

=back

=head4 Returns

Workbook-Objekt

=head4 Description

Erzeuge ein Excel Workbook-Objekt und liefere eine Referenz auf
dieses Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$arg) = @_;

    if (!ref $arg) {
        $arg = Quiq::Path->expandTilde($arg);
    }

    my $wkb = $class->SUPER::new($arg);
    if (!$wkb) {
        $class->throw(
            'EXCEL-00099: Can\'t instantiate workbook object',
            Error => $!,
        );
    }

    return $wkb;
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.149

=head1 AUTHOR

Frank Seitz, L<http://fseitz.de/>

=head1 COPYRIGHT

Copyright (C) 2019 Frank Seitz

=head1 LICENSE

This code is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# -----------------------------------------------------------------------------

1;

# eof
