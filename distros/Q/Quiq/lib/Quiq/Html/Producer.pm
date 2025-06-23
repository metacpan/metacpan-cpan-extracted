# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Html::Producer - Generierung von HTML-Code

=head1 BASE CLASS

L<Quiq::Html::Construct>

=head1 DESCRIPTION

Die Klasse vereinigt die Funktionalität der Klassen Quiq::Html::Tag
und Quiq::Html::Construct und erlaubt somit die Generierung von
einzelnen HTML-Tags und einfachen Tag-Konstrukten. Sie
implementiert keine eigene Funktionalität, sondern erbt diese von
ihren Basisklassen. Der Konstruktor ist in der Basisklasse
Quiq::Html::Tag implementiert.

Vererbungshierarchie:

  Quiq::Html::Tag        (einzelne HTML-Tags)
      |
  Quiq::Html::Construct  (einfache Konstrukte aus HTML-Tags)
      |
  Quiq::Html::Producer   (vereinigte Funktionalität)

Einfacher Anwendungsfall:

  my $h = Quiq::Html::Producer->new;
  print Quiq::Html::Page->html($h,
      ...
  );

=cut

# -----------------------------------------------------------------------------

package Quiq::Html::Producer;
use base qw/Quiq::Html::Construct/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

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
