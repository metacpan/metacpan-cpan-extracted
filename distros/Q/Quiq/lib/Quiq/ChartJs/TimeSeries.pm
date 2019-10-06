package Quiq::ChartJs::TimeSeries;
use base qw/Quiq::Hash/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.159';

use Quiq::Unindent;
use Quiq::Template;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::ChartJs::TimeSeries - Zeitreihen-Plot via Chart.js

=head1 BASE CLASS

L<Quiq::Hash>

=head1 DESCRIPTION

Erzeuge einen Zeitreihen-Plot via Chart.js.

=head1 SEE ALSO

=over 2

=item *

L<https://www.chartjs.org>

=back

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Objekt

=head4 Synopsis

  $ch = $class->new($name,@attVal);

=head4 Attributes

=over 4

=item name

Name der Chart-Instanz. Der Name wird als CSS-Id für die Zeichenfläche
(Canvas) und als Variablenname für die Instanz verwendet.

=back

=head4 Returns

Objekt

=head4 Description

Instantiiere ein Objekt der Klasse und liefere eine Referenz auf
dieses Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$name) = splice @_,0,2;
    # @_: @attVal

    my $self = $class->SUPER::new(
        name => $name,
    );
    $self->set(@_);

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 javaScript() - JavaScript-Code

=head4 Synopsis

  $ch = $ch->javaScript;

=head4 Returns

JavaScript-Code (String)

=head4 Description

Liefere den JavaScript-Code der Chart-Instanz.

=cut

# -----------------------------------------------------------------------------

sub javaScript {
    my $self = shift;

    my $template = Quiq::Unindent->string(q~
        var __NAME__Ctx = document.getElementById('__NAME__').getContext('2d');
        var __NAME__Cfg = {
        };
        var __NAME__Plot = new Chart(__NAME__Ctx,__NAME__Cfg);
    ~);

    my $tpl = Quiq::Template->new('text',\$template);

    $tpl->replace(
        __NAME__ => $self->get('name'),
    );

    return $tpl->asStringNL;
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.159

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
