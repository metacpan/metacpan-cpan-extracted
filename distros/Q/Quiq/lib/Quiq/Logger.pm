# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Logger - Schreiben von Logmeldungen

=head1 BASE CLASS

L<Quiq::Hash>

=cut

# -----------------------------------------------------------------------------

package Quiq::Logger;
use base qw/Quiq::Hash/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

use Quiq::String;
use Quiq::Path;
use POSIX ();
use Encode ();

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Objekt

=head4 Synopsis

  $log = $class->new($level,$file,$toTerm);

=head4 Arguments

=over 4

=item $level

(String) Loglevel: Es werden fünf Loglevel unterschieden: 'DEBUG', 'INFO',
'WARN', 'ERROR', 'FATAL'.

=item $file

(Pfad) Die Datei, in die die Meldungen gelogged werden.

=item $toTerm

(Bool) Ob die Meldungen außer in die Logdatei auch auf STDOUT ausgegeben
werden sollen.

=back

=head4 Returns

Logger-Objekt

=head4 Description

Instantiiere ein Objekt der Klasse und liefere dieses zurück.

=cut

# -----------------------------------------------------------------------------

my $Logger;

my %Level = (
    DEBUG => 1,
    INFO => 2,
    WARN => 3,
    ERROR => 4,
    FATAL => 5,
);

sub new {
    my ($class,$level,$file,$toTerm) = @_;

    $| = 1;

    return $Logger = $class->SUPER::new(
        level => $Level{$level},
        file => $file,
        toTerm => $toTerm,
    );
}

# -----------------------------------------------------------------------------

=head3 logger() - Liefere Logger-Objekt

=head4 Synopsis

  $log = $class->logger;

=head4 Returns

Logger-Objekt

=head4 Description

Ermittele das Logger-Objekt und liefere dieses zurück. Das Logger-Objekt
muss zuvor natürlich instantiiert worden sein.

=cut

# -----------------------------------------------------------------------------

sub logger {
    my $class = shift;
    return $Logger // $class->throw(
        'LOGGER-00099: Logger object not instantiated',
    );
}

# -----------------------------------------------------------------------------

=head2 Logmeldung auf Loglevel schreiben

=head3 debug() - Schreibe DEBUG Logmeldung

=head4 Synopsis

  $log->debug($msg);

=head4 Arguments

=over 4

=item $msg

(String) Logmeldung

=back

=head4 Description

Schreibe die Meldung $msg als DEBUG ins Log und - falls bei der
Instantiierung angegeben - nach STDOUT (Terminal).

=cut

# -----------------------------------------------------------------------------

sub debug {
    my ($self,$msg) = @_;
    $self->write('DEBUG',$msg);
}

# -----------------------------------------------------------------------------

=head3 info() - Schreibe INFO Logmeldung

=head4 Synopsis

  $log->info($msg);

=head4 Arguments

=over 4

=item $msg

(String) Logmeldung

=back

=head4 Description

Schreibe die Meldung $msg als INFO ins Log und - falls bei der
Instantiierung angegeben - nach STDOUT (Terminal).

=cut

# -----------------------------------------------------------------------------

sub info {
    my ($self,$msg) = @_;
    $self->write('INFO',$msg);
}

# -----------------------------------------------------------------------------

=head3 warn() - Schreibe WARN Logmeldung

=head4 Synopsis

  $log->warn($msg);

=head4 Arguments

=over 4

=item $msg

(String) Logmeldung

=back

=head4 Description

Schreibe die Meldung $msg als WARN ins Log und - falls bei der
Instantiierung angegeben - nach STDOUT (Terminal).

=cut

# -----------------------------------------------------------------------------

sub warn {
    my ($self,$msg) = @_;
    $self->write('WARN',$msg);
}

# -----------------------------------------------------------------------------

=head3 error() - Schreibe ERROR Logmeldung

=head4 Synopsis

  $log->error($msg);

=head4 Arguments

=over 4

=item $msg

(String) Logmeldung

=back

=head4 Description

Schreibe die Meldung $msg als ERROR ins Log und - falls bei der
Instantiierung angegeben - nach STDOUT (Terminal).

=cut

# -----------------------------------------------------------------------------

sub error {
    my ($self,$msg) = @_;
    $self->write('ERROR',$msg);
}

# -----------------------------------------------------------------------------

=head3 fatal() - Schreibe FATAL Logmeldung

=head4 Synopsis

  $log->fatal($msg);

=head4 Arguments

=over 4

=item $msg

(String) Logmeldung

=back

=head4 Description

Schreibe die Meldung $msg als FATAL ins Log und - falls bei der
Instantiierung angegeben - nach STDOUT (Terminal) B<und terminiere
die Ausführung des Programms>.

=cut

# -----------------------------------------------------------------------------

sub fatal {
    my ($self,$msg) = @_;
    $self->write('FATAL',$msg);
    exit 99;
}

# -----------------------------------------------------------------------------

=head2 Grundlegende Methoden

=head3 write() - Schreibe Logmeldung

=head4 Synopsis

  $log->write($level,$msg);

=head4 Arguments

=over 4

=item $level

Level der Logmeldung

=item $msg

(String) Logmeldung

=back

=head4 Description

Schreibe die Meldung $msg ins Log und - falls bei der Instantiierung
angegeben - nach STDOUT (Terminal).

=cut

# -----------------------------------------------------------------------------

sub write {
    my ($self,$level,$msg) = @_;

    if ($Level{$level} < $self->{'level'}) {
        return;
    }

    $msg = Quiq::String->unindent($msg);
    if ($msg =~ /\n/) { # mehrzeilige Meldung
        # $msg =~ s/^/| /mg;
        $msg = "\n$msg\n";
    }
    else {
        $msg = " $msg\n";
    }

    $msg = sprintf '%s %s %s%s',
        POSIX::strftime('%Y-%m-%d %H:%M:%S',localtime),$$,$level,$msg;

    if ($self->{'toTerm'}) {
        print $msg;
    }

    Quiq::Path->append($self->{'file'},Encode::encode('utf-8',$msg));

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
