# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Diff - Zeige Differenzen zwischen Zeichenketten

=head1 BASE CLASS

L<Quiq::Object>

=cut

# -----------------------------------------------------------------------------

package Quiq::Diff;
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

=head3 diff() - Vergleiche Zeichenketten per diff(1)

=head4 Synopsis

  $diff = $class->diff($str1,$str2);

=head4 Arguments

=over 4

=item $str1

Erste Zeichenkette.

=item $str2

Zweite Zeichenkette.

=back

=head4 Returns

Differenzen (String)

=head4 Description

Vergleiche die Zeichenketten $str1 und $str2 per diff(1) und liefere
das Ergebnis zurück. Unterschiede im Umfang an Whitespace werden
ignoriert (diff-Option C<--ignore-space-change> ist gesetzt).

=head4 See Also

diff(1)

=cut

# -----------------------------------------------------------------------------

sub diff {
    my ($class,$str1,$str2) = @_;

    my $p = Quiq::Path->new;
    my $file1 = $p->tempFile($str1);
    my $file2 = $p->tempFile($str2);

    return Quiq::Shell->exec("diff --ignore-space-change $file1 $file2",
        -capture => 'stdout',
        -sloppy => 1,
    );
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
