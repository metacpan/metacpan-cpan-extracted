# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Css::Snippets - CSS-Code für die Seiten einer Web-Applikation

=head1 BASE CLASS

L<Quiq::Hash>

=head1 DESCRIPTION

Ein Objekt der Klasse ist ein Speicher für Gruppen von CSS-Definitionen,
die auf den Webseiten einer Applikation selektiv genutzt werden können.
Eine Gruppe ("Snippet") wird unter einem Schlüssel $key, z.B. 'page'
oder 'menubar' im Objekt gespeichert und kann über diesen abgefragt
werden.

=head1 EXAMPLE

  use Quiq::Css::Snippets;
  
  # Instantiiere Objekt (hier am Beispiel der der Gruppen 'page'
  # und 'menubar')
  
  my $sty = Quiq::Css::Snippets->new(
      page => q~
          body {
              font-family: sans-serif;
              font-size: 11pt;
          }
      ~,
      menubar => q~
          #menubar {
              font-size: 14pt;
          }
          #menubar li {
              padding-left: 18px;
              padding-right: 18px;
          }
      ~
  );
  
  my $cssCode = $sty->snippets('page','menuber');
  ==>
  body {
      font-family: sans-serif;
      font-size: 11pt;
  }
  #menubar {
      font-size: 14pt;
  }
  #menubar li {
      padding-left: 18px;
      padding-right: 18px;
  }

=cut

# -----------------------------------------------------------------------------

package Quiq::Css::Snippets;
use base qw/Quiq::Hash/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

use Quiq::Unindent;

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Objekt

=head4 Synopsis

  $sty = $class->new($key=>\%typeArr,...);

=head4 Description

Instantiiere ein Objekt der Klasse und liefere eine Referenz auf
dieses Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: $key=>\%typeArr,...
    return $class->SUPER::new({@_});
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 snippets() - Liefere Liste der CSS-Gruppen

=head4 Synopsis

  @arr | $arr = $res->snippets(@keys);

=head4 Arguments

=over 4

=item @keys

Liste von Schlüsseln, z.B. 'page', 'menubar'.

=back

=head4 Description

Liefere die Liste der Gruppen mit den Schlüsseln @keys.

=cut

# -----------------------------------------------------------------------------

sub snippets {
    my $self = shift;
    # @_: @keys

    my @arr;
    for my $key (@_) {
        if (!exists $self->{$key}) {
            $self->throw(
                'CSS-00001: Snippet not defined',
                Resource => $key,
            );
        }
        push @arr,Quiq::Unindent->string($self->{$key});
    }

    return wantarray? @arr: join('',@arr);
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
