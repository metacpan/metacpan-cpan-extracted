package Quiq::Mojolicious::Plugin::Log::Parameters;
use base qw/Mojolicious::Plugin/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.147';

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Mojolicious::Plugin::Log::Parameters - Logge Request-Parameter

=head1 BASE CLASS

Mojolicious::Plugin

=head1 SYNOPSIS

    # Mojolicious
    $app->plugin('Quiq::Mojolicious::Plugin::Log::Parameters');
    
    # Mojolicious::Lite
    plugin 'Quiq::Mojolicious::Plugin::Log::Parameters';

=head1 DESCRIPTION

Das Plugin installiert einen C<before_routes> Handler, der bei
jedem Request auf Loglevel C<debug> die Liste der empfangenen GET-
und POST-Parameter ins Log ausgibt.

Das Plugin ist bei der Entwicklung von Action-Seiten zu Formularen
nützlich, denn es macht sichtbar, welche Daten die Action-Seite
empfängt.

=head1 METHODS

=head2 Objektmethoden

=head3 register() - Registriere Plugin

=head4 Synopsis

    $plugin->register($app,$conf);

=head4 Description

Diese Methode implementiert die Funktionalität des Plugin. Sie
wird nicht direkt, sondern von Mojolicious aufgerufen.

=cut

# -----------------------------------------------------------------------------

sub register {
    my ($self,$app,$conf) = @_;

    $app->hook(before_routes=>sub {
        my $c = shift;

        my $p = $c->req->params;
        for my $key (sort @{$p->names}) {
            my $valA = $p->every_param($key);
            $c->app->log->debug(
                "Param: $key => ".join ',',map {qq|"$_"|} @$valA);
        }
    });

    return;
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
