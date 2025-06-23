# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Chrome - Operationen im Zusammenhang mit dem Chrome Browser

=head1 BASE CLASS

L<Quiq::Object>

=cut

# -----------------------------------------------------------------------------

package Quiq::Chrome;
use base qw/Quiq::Object/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

use Quiq::Path;

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Methoden

=head3 renameHtmlDownload() - Benenne heruntergeladene HTML-Seite um

=head4 Synopsis

  $this->renameHtmlDownload($oldName,$newName);

=head4 Arguments

=over 4

=item $oldName

Aktueller Name der HTML-Datei, die heruntergeladen wurde.

=item $newName

Aktueller Name der HTML-Datei, die heruntergeladen wurde.

=back

=head4 Description

Wird eine HTML-Seite mit Chrome heruntergeladen
(C<Rechte Maustaste / Save as...>), wird diese unter dem im Download-Dialog
vergebenen Namen I<NAME>C<.html> abgespeichert. Zusätzlich wird ein
Verzeichnis I<NAME>C<_files> für die von der Seite inkludierten
Bestandteile angelegt.

WICHTIG: Die Umbennung muss im aktuellen Verzeichnis stattfinden.

=head4 Example

  $ perl -MQuiq::Chrome -E 'Quiq::Chrome->renameHtmlDownload("fehler.html","01-172667217700-zugferd-2.3.html")'

=cut

# -----------------------------------------------------------------------------

sub renameHtmlDownload {
    my ($class,$oldName,$newName) = @_;

    my $p = Quiq::Path->new;

    my $oldDir = sprintf '%s_files',$p->basename($oldName);
    my $newDir = sprintf '%s_files',$p->basename($newName);

    if (!$p->exists($oldName)) {
        $class->throw(
            'CHROME-00099: File does not exist',
            File => $oldName,
        );
    }

    if (!$p->exists($oldDir)) {
        $class->throw(
            'CHROME-00099: Directory does not exist',
            Dir => $oldDir,
        );
    }

    my $html = $p->read($oldName);
    $html =~ s/$oldDir/$newDir/g;
    $p->write($newName,$html);

    $p->rename($oldDir,$newDir);

    return;
};

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
