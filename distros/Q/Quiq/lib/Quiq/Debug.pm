package Quiq::Debug;
use base qw/Quiq::Object/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.149';

use Data::Printer color=>{string=>'black'};
use Data::Printer ();

# -----------------------------------------------------------------------------

=head1 NAME

Quiq::Debug - Hilfe beim Debuggen von Programmen

=head1 BASE CLASS

L<Quiq::Object>

=head1 METHODS

=head2 Datenstruktur ausgeben

=head3 dump() - Liefere Datenstruktur in lesbarer Form

=head4 Synopsis

    $str = $this->dump($ref,@opt);

=head4 Description

Liefere eine Perl-Datenstruktur beliebiger Tiefe in lesbarer Form
als Zeichenkette, so dass sie zu Debugzwecken ausgegeben werden kann.
Die Methode nutzt das Modul Data::Printer und davon die Funktion
np(). Die Optionen @opt werden an diese Funktion weiter geleitet.

=head4 Example

    Quiq::Debug->dump($obj,colored=>1))

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

=head1 VERSION

1.149

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
