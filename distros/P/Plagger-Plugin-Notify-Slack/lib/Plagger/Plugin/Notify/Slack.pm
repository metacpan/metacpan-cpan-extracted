package Plagger::Plugin::Notify::Slack;
use 5.008001;
use strict;
use warnings;
use base qw( Plagger::Plugin );

use LWP::UserAgent;
use Encode;
use JSON qw(encode_json);

our $VERSION = "0.03";

sub register {
    my ( $self, $context ) = @_;
    $context->register_hook(
        $self,
        'publish.entry' => $self->can('publish'),
        'plugin.init'   => $self->can('initialize'),
    );
}

sub initialize {
    my ( $self, $context, $args ) = @_;

    $self->{remote} = $self->conf->{webhook_url} or return;
}

sub publish {
    my ( $self, $context, $args ) = @_;

    $context->log( info => "Notifying " . $args->{entry}->title . " to Slack" );

    my $text = $self->templatize( 'notify.tt', $args );
    Encode::_utf8_off($text) if Encode::is_utf8($text);

    my $payload = +{ text => $text };
    $payload->{username}   = $self->conf->{username}   if exists $self->conf->{username};
    $payload->{icon_url}   = $self->conf->{icon_url}   if exists $self->conf->{icon_url};
    $payload->{icon_emoji} = $self->conf->{icon_emoji} if exists $self->conf->{icon_emoji};
    $payload->{channel}    = $self->conf->{channel}    if exists $self->conf->{channel};

    my $ua = LWP::UserAgent->new;
    my $res = $ua->post( $self->{remote}, [ payload => encode_json($payload) ] );

    unless ( $res->is_success ) {
        $context->log( error => "Notiying to Slack failed: " . $res->status_line );
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Plagger::Plugin::Notify::Slack - Notify feed updates to Slack

=head1 SYNOPSIS

    - module: Notify::Slack
      config:
        webhook_url: {incoming_webhook_url}

=head1 CONFIG

=over

=item webhook_url

Inconming webhooks URL. (required)

=item username

Username for your bot.

=item icon_url

Icon URL for your bot.

=item icon_emoji

Icon emoji for your bot.

=item channel

Channnel for notifying.

=back

=head1 DESCRIPTION

Plagger::Plugin::Notify::Slack allows you to notify feed updates to Slack channels using Inconming Webhooks.

=head1 LICENSE

Copyright (C) zoncoen.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

zoncoen E<lt>zoncoen@gmail.comE<gt>

=cut

