# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::PerlModule - Perl-Modul

=head1 BASE CLASS

L<Quiq::Hash>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert ein Perl-Modul im Dateisystem.
Hinsichtlich seiner Installation.

=cut

# -----------------------------------------------------------------------------

package Quiq::PerlModule;
use base qw/Quiq::Hash/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Objekt

=head4 Synopsis

  $mod = $class->new($name);

=head4 Description

Instantiiere Objekt für Perl-Modul $name und liefere eine Referenz
auf dieses Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$name) = @_;
    return bless \$name,$class;
}

# -----------------------------------------------------------------------------

=head2 Accessors

=head3 name() - Liefere Name des Moduls

=head4 Synopsis

  $name = $mod->name;

=head4 Example

  A::B::C

=cut

# -----------------------------------------------------------------------------

sub name {
    my $self = shift;
    return $$self;
}

# -----------------------------------------------------------------------------

=head2 Methods

=head3 isCore() - Teste, ob Core-Modul

=head4 Synopsis

  $bool = $mod->isCore;

=head4 Description

Liefere "wahr", wenn das Modul ein Core-Modul ist, andernfalls falsch.

Ein Perl-Modul ist ein Core-Modul, wenn es bei den Perl-Quellen
dabei ist, also mit dem Perl-Interpreter zusammen installiert wird.

=cut

# -----------------------------------------------------------------------------

sub isCore {
    my $self = shift;

    if ($] >= 5.010) { # 5.10 und neuer
        require Module::CoreList;
        no warnings 'once';
        return exists $Module::CoreList::version{$]+0}{$$self}? 1: 0;
    }

    require Config;
    my $corePath = $Config::Config{'installprivlib'} || die;

    my $modPath = $self->nameToPath;
    for my $incPath (@INC) {
        my $file = "$incPath/$modPath";
        if (-e $file) {
            return $file =~ /^\Q$corePath/? 1: 0;
        }
    }
    return 0;
}

# -----------------------------------------------------------------------------

=head3 isPragma() - Teste, ob Pragma

=head4 Synopsis

  $bool = $mod->isPragma;

=head4 Description

Liefere "wahr", wenn das Modul ein Pragma ist, andernfalls falsch.

Ein Perl-Modul ist ein Pragma, wenn sein Name keine
Großbuchstaben enthält.

=cut

# -----------------------------------------------------------------------------

sub isPragma {
    my $self = shift;
    return $$self !~ /[[:upper:]]/? 1: 0;
}

# -----------------------------------------------------------------------------

=head3 find() - Suche Modul im Dateisystem

=head4 Synopsis

  $path = $mod->find;

=head4 Description

Liefere den Pfad, unter dem das Modul geladen würde (mit use
oder require).

=head4 Example

  use A::B::C;
  print Quiq::PerlModule->new('A::B::C')->find;
  # '/usr/lib/perl5/site_perl/5.10.0/A/B/C.pm'

=cut

# -----------------------------------------------------------------------------

sub find {
    my $self = shift;

    my $modulePath = $self->nameToPath;
    for my $incPath (@INC) {
        my $path = "$incPath/$modulePath";
        if (-f $path) {
            return $path;
        }
    }

    $self->throw(
        'PERLMODULE-00002: Modul nicht gefunden',
        Module=>$$self,
    );
}

# -----------------------------------------------------------------------------

=head3 loadPath() - Liefere den Lade-Pfad

=head4 Synopsis

  $path = $mod->loadPath;

=head4 Description

Liefere den Pfad, unter dem das Modul geladen wurde (mit use
oder require).

Diese Methode ist nützlich, wenn einem nicht klar ist, aus
welchem Pfad heraus Perl ein Modul geladen hat, z.B. weil möglicherweise
mehrere Versionen des Moduls unter verschiedenen Pfaden installiert
sind.

Ohne Quiq::PerlModule kann dieselbe Information auf folgendem Weg herausgefunden
werden -  A::B::C sei das Modul:

  $INC{'A/B/C.pm'}

Existiert der Eintrag nicht, wurde das Modul nicht geladen.

=head4 Example

  use A::B::C;
  print Quiq::PerlModule->new('A::B::C')->loadPath;
  # '/usr/lib/perl5/site_perl/5.10.0/A/B/C.pm'

=cut

# -----------------------------------------------------------------------------

sub loadPath {
    my $self = shift;

    my $path = $self->nameToPath;
    if (!exists $INC{$path}) {
        $self->throw(
            'PERLMODULE-00001: Modul ist nicht geladen',
            Module=>$$self,
        );
    }

    return $INC{$path};
}

# -----------------------------------------------------------------------------

=head3 moduleDir() - Liefere den Pfad zum Modulverzeichnis

=head4 Synopsis

  $dir = $mod->moduleDir;

=head4 Description

Das Modulverzeichnis ist der Ladepfad des Moduls (s. loadPath())
ohne die Dateiendung C<.pm>.

=head4 Example

  use A::B::C;
  print Quiq::PerlModule->new('A::B::C')->moduleDir;
  # '/usr/lib/perl5/site_perl/5.10.0/A/B/C'

=cut

# -----------------------------------------------------------------------------

sub moduleDir {
    my $self = shift;

    my $dir = $self->loadPath;
    $dir =~ s/\.pm$//;

    return $dir;
}

# -----------------------------------------------------------------------------

=head3 nameToPath() - Liefere Modulpfad zum Modulnamen

=head4 Synopsis

  $path = $class->nameToPath($name); # Klassenmethode
  $path = $mod->nameToPath; # Objektmethode

=head4 Description

Wandele Modulname (wie er bei use angegeben wird) in Modulpfad
(wie er in %INC als Schlüssel vorkommt) um und liefere diesen zurück.

=head4 Example

  'A::B::C' => 'A/B/C.pm'

=cut

# -----------------------------------------------------------------------------

sub nameToPath {
    my $this = shift;
    # @_: $name

    my $str = ref $this? $$this: shift;
    $str =~ s|::|/|g;
    $str .= '.pm';

    return $str;
}

# -----------------------------------------------------------------------------

=head3 pathToName() - Liefere Modulname zum Modulpfad

=head4 Synopsis

  $name = $class->pathToName($path);

=head4 Description

Wandele Modulpfad (wie er in %INC als Schlüssel vorkommt) in Modulnamen
(wie er bei use angegeben wird) um und liefere diesen zurück.

=head4 Example

  'A/B/C.pm' ==> 'A::B::C'

=cut

# -----------------------------------------------------------------------------

sub pathToName {
    my ($class,$str) = @_;

    $str =~ s/\.pm$//;
    $str =~ s|/|::|g;

    return $str;
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
