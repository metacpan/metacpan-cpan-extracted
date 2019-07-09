package Quiq::TempFile;
use base qw/Quiq::Object/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.151';

use overload '""' => sub {${$_[0]}}, 'cmp' => sub{${$_[0]} cmp $_[1]};
use Quiq::Path;
use File::Temp ();

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

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Objekt

=head4 Synopsis

    $file = $class->new(@opt);

=head4 Options

=over 4

=item -dir => $dir (Default: '/tmp')

Verzeichnis, in dem die temporäre Datei erzeugt wird.

=item -suffix => $suffix

Dateienendung, z.B. '.dat'.

=item -template => $template

Dateinamen-Template, z.B. 'tmpfileXXXXX'.

=item -unlink => $bool (Default: 1)

Lösche die Datei, wenn das Objekt aus den Skope geht.

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

    # Wir setzen unsere Optionen in die Optionen von File::Temp um

    my @args;
    while (@_) {
        my $opt = shift;
        if ($opt eq '-dir') {
            substr($opt,0,1) = '';
            push @args,uc($opt),Quiq::Path->expandTilde(shift);
        }
        elsif ($opt =~ /^(-suffix|-template|-unlink)$/) {
            substr($opt,0,1) = '';
            push @args,uc($opt),shift;
        }
        else {
            $class->throw(
                'TEMPFILE-00001: Unknown option',
                Option => $_[0],
            )
        }
    }

    return bless \File::Temp->new(@args),$class;
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.151

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
