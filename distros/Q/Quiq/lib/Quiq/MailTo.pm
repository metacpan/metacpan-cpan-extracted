# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::MailTo - Erzeuge mailto-URL

=head1 BASE CLASS

L<Quiq::Object>

=cut

# -----------------------------------------------------------------------------

package Quiq::MailTo;
use base qw/Quiq::Object/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

use Quiq::Parameters;
use Quiq::Url;

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Klassenmethoden

=head3 url() - Erzeuge mailto-URL

=head4 Synopsis

  $url = $class->url($to,@keyVal);

=head4 Arguments

=over 4

=item $to

Liste der direkten Empfänger.

=item @keyVal

Optionale URL-Eigenschaften:

=over 4

=item cc => $cc

Liste der Empfänger, die die Mail in Kopie erhalten.

=item bcc => $bcc

Liste der Empfänger, die die Mail als verdeckte Kopie erhalten.

=item subject => $subject

Betreff.

=item body => $text

Text.

=back

=back

=head4 Returns

(String) URL

=head4 Description

Erzeuge einen mailto-URL über den Schlüssel/Wert-Paaren @keyVal
und liefere diesen zurück.

=head4 Example

  Quiq::MailTo->url('fs@fseitz.de',subject=>'Ein Test');
  # =>
  mailto:fs@fseitz.de?subject=Ein%20Test

=cut

# -----------------------------------------------------------------------------

sub url {
    my ($class,$to) = splice @_,0,2;

    my ($cc,$bcc,$subject,$body);

    Quiq::Parameters->extractPropertiesToVariables(\@_,
        cc => \$cc,
        bcc => \$bcc,
        subject => \$subject,
        body => \$body,
    );

    my $u = Quiq::Url->new;

    my $url = 'mailto:'.$u->encode($to);
    my $query = Quiq::Url->queryEncode(
        cc => $cc,
        bcc => $bcc,
        subject => $subject,
        body => $body,
    );
    if ($query) {
        $url .= "?$query";
    }
    $url =~ s/%40/\@/g;

    return $url;
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
