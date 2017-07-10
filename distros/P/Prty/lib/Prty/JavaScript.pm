package Prty::JavaScript;

use strict;
use warnings;

our $VERSION = 1.117;

use Prty::Path;
use Scalar::Util ();

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Prty::JavaScript - Generierung von JavaScript-Code

=head1 METHODS

=head2 Klassenmethoden

=head3 script() - Generiere einen oder mehrere <script>-Tags

=head4 Synopsis

    $scriptTags = Prty::JavaScript->script($h,@specs);

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

=head4 Arguments

=over 4

=item @specs

Liste von Script-Spezifikationen.

=back

=head4 Examples

Code zum Laden einer JavaScript-Datei über URL:

    $script = Prty::JavaScript->script($h,'https://host.dom/scr.js');
    =>
    <script src="https://host.dom/scr.js" type="text/javascript"></script>

Code aus Datei einfügen:

    $style = Prty::JavaScript->script($h,'inline:js/script.css');
    =>
    <script type="text/javascript">
      ...
    </script>

Code direkt einfügen:

    $style = Prty::JavaScript->script($h,q|
        ...
    |);
    =>
    <script type="text/javascript">
      ...
    </script>

Mehrere Code-Spezifikationen:

    $style = Prty::JavaScript->script(
        '...'
        '...'
    );

Mehrere Code-Spezifikationen via Arrayreferenz:

    $style = Prty::JavaScript->script(
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
            my $data = Prty::Path->read($spec);

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
                type=>'text/javascript',
                src=>$spec,
            );
        }
    }

    return $scriptTags;
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.117

=head1 AUTHOR

Frank Seitz, L<http://fseitz.de/>

=head1 COPYRIGHT

Copyright (C) 2017 Frank Seitz

=head1 LICENSE

This code is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# -----------------------------------------------------------------------------

1;

# eof
