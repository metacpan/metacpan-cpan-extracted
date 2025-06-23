# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Smb::Client - SMB Client

=head1 BASE CLASS

L<Quiq::Hash>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert einen SMB-Client. Die Klasse
realisiert ihre Funktionalität unter Rückgriff auf
L<Filesys::SmbClient|https://metacpan.org/pod/Filesys::SmbClient>,
allerdings nicht durch Ableitung, sondern durch Einbettung.
Die Klasse zeichnet sich dadurch aus, dass sie

=over 2

=item *

höhere Dateioperationen wie ls(), get() und put() realisiert
(ähnlich FTP)

=item *

Fehler nicht über Returnwerte anzeigt, sondern im Fehlerfall
eine Exception wirft

=back

=cut

# -----------------------------------------------------------------------------

package Quiq::Smb::Client;
use base qw/Quiq::Hash/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

use Filesys::SmbClient ();
use Quiq::Path;

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Objekt

=head4 Synopsis

  $smb = $class->new(%args);

=head4 Arguments

=over 4

=item %args

Liste von Schlüssel/Wert-Paaren, siehe
L<Filesys::SmbClient|https://metacpan.org/pod/Filesys::SmbClient#new-%hash>.

=back

=head4 Returns

Object

=head4 Description

Instantiiere eine Objekt der Klasse und liefere eine Referenz auf
dieses Objekt zurück.

=head4 Example

  my $smb = Quiq::Smb->new(
      username => 'elbrusfse',
      password => 'geheim',
      workgroup => 'ZEPPELIN_HV',
      debug => 0,
  );

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: %args 

    return $class->SUPER::new(
        smb => Filesys::SmbClient->new(@_),
    );
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 delete() - Lösche Datei von Server

=head4 Synopsis

  $smb->delete($file);

=head4 Arguments

=over 4

=item $file

(String) Pfad der Datei.

=back

=head4 Description

Lösche Datei $file von Server.

=cut

# -----------------------------------------------------------------------------

sub delete {
    my ($self,$file) = @_;

    my $smb = $self->{'smb'};

    my $ret = $smb->unlink($file);
    if (!$ret) {
        $self->throw(
            'SMB-00003: Delete failed',
            File=>qq|"$file"|,
            Error=>$!,
        );
    }
    
    return;
}

# -----------------------------------------------------------------------------

=head3 getData() - Hole Daten von Server

=head4 Synopsis

  $data = $smb->getData($file);

=head4 Arguments

=over 4

=item $file

(String) Dateiname.

=back

=head4 Returns

(String) Dateininhalt.

=head4 Description

Liefere den Inhalt der Datei $file.

=head4 Example

  $data = $smb->get('smb://ZBM-MOM-T/XRECHNUNG$/S-001191090X_Original.pdf');

=cut

# -----------------------------------------------------------------------------

sub getData {
    my ($self,$file) = @_;

    my $smb = $self->{'smb'};

    my $data;
    my $fd = $smb->open($file,'0666');
    if (!$fd) {
        $self->throw(
            'SMB-00002: Open for reading failed',
            Path=>qq|"$file"|,
            Error=>$!,
        );
    }
    while (1) {
        my $buf = $smb->read($fd);
        if (!$buf) {
            # eof
            last;
        }
        $data .= $buf;
    }
    $smb->close($fd);
    
    return $data;
}

# -----------------------------------------------------------------------------

=head3 ls() - Liste von Dateien in Server-Verzeichnis

=head4 Synopsis

  @arr|$arr = $sbm->ls($dir);

=head4 Arguments

=over 4

=item $dir

Verzeichnis

=back

=head4 Returns

(Array of Strings) Liste von Dateinamen. Im Skalarkontext eine Referenz
auf die Liste.

=head4 Description

Liefere die Liste der Dateien auf dem Server in Verzeichnis $dir.

=head4 Example

  @names = $smb->ls('smb://ZBM-MOM-T/XRECHNUNG$');

=cut

# -----------------------------------------------------------------------------

sub ls {
    my ($self,$path) = @_;

    my $smb = $self->{'smb'};

    my @arr;
    my $fd = $smb->opendir($path);
    if (!$fd) {
        $self->throw(
            'SMB-00001: ls failed',
            Path=>qq|"$path"|,
            Error=>$!,
        );
    }
    for ($smb->readdir($fd)) {
        if ($_ eq '.' || $_ eq '..') {
            next;
        }
        push @arr,$_;
    }
    $smb->closedir($fd);
    
    return wantarray? @arr: \@arr;
}

# -----------------------------------------------------------------------------

=head3 put() - Übertrage Datei auf Server

=head4 Synopsis

  $smb->put($from,$to);

=head4 Arguments

=over 4

=item $from

(String) Pfad der Quelldatei.

=item $to

(String) Pfad der Zieldatei

=back

=head4 Description

Kopiere Datei $from nach $to.

=head4 Example

  $smb->put('test.xls','smb://zeppelin.corp/zbm/Transfer/elbrusfse/test.xls');

=cut

# -----------------------------------------------------------------------------

sub put {
    my ($self,$from,$to) = @_;

    my $data = Quiq::Path->read($from);
    $self->putData($data,$to);
    
    return;
}

# -----------------------------------------------------------------------------

=head3 putData() - Übertrage Daten auf Server

=head4 Synopsis

  $smb->putData($data,$file);

=head4 Arguments

=over 4

=item $data

(String) Dateiinhalt.

=item $file

(String) Dateiname.

=back

=head4 Description

Schreibe Datei $file mit Inhalt $data.

=head4 Example

  $smb->putData($data,'smb://ZBM-MOM-T/XRECHNUNG$/S-001191090X_Original.pdf');

=cut

# -----------------------------------------------------------------------------

sub putData {
    my ($self,$data,$file) = @_;

    my $smb = $self->{'smb'};

    my $fd = $smb->open(">$file",'0666');
    if (!$fd) {
        $self->throw(
            'SMB-00002: Open for writing failed',
            Path=>qq|"$file"|,
            Error=>$!,
        );
    }
    my $ret = $smb->write($fd,$data);
    if (!$ret) {
        $self->throw(
            'SMB-00003: Write failed',
            Path=>qq|"$file"|,
            Error=>$!,
        );
    }
    $smb->close($fd);
    
    return;
}

# -----------------------------------------------------------------------------

=head3 rename() - Benenne Datei auf Server um

=head4 Synopsis

  $smb->rename($oldname,$newname);

=head4 Arguments

=over 4

=item $oldname

(String) Alter Dateiname.

=item $newname

(String) Neuer Dateiname.

=back

=head4 Description

Benenne Datei $oldname in $newname um.

=cut

# -----------------------------------------------------------------------------

sub rename {
    my ($self,$oldname,$newname) = @_;

    my $smb = $self->{'smb'};

    my $ret = $smb->rename($oldname,$newname);
    if (!$ret) {
        $self->throw(
            'SMB-00003: Rename failed',
            Path=>qq|"$oldname" => "$newname"|,
            Error=>$!,
        );
    }
    
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
