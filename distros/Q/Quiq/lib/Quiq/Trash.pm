# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Trash - Operationen auf dem Trash von XFCE

=head1 BASE CLASS

L<Quiq::Hash>

=cut

# -----------------------------------------------------------------------------

package Quiq::Trash;
use base qw/Quiq::Hash/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

use Quiq::Path;
use Quiq::Terminal;

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Objekt

=head4 Synopsis

  $t = $class->new;
  $t = $class->new($trashDir);

=head4 Arguments

=over 4

=item $trashDir (Default: '~/.local/share/Trash')

Pfad zum Trash.

=back

=head4 Returns

Objekt

=head4 Description

Instantiiere ein Objekt der Klasse und liefere dieses zurück. Weicht
der Trash-Pfad vom Standard-Pfad ab, kann dieser als Parameter
gesetzt werden.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    my $trashDir = @_? shift: '~/.local/share/Trash';

    return $class->SUPER::new(
        trashDir => $trashDir,
    );
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 emptyTrash() - Leere Trash

=head4 Synopsis

  $t->emptyTrash;
  $t->emptyTrash($ask);

=head4 Arguments

=over 4

=item $ask (Default: 0)

Stelle Rückfrage an den Benutzer, wenn der Trash nicht leer ist.

=back

=head4 Description

Leere den Trash, d.h. lösche I<alle> Dateien aus C<$trashDir/files> und
C<$trashDir/info>.

=cut

# -----------------------------------------------------------------------------

sub emptyTrash {
    my ($self,$ask) = @_;

    my $p = Quiq::Path->new;

    my $trashDir = $self->trashDir;
    if ($ask) {
        my $pathA = $p->find("$trashDir/files",-excludeRoot=>1,-sort=>1);
        if (@$pathA) {
            say join "\n",@$pathA;
            my $answ = Quiq::Terminal->askUser(
                'Delete existing trash files?',
                -values => 'y/n',
                -default => 'y',
            );
            if ($answ eq 'n') {
                return;
            }
        }
    }

    $p->deleteContent("$trashDir/files");
    $p->deleteContent("$trashDir/info");

    return;
}

# -----------------------------------------------------------------------------

=head3 files() - Liste der im Trash enthaltenen Dateien

=head4 Synopsis

  @files | $fileA = $t->files;

=head4 Returns

Liste von Dateien. Im Skalarkontext eine Referenz auf die Liste.

=head4 Description

Liefere die Liste aller im Trash enthaltene Dateien.

=cut

# -----------------------------------------------------------------------------

sub files {
    my $self = shift;

    my $trashDir = $self->trashDir;
    my $fileA = Quiq::Path->find("$trashDir/files",-type=>'f',-sort=>1);

    return wantarray? @$fileA: $fileA;
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
