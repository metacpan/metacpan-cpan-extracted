package Quiq::Diff;
use base qw/Quiq::Object/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.153';

use Quiq::TempFile;
use Quiq::Shell;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Diff - Zeige Differenzen zwischen Zeichenketten

=head1 BASE CLASS

L<Quiq::Object>

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

    my $file1 = Quiq::TempFile->new($str1);
    my $file2 = Quiq::TempFile->new($str2);

    return Quiq::Shell->exec("diff --ignore-space-change $file1 $file2",
        -capture => 'stdout',
        -sloppy => 1,
    );
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.153

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
