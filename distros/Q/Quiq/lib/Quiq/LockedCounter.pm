# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::LockedCounter - Persistenter Zähler mit Lock

=head1 BASE CLASS

L<Quiq::Object>

=head1 SYNOPSIS

  use Quiq::LockedCounter;
  
  $cnt = Quiq::LockedCounter->new($file)->increment;
  ...
  $n = $cnt->count;

=head1 DESCRIPTION

Die Klasse realisiert einen Zähler mit Exklusiv-Lock. Der
Zählerstand wird in einer Datei gespeichert. Die Datei wird
gelockt. Der Lock wird bis zur Destrukturierung des Objekts
gehalten.

=cut

# -----------------------------------------------------------------------------

package Quiq::LockedCounter;
use base qw/Quiq::Object/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

use Quiq::FileHandle;

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Counter

=head4 Synopsis

  $ctr = Quiq::LockedCounter->new($file);

=head4 Returns

Objekt

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$file) = @_;

    my $fh = Quiq::FileHandle->open('+>>',$file,-lock=>'EX');
    $fh->autoFlush;
    $fh->seek(0);
    my $count = <$fh>;
    if ($count) {
        chomp $count;
    }
    else {
        $fh->truncate;
        $fh->print("0\n");
        $count = 0;
    }

    return bless [$file,$fh,$count],$class;
}

# -----------------------------------------------------------------------------

=head2 Operationen

=head3 count() - Liefere Zählerstand

=head4 Synopsis

  $n = $ctr->count;

=head4 Returns

Zählerstand (Integer)

=cut

# -----------------------------------------------------------------------------

sub count {
    return shift->[2];
}

# -----------------------------------------------------------------------------

=head3 file() - Liefere Dateipfad

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

=head3 increment() - Inkrementiere Zählerstand

=head4 Synopsis

  $ctr = $ctr->increment;

=head4 Returns

Objekt

=cut

# -----------------------------------------------------------------------------

sub increment {
    my $self = shift;

    my $fh = $self->[1];
    $fh->truncate;
    $fh->print(++$self->[2],"\n");

    return $self;
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
