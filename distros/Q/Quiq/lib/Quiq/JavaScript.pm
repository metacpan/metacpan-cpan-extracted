package Quiq::JavaScript;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.147';

use Quiq::Path;
use Scalar::Util ();

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::JavaScript - Generierung von JavaScript-Code

=head1 METHODS

=head2 Klassenmethoden

=head3 line() - Mache JavaScript-Code einzeilig

=head4 Synopsis

    $line = $class->line($code);

=head4 Arguments

=over 4

=item $code

Mehrzeiliger JavaScript-Code (String)

=back

=head4 Returns

JavaScript-Code einzeilig (String)

=head4 Description

Wandele mehrzeiligen JavaScript-Code in einzeiligen JavaScript-Code
und liefere diesen zurück. Die Methode ist nützlich, wenn formatierter,
mehrzeiliger JavaScript-Code in ein HTML Tag-Attribut (JavaScript-Handler
wie onclick="..." oder onchange="...") eingesetzt werden soll.

=head4 Example

Aus

    var s = '';
    for (var i = 0; i < 10; i++)
        s += 'x';

wird

    var s = ''; for (var i = 0; i < 10; i++) s += 'x';

=head4 Details

Die Regeln der Umwandlung:

=over 2

=item *

Leerzeilen und Zeilen nur aus Whitespace werden entfernt

=item *

Whitespace (einschl. Zeilenumbruch) am Anfang und am Ende
jeder Zeile wird entfernt

=item *

alle Zeilen werden mit einem Leerzeichen als Trenner konkateniert

=back

Damit dies sicher funktioniert, muss jede JavaScript-Anweisung
mit einem Semikolon am Zeilenende beendet werden und darf nicht,
wie JavaScipt es auch erlaubt, weggelassen werden.

=cut

# -----------------------------------------------------------------------------

sub line {
    my ($self,$code) = @_;

    my $line = '';
    open my $fh,'<',\$code or $self->throw;
    while (<$fh>) {
        s/^\s+//;
        s/\s+$//;
        next if $_ eq '';

        if ($line ne '') {
            $line .= ' ';
        }
        $line .= $_;
    }

    return $line;
}

# -----------------------------------------------------------------------------

=head3 script() - Generiere einen oder mehrere <script>-Tags

=head4 Synopsis

    $scriptTags = Quiq::JavaScript->script($h,@specs);

=head4 Arguments

=over 4

=item @specs

Liste von Script-Spezifikationen.

=back

=head4 Description

Übersetze die Code-Spezifikationen @specs in einen oder mehrere
Script-Tags.

Mögliche Code-Spezifikationen:

=over 4

=item "inline:$file":

Datei $file wird geladen und ihr Inhalt wird in einen Script-Tag
eingefasst.

=item $string (Zeichenkette mit runden Klammern oder Leerzeichen)

Zeichenkette $string wird in einen Script-Tag eingefasst.

=item $url (Zeichenkette ohne runde Klammern oder Leerzeichen):

Zeichenkette wird als URL interpretiert und in einen Script-Tag
mit src-Attribut übersetzt.

=item \@specs (Arrayreferenz):

Wird zu @specs expandiert.

=back

=head4 Examples

Code zum Laden einer JavaScript-Datei über URL:

    $script = Quiq::JavaScript->script($h,'https://host.dom/scr.js');
    =>
    <script src="https://host.dom/scr.js" type="text/javascript"></script>

Code aus Datei einfügen:

    $style = Quiq::JavaScript->script($h,'inline:js/script.css');
    =>
    <script type="text/javascript">
      ...
    </script>

Code direkt einfügen:

    $style = Quiq::JavaScript->script($h,q|
        ...
    |);
    =>
    <script type="text/javascript">
      ...
    </script>

Mehrere Code-Spezifikationen:

    $style = Quiq::JavaScript->script(
        '...'
        '...'
    );

Mehrere Code-Spezifikationen via Arrayreferenz:

    $style = Quiq::JavaScript->script(
        ['...','...']
    );

Dies ist nützlich, wenn die Spezifikation von einem Parameter
einer umgebenden Methode kommt.

=cut

# -----------------------------------------------------------------------------

sub script {
    my $this = shift;
    my $h = shift;
    # @_: @spec

    my $scriptTags = '';

    while (@_) {
        my $spec = shift;

        if (!defined $spec || $spec eq '') {
            next;
        }

        my $type = Scalar::Util::reftype($spec);
        if ($type && $type eq 'ARRAY') {
            unshift @_,@$spec;
            next;
        }

        if ($spec =~ s/^inline://) {
            my $data = Quiq::Path->read($spec);

            # "// eof" und Leerzeichen am Ende entfernen

            $data =~ s|\s+$||;
            $data =~ s|\s*// eof$||;

            $scriptTags .= $h->tag('script',
                $data
            );
        }
        elsif ($spec =~ /[\s\(]/) {
            # Javascript-Code, wenn Whitespace oder Klammer enthalten
            $scriptTags .= $h->tag('script',
                $spec
            );       
        }
        else {
            # sonst URL
            $scriptTags .= $h->tag('script',
                type => 'text/javascript',
                src => $spec,
            );
        }
    }

    return $scriptTags;
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.147

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
