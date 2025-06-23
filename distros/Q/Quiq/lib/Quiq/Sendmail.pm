# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Sendmail - Versende Mail mit sendmail

=head1 BASE CLASS

L<Quiq::Object>

=head1 SYNOPSIS

  use Quiq::Sendmail;
  
  Quiq::Sendmail->send($to,$subject,$body,
      -contentType => 'text/html; charset=utf-8',
  );

=cut

# -----------------------------------------------------------------------------

package Quiq::Sendmail;
use base qw/Quiq::Object/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

use Quiq::FileHandle;
use Encode ();

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Objekt

=head4 Synopsis

  $s = $class->new;

=head4 Returns

Objekt

=head4 Description

Instantiiere ein Objekt der Klasse und liefere eine Referenz auf
dieses Objekt zurück. Da die Klasse ausschließlich Klassenmethoden
enthält, hat das Objekt ausschließlich die Funktion, eine abkürzende
Aufrufschreibweise für diese Methoden zu ermöglichen.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    return bless \(my $dummy),$class;
}

# -----------------------------------------------------------------------------

=head2 Klassenmethoden

=head3 send() - Versende Mail

=head4 Synopsis

  $this->send($to,$subject,$body,@opt);

=head4 Arguments

=over 4

=item $to

Empfänger der E-Mail.

=item $subject

Betreff der E-Mail.

=item $body

Inhalt der E-Mail.

=back

=head4 Options

=over 4

=item -contentType => $contentType (Default: 'text/plain')

Content-Type von $subject und $body. Wenn leer, wird
kein Content-Type-Header gesetzt.

=item -encoding => $charset (Default: 'utf-8')

Encoding von $subject und $body. Wenn leer, wird vor dem Senden
encode() nicht auf $subject und $body angewendet.

=item -from => $address

Absender, z.B. 'Frank Seitz <fs@fseitz.de>'.

=item -replyTo => $address

Reply-To Adresse.

=back

=head4 Description

Versende eine E-Mail an Empfänger $to mit dem Betreff $subject und
dem Inhalt $body.

=cut

# -----------------------------------------------------------------------------

sub send {
    my ($this,$to,$subject,$body) = splice @_,0,4;

    # Optionen

    my $contentType = 'text/plain';
    my $encoding = 'utf-8';
    my $from = undef;
    my $replyTo = undef;

    my $optA = $this->parameters(\@_,
        -contentType => \$contentType,
        -encoding => \$encoding,
        -from => $from,
        -replyTo => \$replyTo,
    );
    
    # Operation ausführen

    if ($encoding) {
        $subject = Encode::encode($encoding,$subject);
        $body = Encode::encode($encoding,$body);
    }

    my $fh = Quiq::FileHandle->new('|-','/usr/sbin/sendmail -t');
    if ($from) {
        $fh->print("From: $from\n");
    }
    $fh->print("To: $to\n");
    if ($replyTo) {
        $fh->print("Reply-To: $replyTo\n");
    }
    $fh->print("Subject: $subject\n");
    if ($contentType) {
        if ($encoding) {
            $contentType .= "; charset=$encoding";
        }
        $fh->print("Content-Type: $contentType\n\n");
    }
    $fh->print($body);
    $fh->close;

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
