package Quiq::Rsync;
use base qw/Quiq::Object/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.149';

use Quiq::Option;
use File::Rsync ();

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Rsync - Aufruf von rsync von Perl aus

=head1 BASE CLASS

L<Quiq::Object>

=head1 SYNOPSIS

    use Quiq::Rsync;
    
    # /src/dir => /dest/dir (gleicher Verzeichnisname)
    
    Quiq::Rsync->exec('/src/dir','/dest');
    Quiq::Rsync->exec('/src/dir/','/dest/dir');
    
    # /src/dir1 => /dest/dir2 (unterschiedlicher Verzeichnisname)
    Quiq::Rsync->exec('/src/dir1/','/dest/dir2');
    
    # Änderungen anzeigen, aber nicht durchführen
    Quiq::Rsync->exec($src,$dest,-dryRun=>1);

=head1 DESCRIPTION

Führe rsync(1) unter Kontrolle von Perl aus. Die Klasse stützt sich
auf die Klasse File::Rsync ab und stellt gegenüber dieser eine
spezialisierte, einfachere Schnittstelle zur Verfügung.
Eigenschaften:

=over 2

=item *

der Aufruf von exec() ohne Optionen entspricht der
"Standard-Nutzung" von rsync

=item *

im Fehlerfall wird eine Exception geworfen

=item *

eine Ausgabe findet nur im Fehlerfall und bei Änderungen statt,
die statistische Ausgabe von rsync unterbleibt

=back

=head1 METHODS

=head2 Klassenmethoden

=head3 exec() - Führe rsync-Kommando aus

=head4 Synopsis

    $class->exec($src,$dest,@opt);

=head4 Arguments

=over 4

=item $src

Quell-Pfad

=item $dest

Ziel-Pfad

=back

=head4 Options

=over 4

=item -dryRun => $bool

Füge die Option --dry-run zur Kommandozeile hinzu, d.h. das
rsync-Kommando wird ausgeführt, ohne dass Änderungen vorgenommen
werden.

=back

=head4 Returns

nichts

=head4 Description

Führe rsync(1) für Quellpfad $src und Zielpfad $dest aus.
Ohne Angabe von Optionen wird als Kommandozeile ausgeführt:

    rsync --archive --verbose --delete SRC DEST

D.h. $src und $dest werden als Verzeichnisse angesehen, wobei
Verzeichnis $dest auf exakt den gleichen Stand wie $src gebracht wird.

Schlägt das Kommando fehl, wird eine Exception geworfen.

Die Ausgabe des rsync-Kommandos wird nach STDOUT geschrieben,
wobei einige Zeilen entfernt werden, so dass eine Ausgabe nur
dann erscheint, wenn Änderungen durchgeführt wurden, d.h. die
Zeilen über und unter PROTOKOLL werden entfernt:

    sending incremental file list
    PROTOKOLL
    sent X bytes  received X bytes  X.00 bytes/sec
    total size is X speedup is X.X

Im Dry-Run-Modus wird am Ende (DRY RUN) angezeigt.

=cut

# -----------------------------------------------------------------------------

sub exec {
    my ($class,$src,$dest) = splice @_,0,3;
    # @opt

    my $dryRun = 0;

    Quiq::Option->extract(\@_,
        -dryRun => \$dryRun,
    );

    my $rsy = File::Rsync->new(
        -archive => 1,
        -verbose => 1,
        -delete => 1,
        -dry_run => $dryRun,
        src => $src,
        dest => $dest,
    );

    if (!$rsy->exec) {
        my $errA = $rsy->err;
        $class->throw(
            'RSYNC-00001: Command failed',
            # Cmd => $rsy->cmd,
            Stderr => $errA? join('',@$errA): undef,
        );
    }
    else {
        # Liefere die Ausgabe, die das rsync-Kommando nach stdout
        # geschrieben hat, wobei die Zeilen über und unter PROTOKOLL
        # entfernt werden:
        #
        #     sending incremental file list
        #     PROTOKOLL
        #     sent X bytes  received X bytes  X.00 bytes/sec
        #     total size is X speedup is X.X
        #
        # Im Dry-Run-Modus wird am Ende (DRY RUN) angezeigt.
    
        my @arr = $rsy->out;
        if ($arr[0] =~ /^sending/) {
            shift @arr;
        }
        if ($arr[-3] =~ /^$/) {
            splice @arr,-3,1;
        }
        if ($arr[-2] =~ /^sent/) {
            splice @arr,-2,1;
        }
        if ($arr[-1] =~ /^total/) {
            if ($arr[-1] =~ /DRY RUN/) {
                $arr[-1] = "(DRY RUN)\n";
            }
            else {
                pop @arr;
            }
        }
        if (@arr) {
            my $host = $dest;
            $host =~ s/:.*//;
            $host =~ s/.*\@//;
            print "==$host==\n";
        } 
        print join '',@arr;
    }
        
    return;
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
