package Plack::Middleware::PostErrorToSlack;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.01";

use Plack::Util::Accessor qw(webhook_url channel username icon_url icon_emoji);

use parent qw(Plack::Middleware);

use Plack::Response;
use Try::Tiny;

use LWP::UserAgent;
use JSON::XS qw(encode_json);

sub call {
    my $self = shift;
    my $env = shift;

    my $error;
    my $res = try {
        $self->app->($env);
    } catch {
        $error = $_;
    };
    if ($error) {
        $self->post_error($env, $error);
        die $error;
    }

    return $res;
}

sub post_error {
    my ($self, $env, $error) = @_;

    my $message = $self->error_message($env, $error);

    my $ua = LWP::UserAgent->new;

    unless ($self->webhook_url) {
        warn 'Please set webhook_url';
    }

    my $payload = {
        text       => $message,
    };
    for my $key (qw{channel username icon_url icon_emoji}) {
        my $value = $self->$key;
        next unless $value;
        $payload->{$key} = $value;
    }

    $ua->post($self->webhook_url, {
        payload => encode_json($payload),
    });
}

sub error_message {
    my ($self, $env, $error) = @_;

    my $user = $ENV{'USER'};

    my $branch = `git rev-parse --abbrev-ref HEAD`;
    chomp $branch;

    $error = $error . ''; # copy;
    chomp $error;

    if ($branch) {
        sprintf "%s encountered an error while `%s %s` on branch `%s`\n```\n%s\n```", $user, $env->{REQUEST_METHOD}, $env->{PATH_INFO}, $branch, $error;
    } else {
        sprintf "%s encountered an error while `%s %s`\n```\n%s\n```", $user, $env->{REQUEST_METHOD}, $env->{PATH_INFO}, $error;
    }
}

1;

__END__

=encoding utf-8

=head1 NAME

Plack::Middleware::PostErrorToSlack - Post error message to Slack when you app dies

=head1 SYNOPSIS

    enable "PostErrorToSlack",
        webhook_url => 'https://hooks.slack.com/services/...'; # Incoming Webhook URL

=head1 DESCRIPTION

When your app dies, Plack::Middleware::PostErrorToSlack posts the error to Slack, and rethrow the error.

You can share your error with your team members, And you can discuss how to fix it.

This module is mainly for local development. Do not enable this on production environment.

=head1 CONFIGURATION

=over 4

=item webhook_url (required)

You must set up an Incoming Webhooks and set webhook_url. Read the document below.

L<https://api.slack.com/incoming-webhooks>

=item channel, username, icon_url, icon_emoji

You can override these parameters.

=back

=head1 LICENSE

Copyright (C) hitode909.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

hitode909 E<lt>hitode909@gmail.comE<gt>

=cut

