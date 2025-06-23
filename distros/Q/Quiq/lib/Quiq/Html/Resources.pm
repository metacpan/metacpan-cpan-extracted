# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Html::Resources - CSS- und JavaScript-Resourcen einer Webapplikation

=head1 BASE CLASS

L<Quiq::Hash>

=head1 DESCRIPTION

Ein Objekt der Klasse ist ein Speicher für die Definition von CSS- und
JavaScript-Ressourcen. Die Ressourcen werden unter einem Schlüssel
$key, z.B. 'jquery' oder 'jquery-ui', im Speicher abgelegt und
nach ihrem Typ (css, js) unterschieden.

=head1 EXAMPLE

  use Quiq::Html::Resources;
  
  # Instantiiere Objekt (hier am Beispiel der Resourcen 'jquery'
  # und 'jquery-ui')
  
  my $res = Quiq::Html::Resources->new(
      jquery => {
          js => [
              'https://code.jquery.com/jquery-latest.min.js',
          ],
      },
      'jquery-ui' => {
          css => [
              'https://code.jquery.com/ui/1.12.1/themes/base/jquery-ui.css',
          ],
          js => [
              'https://code.jquery.com/ui/1.12.1/jquery-ui.min.js',
          ],
      },
  );
  
  my @cssResources = $res->resources('jquery-ui','css');
  # ('https://code.jquery.com/ui/1.12.1/themes/base/jquery-ui.css')
  
  my @jsResources = $res->resources('jquery-ui','js');
  # ('https://code.jquery.com/ui/1.12.1/jquery-ui.css')

=cut

# -----------------------------------------------------------------------------

package Quiq::Html::Resources;
use base qw/Quiq::Hash/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Objekt

=head4 Synopsis

  $res = $class->new($key=>\%typeArr,...);

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

=head3 resources() - Liefere Liste von Ressourcen

=head4 Synopsis

  @arr | $arr = $res->resources(@keys);

=head4 Arguments

=over 4

=item @keys

Liste von Schlüsseln, z.B. 'jquery', 'datatables'.

=back

=head4 Description

Liefere die Liste der Ressourcen zu den Schlüsseln @keys.

=cut

# -----------------------------------------------------------------------------

sub resources {
    my $self = shift;
    # @_: @keys

    my @arr;
    for my $key (@_) {
        if (!exists $self->{$key}) {
            $self->throw(
                'RESOURCE-00001: Resource not defined',
                Resource => $key,
            );
        }
        for my $type ('css','js') {
            if (my $arr = $self->{$key}->{$type}) {
                push @arr,@$arr;
            }
        }
    }

    return wantarray? @arr: \@arr;
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
