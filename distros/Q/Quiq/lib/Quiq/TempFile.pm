# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::TempFile - Temporäre Datei

=head1 BASE CLASS

L<Quiq::Object>

=head1 DESCRIPTION

Der Konstruktor der Klasse erzeugt eine temporäre Datei.
Geht die letzte Objekt-Referenz aus dem Scope, wird die Datei
automatisch gelöscht. Das Datei-Objekt stringifiziert sich
im String-Kontext automatisch zum Datei-Pfad.

=cut

# -----------------------------------------------------------------------------

package Quiq::TempFile;
use base qw/Quiq::Object/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

use overload '""' => sub {${$_[0]}}, 'cmp' => sub{${$_[0]} cmp $_[1]};
use Quiq::Path;
use File::Temp ();

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Objekt

=head4 Synopsis

  $file = $class->new(@opt);
  $file = $class->new($data,@opt);

=head4 Arguments

=over 4

=item $data

Daten, die in die temporäre Datei geschrieben werden.

=back

=head4 Options

=over 4

=item -dir => $dir (Default: '/tmp')

Verzeichnis, in dem die temporäre Datei erzeugt wird.

=item -pathOnly => $bool

Erzeuge nur den Pfad, lösche die Datei sofort.

=item -suffix => $suffix

Dateienendung, z.B. '.dat'.

=item -template => $template

Dateinamen-Template, z.B. 'tmpfileXXXXX'.

=item -unlink => $bool (Default: 1)

Lösche die Datei, wenn das Objekt aus dem Scope geht.

=back

=head4 Returns

Tempdatei-Objekt

=head4 Description

Instantiiere ein Objekt der Klasse und liefere eine Referenz auf
dieses Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: @opt

    # Optionen und Argumente

    my ($dir,$pathOnly,$suffix,$template,$unlink);

    my $argA = $class->parameters(0,1,\@_,
        -dir => \$dir,
        -pathOnly => \$pathOnly,
        -suffix => \$suffix,
        -template => \$template,
        -unlink => \$unlink,
    );
    my $data = shift @$argA;

    # Wir setzen unsere Optionen in die Optionen von File::Temp um

    my @args;
    if (defined $dir) {
        $dir = Quiq::Path->expandTilde($dir);
        push @args,'DIR',$dir;
    }
    if (defined $suffix) {
        push @args,'SUFFIX',$suffix;
    }
    if (defined $template) {
        push @args,'TEMPLATE',$template;
    }
    if (defined $unlink) {
        push @args,'UNLINK',$unlink;
    }

    my $self = bless \File::Temp->new(@args),$class;
    if (defined $data) {
        Quiq::Path->write($self,$data);
    }
    if ($pathOnly) {
        Quiq::Path->delete("$self");
    }

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
