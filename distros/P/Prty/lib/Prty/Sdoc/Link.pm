package Prty::Sdoc::Link;
use base qw/Prty::Sdoc::Node/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = 1.125;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Prty::Sdoc::Link - Definition eines Link

=head1 BASE CLASS

L<Prty::Sdoc::Node>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert die Definition eines Link.

=head1 ATTRIBUTES

=over 4

=item parent => $parent

Verweis auf Superknoten

=item name => $name

Name oder Namen des Link. Mehrere Namen werden mit | getrennt.

=item url => $url

Url des Link

=back

=head1 METHODS

=head2 Konstruktor

=head3 new() - Konstruktor

=head4 Synopsis

    $node = $class->new($doc,$parent,$att);

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$doc,$parent,$att) = @_;

    my $root = $parent->rootNode;
    my $linkH = $root->links;

    for my $name (split /\|/,{@$att}->{'name'}) {
        # Objekt instantiieren

        my $self = $class->SUPER::new(
            parent=>undef,
            type=>'Link',
            name=>undef,
            url=>undef,
        );
        $self->parent($root); # schwache Referenz
        $self->set(@$att);
        $self->set(name=>$name);
        $self->lockKeys;

        $linkH->set($name=>$self);
    }

    return;
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.125

=head1 AUTHOR

Frank Seitz, L<http://fseitz.de/>

=head1 COPYRIGHT

Copyright (C) 2018 Frank Seitz

=head1 LICENSE

This code is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# -----------------------------------------------------------------------------

1;

# eof
