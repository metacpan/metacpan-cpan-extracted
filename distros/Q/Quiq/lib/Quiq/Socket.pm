package Quiq::Socket;
use base qw/IO::Socket::INET Quiq::Object/;

use strict;
use warnings;
use v5.10.0;
use utf8;

our $VERSION = '1.149';

use Quiq::Option;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Socket - TCP-Verbindung zu einem Server

=head1 BASE CLASSES

=over 2

=item *

IO::Socket::INET

=item *

L<Quiq::Object>

=back

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert eine TCP-Verbindung zu einem Server.
Der Verbindungsaufbau erfolgt mit der Instantiierung des Objekts.

Die Klasse ist abgeleitet von IO::Socket::INET und besitzt folglich
alle Methoden dieser Klasse.

=head1 EXAMPLE

Sende GET-Request an Google und gib die Antwort aus:

    my $sock = Quiq::Socket->new('google.com',80);
    print $sock "GET /\n";
    while (<$sock>) {
        print;
    }

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Socket

=head4 Synopsis

    $sock = $class->new($host,$port,@opt);

=head4 Options

=over 4

=item -sloppy => $bool (Default: 0)

Wirf keine Exception, wenn der Verbindungsaufbau fehlschlägt, sondern
liefere C<undef>.

=back

=head4 Description

Baue eine TCP-Verbindung zu Host $host und Port $port auf
und liefere eine Referenz auf das Socket-Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    my $host = shift;
    my $port = shift;
    # @_: @opt

    # Optionen

    my $sloppy = 0;
    Quiq::Option->extract(\@_,
        -sloppy => \$sloppy,
    );

    # Baue Verbindung auf

    my $self = $class->SUPER::new("$host:$port");
    if (!$self && !$sloppy) {
        $class->throw(
            'SOCK-00001: Verbindungsaufbau fehlgeschlagen',
            Host => $host,
            Port => $port,
        );
    }

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 slurp() - Lies alle Daten

=head4 Synopsis

    $data = $sock->slurp;

=head4 Description

Lies alle Daten bis der Socket geschlossen wird. Die Methode ist
nützlich, um eine HTTP-Antwort zu lesen.

=cut

# -----------------------------------------------------------------------------

sub slurp {
    my $self = shift;
    local $/;
    return <$self>;
}

# -----------------------------------------------------------------------------

=head3 close() - Schließe Socket

=head4 Synopsis

    $sock->close;

=cut

# -----------------------------------------------------------------------------

sub close {
    my $self = shift;

    CORE::close $self or do {
        $self->throw('SOCK-00002: Socket schließen fehlgeschlagen');
    };

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
