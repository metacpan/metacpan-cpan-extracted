package Quiq::Html::Construct;
use base qw/Quiq::Html::Tag/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.157';

use Quiq::Css;
use Quiq::JavaScript;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Html::Construct - Generierung von einfachen Tag-Konstrukten

=head1 BASE CLASS

L<Quiq::Html::Tag>

=head1 DESCRIPTION

Die Klasse erweitert ihre Basisklasse Quiq::Html::Tag um die
Generierung von einfachen HTML-Konstrukten, die einerseits
über Einzeltags hinausgehen, andererseits aber nicht die Implementierung
einer eigenen Klasse rechtfertigen.

=head1 METHODS

=head2 Objektmethoden

=head3 loadFiles()

=head4 Synopsis

    $html = $class->loadFiles(@spec);

=head4 Description

Siehe Basisklasse Quiq::Html::Tag.

=cut

# -----------------------------------------------------------------------------

sub loadFiles {
    my $self = shift;
    # @_: @spec

    my $html = '';
    for (my $i = 0; $i < @_; $i++) {
        my $arg = $_[$i];
        if ($arg eq 'css' || $arg =~ /\.css$/) {
            if ($arg eq 'css') {
                $i++;
            }
            $html .= Quiq::Css->style($self,$_[$i]);
        }
        elsif ($arg eq 'js' || $arg =~ /\.js$/) {
            if ($arg eq 'js') {
                $i++;
            }
            $html .= Quiq::JavaScript->script($self,$_[$i]);
        }
        else {
            $self->throw(
                'HTML-00099: Unexpected argument',
                Argument => $arg,
            );
        }
    }

    return $html;
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.157

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
