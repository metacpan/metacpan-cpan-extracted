package Quiq::Xml::LibXml;
use base qw/XML::LibXML/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.147';

use Encode ();

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Xml::LibXml - Funktionale Erweiterungen von XML::LibXML

=head1 BASE CLASS

XML::LibXML

=head1 DESCRIPTION

Dieses Modul lädt XML::LibXML und erweitert dessen Klassen
um zusätzliche Funktionalität.

=head1 METHODS

=head2 Erweiterung XML::LibXML::Document

=head3 lookup() - Finde Knoten

=head4 Synopsis

    $node = $doc->lookup($xpath);

=head4 Returns

Knoten

=cut

# -----------------------------------------------------------------------------

*XML::LibXML::Document::lookup = sub {
    my ($self,$xpath) = @_;

    my @nodes = $self->findnodes($xpath);
    if (!@nodes) {
        $self->throw;
    }
    if (@nodes > 1) {
        $self->throw;
    }

    return $nodes[0];
};

# -----------------------------------------------------------------------------

=head3 toFormattedString() - Formatiertes XML

=head4 Synopsis

    $str = $doc->toFormattedString;

=head4 Returns

Formatiertes XML (UTF-8 encoded String)

=head4 Description

Liefere das XML des Dokumentes in formatierter Darstellung. Im
Unterschied zur Methode $doc->toString()

=over 2

=item *

werden zunächst alle leeren Textknoten aus dem Dokument entfernt
(da bei "mixed content" die Methode toString() keine
Formatierung vornimmt)

=item *

wird der String UTF-8 encoded geliefert (was die Methode
toString() des Dokuments - im Gegensatz zu anderen Knoten
- nicht tut)

=back

=cut

# -----------------------------------------------------------------------------

*XML::LibXML::Document::toFormattedString = sub {
    my $self = shift;

    # Entferne alle leeren Text-Knoten

    for my $nod ($self->findnodes('//text()')) {
        if ($nod !~ /\S/) {
            $nod->unbindNode;
        }
    }

    return Encode::decode('utf-8',$self->toString(1));
};

# -----------------------------------------------------------------------------

=head2 Erweiterung XML::LibXML::Node

=head3 removeNode() - Entferne Knoten

=head4 Synopsis

    $nod->removeNode;

=head4 Returns

nichts

=head4 Description

Entferne den Knoten aus dem Dokument.

Dies ist ein Alias für die Methode $nod->unbindNode(), deren Name
ein wenig inkonsequent ist in Bezug auf $nod->removeChild(),
$nod->removeChildNodes().

=cut

# -----------------------------------------------------------------------------

*XML::LibXML::Node::removeNode = *XML::LibXML::Node::unbindNode;

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
