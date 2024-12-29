# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Debug - Hilfe beim Debuggen von Programmen

=head1 BASE CLASS

L<Quiq::Object>

=cut

# -----------------------------------------------------------------------------

package Quiq::Debug;
use base qw/Quiq::Object/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.223';

use Data::Printer color=>{string=>'black'};
use Data::Printer ();
use Quiq::Path;
use Quiq::Terminal;
use Quiq::Shell;

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Datenstrukturen

=head3 dump() - Liefere Datenstruktur in lesbarer Form

=head4 Synopsis

  $str = $this->dump($ref,@opt);

=head4 Arguments

=over 4

=item $ref

Referenz auf eine Datenstruktur.

=item @opt

Optionen der Funktion np() des Moduls Data::Printer. Dokumentation siehe
dort.

=back

=head4 Description

Liefere eine Perl-Datenstruktur beliebiger Tiefe in lesbarer Form
als Zeichenkette, so dass sie zu Debugzwecken ausgegeben werden kann.
Die Methode nutzt das Modul Data::Printer und davon die Funktion
np(). Die Optionen @opt werden an diese Funktion weiter geleitet.

=head4 Example

  Quiq::Debug->dump($obj,colored=>1);

=cut

# -----------------------------------------------------------------------------

sub dump {
    my ($this,$ref) = splice @_,0,2;
    return Data::Printer::np($ref,@_);
}

# -----------------------------------------------------------------------------

=head2 Module

=head3 modulePaths() - Pfade der geladenen Perl Moduldateien

=head4 Synopsis

  $str = $this->modulePaths;

=head4 Description

Liefere eine Aufstellung der Pfade der aktuell geladenen
Perl Moduldateien. Ein Modulpfad pro Zeile, alphabetisch sortiert.

=head4 Example

Die aktuell geladenen Moduldateien auf STDOUT ausgeben:

  print Quiq::Debug->modulePaths;
  ==>
  /home/fs/lib/perl5/Quiq/Debug.pm
  /home/fs/lib/perl5/Quiq/Object.pm
  /home/fs/lib/perl5/Perl/Quiq/Stacktrace.pm
  /usr/share/perl/5.20/base.pm
  /usr/share/perl/5.20/strict.pm
  /usr/share/perl/5.20/vars.pm
  /usr/share/perl/5.20/warnings.pm
  /usr/share/perl/5.20/warnings/register.pm

=cut

# -----------------------------------------------------------------------------

sub modulePaths {
    my $this = shift;
    return join("\n",sort values %INC)."\n";
}

# -----------------------------------------------------------------------------

=head2 Subroutines

=head3 findSubroutine() - Suche Subroutine

=head4 Synopsis

  @arr | $str = $this->findSubroutine($pattern);

=head4 Description

Suche die Subroutines, die den Pattern $pattern erfüllen, in den
Moduldateien (.pm) entlang der Pfade in @INC. Im Array-Kontext liefere die
Liste der Modulnamen, im Skalarkontext die Liste als Zeichenkette (ein
Modulpfad pro Zeile).

=head4 Example

B<ANPASSEN>

Die aktuell geladenen Moduldateien auf STDOUT ausgeben:

  print Quiq::Debug->findSubroutine;
  ==>
  /home/fs/lib/perl5/Quiq/Debug.pm
  /home/fs/lib/perl5/Quiq/Object.pm
  /home/fs/lib/perl5/Perl/Quiq/Stacktrace.pm
  /usr/share/perl/5.20/base.pm
  /usr/share/perl/5.20/strict.pm
  /usr/share/perl/5.20/vars.pm
  /usr/share/perl/5.20/warnings.pm
  /usr/share/perl/5.20/warnings/register.pm

=cut

# -----------------------------------------------------------------------------

sub findSubroutine {
    my ($this,$pattern) = @_;

    my $p = Quiq::Path->new;

    $pattern = qr/(sub\s+$pattern)/;

    my @modules;
    for my $dir (@INC) {
        if (!-d $dir) {
            next;
        }
        # say "*** $dir ***";
        my @files = $p->find($dir,-pattern=>qr/\.pm$/);
        for my $file (@files) {
            my $data = $p->read($file);
            if ($data =~ /$pattern/) {
                say "*** $file ***";
                while ($data =~ /$pattern/g) {
                    say $1;
                }
            }
        }
    }

    return;
}

# -----------------------------------------------------------------------------

=head2 Textvergleich

=head3 showDiff() - Zeige Differenz zwischen zwei Dateien

=head4 Synopsis

  $str = $this->showDiff($file1,$file2);

=head4 Description

Zeige die Differenz zwischen zwei Dateien. Die Anzeige wird auf die
Breite des Terminals eingestellt.

=head4 Example

  perl -MQuiq::Debug -E 'print Quiq::Debug->showDiff($file1,$file2)' | less

=cut

# -----------------------------------------------------------------------------

sub showDiff {
    my ($this,$file1,$file2) = @_;

    my $width = Quiq::Terminal->width;

    my $sh = Quiq::Shell->new;
    my $str = $sh->exec("diff -W $width -b -y $file1 $file2",
        -sloppy => 1,
        -capture => 'stdout',
    );

    return $str;
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.223

=head1 AUTHOR

Frank Seitz, L<http://fseitz.de/>

=head1 COPYRIGHT

Copyright (C) 2024 Frank Seitz

=head1 LICENSE

This code is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# -----------------------------------------------------------------------------

1;

# eof
