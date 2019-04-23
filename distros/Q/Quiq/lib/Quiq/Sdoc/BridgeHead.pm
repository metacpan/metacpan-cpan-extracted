package Quiq::Sdoc::BridgeHead;
use base qw/Quiq::Sdoc::Node/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = 1.138;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Sdoc::BridgeHead - Zwischenüberschrift

=head1 BASE CLASS

L<Quiq::Sdoc::Node>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert eine Zwischenüberschrift.

=head1 ATTRIBUTES

=over 4

=item parent => $parent

Verweis auf Superknoten.

=item level => $n

Stufe der Zwischenüberschrift.

=item title => $str

Titel des Abschnitts.

=back

=head1 METHODS

=head2 Konstruktor

=head3 new() - Konstruktor

=head4 Synopsis

    $node = $class->new($doc,$parent);

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$doc,$parent) = @_;

    # Eine Zwischenüberschrift ist grundsätzlich einzeilig
    # und endet daher mit der nächsten Zeile.

    my $line = $doc->shiftLine;
    $line->text =~ /^(=+)\? (.*)/;
    my $level = length $1;
    my $title = $2;

    $title =~ s/^\s+//g;
    $title =~ s/\s+$//g;

    # Objekt instantiieren

    my $self = $class->SUPER::new(
        parent=>undef,
        type=>'BridgeHead',
        level=>$level,
        title=>$title,
    );
    $self->parent($parent); # schwache Referenz

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Methods

=head3 dump() - Erzeuge externe Repräsentation für Zwischenüberschrift-Knoten

=head4 Synopsis

    $str = $node->dump($format,@args);

=cut

# -----------------------------------------------------------------------------

sub dump {
    my $self = shift;
    my $format = shift;
    # @_: @args

    my $level = $self->{'level'};
    my $title = $self->{'title'};

    if ($format eq 'debug') {
        return qq(SECTION $level "$title");
    }
    elsif ($format =~ /^e?html$/) {
        my $h = shift;

        my $cssPrefix = $self->rootNode->get('cssPrefix');

        return $h->tag("h$level",
            class=>"$cssPrefix-bhead-h$level",
            $title
        );
    }
    elsif ($format eq 'pod') {
        return "=head$level $title\n\n";
    }
    elsif ($format eq 'man') {
        return "    $title\n\n";
    }
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.138

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
