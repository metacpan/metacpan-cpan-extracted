# -----------------------------------------------------------------------------

=head1 NAME

Quiq::LockedContent - Persistenter Dateininhalt mit Lock

=head1 BASE CLASS

L<Quiq::Object>

=head1 SYNOPSIS

  use Quiq::LockedContent;
  
  $obj = Quiq::LockedContent->new($file);
  $data = $obj->read;
  ...
  $obj->write($data);

=head1 DESCRIPTION

Die Klasse realisiert einen persisteten Inhalt mit Exklusiv-Lock.
Der Inhalt kann gelesen und geschrieben werden. Die Datei wird
gelockt. Der Lock wird bis zur Destrukturierung des Objekts
gehalten.

=cut

# -----------------------------------------------------------------------------

package Quiq::LockedContent;
use base qw/Quiq::Object/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

use Quiq::Path;
use Quiq::FileHandle;

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Konstruktor/Destruktor

=head3 new() - Instantiiere Objekt

=head4 Synopsis

  $obj = Quiq::LockedContent->new($file);

=head4 Returns

Objekt

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    my $file = Quiq::Path->expandTilde(shift);

    my $fh = Quiq::FileHandle->open('+>>',$file,-lock=>'EX');
    $fh->autoFlush;

    return bless [$file,$fh],$class;
}

# -----------------------------------------------------------------------------

=head3 close() - Destrukturiere Objekt

=head4 Synopsis

  $obj->close;

=head4 Alias

destroy()

=cut

# -----------------------------------------------------------------------------

sub close {
    $_[0] = undef;
}

{
    no warnings 'once';
    *destroy = \&close;
}

# -----------------------------------------------------------------------------

=head2 Operationen

=head3 file() - Dateipfad

=head4 Synopsis

  $file = $ctr->file;

=head4 Returns

Dateipfad (String)

=cut

# -----------------------------------------------------------------------------

sub file {
    return shift->[0];
}

# -----------------------------------------------------------------------------

=head3 read() - Lies Daten

=head4 Synopsis

  $data = $obj->read;

=head4 Returns

String

=cut

# -----------------------------------------------------------------------------

sub read {
    my $self = shift;

    my $fh = $self->[1];
    $fh->seek(0);

    return $fh->slurp;
}

# -----------------------------------------------------------------------------

=head3 write() - Schreibe Daten

=head4 Synopsis

  $obj->write($data);

=cut

# -----------------------------------------------------------------------------

sub write {
    my $self = shift;
    # @_: $data

    my $fh = $self->[1];
    $fh->truncate;
    $fh->print($_[0]);

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
