# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Sftp::Client - SFTP Client

=head1 BASE CLASS

L<Quiq::Hash>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert einen SFTP-Client. Die Klasse
realisiert ihre Funktionalität unter Rückgriff auf
L<Net::SFTP::Foreign|https://metacpan.org/pod/Net::SFTP::Foreign>,
allerdings nicht durch Ableitung, sondern durch Einbettung.
Die Klasse zeichnet sich dadurch aus, dass sie

=over 2

=item *

Fehler nicht über Returnwerte anzeigt, sondern im Fehlerfall
eine Exception wirft (allerdings schreibt Net::SFTP::Foreign
zusätzlich Meldungen nach STDERR, siehe
L<Net::SFTP::Foreign#stderr_fh|https://metacpan.org/pod/Net::SFTP::Foreign#stderr_fh-=%3E-$fh>
um dies ggf. zu verbessern)

=back

=cut

# -----------------------------------------------------------------------------

package Quiq::Sftp::Client;
use base qw/Quiq::Hash/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

use Net::SFTP::Foreign ();
use File::Temp ();
use File::Slurp ();

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Objekt

=head4 Synopsis

  $ftp = $class->new(%args);

=head4 Arguments

=over 4

=item %args

Siehe L<Net::SFTP::Foreign|https://metacpan.org/pod/Net::SFTP::Foreign#Net::SFTP::Foreign-%3Enew(%args)>.

=back

=head4 Returns

Object

=head4 Description

Instantiiere eine Objekt der Klasse und liefere eine Referenz auf
dieses Objekt zurück.

=head4 Example

  my $smb = Quiq::Sftp->new(
      user => 'fs',
      password => 'geheim',
      host => 'ftp.fseitz.de',
  );

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: %args 

    my $sftp = eval {Net::SFTP::Foreign->new(
        autodie => 1,
        @_,
    )};
    if ($@) {
        $@ =~ s/ at .*//;
        $class->throw("new - $@");
    }

    return $class->SUPER::new(
        sftp => $sftp,
    );
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 cd() - Wechsele Server-Verzeichnis

=head4 Synopsis

  $sftp->cd($dir);

=head4 Arguments

=over 4

=item $dir

(String) Verzeichnis-Pfad.

=back

=head4 Description

Wechsele auf dem Server in Verzeichnis $dir.

=cut

# -----------------------------------------------------------------------------

sub cd {
    my ($self,$dir) = @_;

    my $sftp = $self->{'sftp'};
    eval {$sftp->setcwd($dir)};
    if ($@) {
        $@ =~ s/ at .*//;
        $self->throw("cd - $@");
    }

    return;
}

# -----------------------------------------------------------------------------

=head3 delete() - Lösche Datei auf Server

=head4 Synopsis

  $sftp->delete($file);

=head4 Alias

remove()

=head4 Arguments

=over 4

=item $file

(String) Datei-Pfad.

=back

=head4 Description

Lösche die Datei $file auf dem Server.

=cut

# -----------------------------------------------------------------------------

sub delete {
    my ($self,$file) = @_;

    my $sftp = $self->{'sftp'};
    eval {$sftp->remove($file)};
    if ($@) {
        $@ =~ s/ at .*//;
        $self->throw("delete - $@");
    }

    return;
}

{
    no warnings 'once';
    *remove = \&delete;
}

# -----------------------------------------------------------------------------

=head3 get() - Hole Datei von Server

=head4 Synopsis

  $sftp->get($remote,%opts);
  $sftp->get($remote,$local,%opts);

=head4 Arguments

=over 4

=item $remote

(String) Pfad der entfernten Datei.

=item $local

(String) Pfad der lokalen Datei.

=back

=head4 Options

=over 4

=item %opts

Siehe L<Net::SFTP::Foreign|https://metacpan.org/pod/Net::SFTP::Foreign#$sftp->get($remote,-$local,-%options)>.

=back

=head4 Description

Hole Datei $remote vom Server und speichere sie unter dem
Pfad $local.

=cut

# -----------------------------------------------------------------------------

sub get {
    my $self = shift;
    # @_: $remote,%opts -or- $remote,$local,%opts

    if (@_%2) {
        my $local = $_[0];
        $local =~ s|.*/||;
        splice @_,1,0,$local;
    }

    my $sftp = $self->{'sftp'};
    eval {$sftp->get(@_)};
    if ($@) {
        $@ =~ s/ at .*//;
        $self->throw("get - $@");
    }

    return;
}

# -----------------------------------------------------------------------------

=head3 getData() - Hole Daten von Server

=head4 Synopsis

  $data = $sftp->getData($remote,%opts);

=head4 Arguments

=over 4

=item $remote

(String) Pfad der entfernten Datei.

=back

=head4 Options

=over 4

=item %opts

Siehe L<Net::SFTP::Foreign|https://metacpan.org/pod/Net::SFTP::Foreign#$sftp->put($local,-$remote,-%opts)>.

=back

=head4 Description

Hole die Datei $remote vom Server und liefere dessen Inhalt zurück.

=cut

# -----------------------------------------------------------------------------

sub getData {
    my ($self,$remote) = splice @_,0,2;
    # @_: %opts

    my $sftp = $self->{'sftp'};
    my $data = eval {
        my $fh = File::Temp->new;
        my $tmpFile = $fh->filename;
        $sftp->get($remote,$tmpFile,@_);
        my $data = File::Slurp::read_file($tmpFile);
        close $fh; # temporäre Datei wird gelöscht
        return $data;
    };
    if ($@) {
        $@ =~ s/ at .*//;
        $self->throw("putData - $@");
    }

    return $data;
}

# -----------------------------------------------------------------------------

=head3 ls() - Liste von Dateien in Server-Verzeichnis

=head4 Synopsis

  @arr|$arr = $sftp->ls(%opts);
  @arr|$arr = $sftp->ls($path,%opts);

=head4 Arguments

=over 4

=item $path

(String) Verzeichnis-Pfad.

=back

=head4 Options

=over 4

=item %opts

Siehe L<Net::SFTP::Foreign|https://metacpan.org/pod/Net::SFTP::Foreign#$sftp->ls($remote,-%opts)>.

=back

=head4 Returns

(Array of Strings) Liste von Datei- oder Verzeichnisnamen.
Im Skalarkontext eine Referenz auf die Liste.

=head4 Description

Liefere die Liste der Dateien unter dem Remote-Pfad $path.

=cut

# -----------------------------------------------------------------------------

sub ls {
    my $self = shift;
    # @_: %opts -or- $path,%opts

    my $sftp = $self->{'sftp'};
    my @arr = eval {@{$sftp->ls(@_,names_only=>1)}};
    if ($@) {
        $@ =~ s/ at .*//;
        $self->throw("ls - $@");
    }

    return wantarray? @arr: \@arr;
}

# -----------------------------------------------------------------------------

=head3 put() - Übertrage Datei auf Server

=head4 Synopsis

  $sftp->put($local,%opts);
  $sftp->put($local,$remote,%opts);

=head4 Arguments

=over 4

=item $local

(String) Pfad der lokalen Datei.

=item $remote

(String) Pfad der entfernten Datei.

=back

=head4 Options

=over 4

=item %opts

Siehe L<Net::SFTP::Foreign|https://metacpan.org/pod/Net::SFTP::Foreign#$sftp->put($local,-$remote,-%opts)>.

=back

=head4 Description

Übertrage Datei $lokal auf den Server und speichere sie unter dem
Pfad $remote.

=cut

# -----------------------------------------------------------------------------

sub put {
    my $self = shift;
    # @_: $local,%opts -or- $local,$remote,%opts

    if (@_%2) {
        my $remote = $_[0];
        $remote =~ s|.*/||;
        splice @_,1,0,$remote;
    }

    my $sftp = $self->{'sftp'};
    eval {$sftp->put(@_)};
    if ($@) {
        $@ =~ s/ at .*//;
        $self->throw("put - $@");
    }

    return;
}

# -----------------------------------------------------------------------------

=head3 putData() - Übertrage Daten auf Server

=head4 Synopsis

  $sftp->putData($data,$remote,%opts);

=head4 Arguments

=over 4

=item $data

(String) Daten, die übertragen werden sollen

=item $remote

(String) Pfad der entfernten Datei.

=back

=head4 Options

=over 4

=item %opts

Siehe L<Net::SFTP::Foreign|https://metacpan.org/pod/Net::SFTP::Foreign#$sftp->put($local,-$remote,-%opts)>.

=back

=head4 Description

Übertrage Daten $data auf den Server und speichere sie unter dem
Pfad $remote.

=cut

# -----------------------------------------------------------------------------

sub putData {
    my ($self,$data,$remote) = splice @_,0,3;
    # @_: %opts

    my $sftp = $self->{'sftp'};
    eval {
        my $fh = File::Temp->new;
        my $tmpFile = $fh->filename;
        syswrite($fh,$data) // die "syswrite failed\n";
        $sftp->put($tmpFile,$remote,@_);
        close $fh; # temporäre Datei wird gelöscht
    };
    if ($@) {
        $@ =~ s/ at .*//;
        $self->throw("putData - $@");
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
