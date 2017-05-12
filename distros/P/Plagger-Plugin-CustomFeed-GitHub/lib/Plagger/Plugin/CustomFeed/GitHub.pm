package Plagger::Plugin::CustomFeed::GitHub;
use strict;
use warnings;
use base qw(Plagger::Plugin);

use LWP::UserAgent;

our $VERSION = "0.01";

sub register {
    my ( $self, $context ) = @_;

    $context->register_hook( $self, 'subscription.load' => $self->can('load'), );
}

sub load {
    my ( $self, $context, $args ) = @_;

    my $feed = Plagger::Feed->new;
    $feed->aggregator( sub { $self->aggregate(@_) } );
    $context->subscription->add($feed);

    return;
}

sub aggregate {
    my ( $self, $context, $args ) = @_;

    my $token = $self->conf->{token} or return;
    my $users = $self->conf->{users} or return;
    $users = [$users] unless ref $users;

    my $ua     = LWP::UserAgent->new;
    my $header = HTTP::Headers->new(
        "Authorization" => "token $token",
        "Accept"        => "application/atom+xml"
    );
    for my $user (@$users) {
        my $url = "https://github.com/$user";
        my $req = HTTP::Request->new( 'GET', $url, $header );

        $context->log( debug => "Fetch feed from $url" );

        my $res = $ua->request($req);

        unless ( $res->is_success ) {
            $context->log( error => "GitHub API failed: " . $res->status_line );
            next;
        }

        my $content = HTML::Entities::decode( $res->content );

        Plagger::Plugin::Aggregator::Simple->handle_feed( $url, \$content );
    }
}

1;

__END__

=encoding utf-8

=head1 NAME

Plagger::Plugin::CustomFeed::GitHub - Custom feed for GitHub

=head1 SYNOPSIS

    - module: CustomFeed::GitHubFeed
        config:
          token: {github_api_token}
          users:
            - {github_username}

=head1 DESCRIPTION

Plagger::Plugin::CustomFeed::GitHub fetches public timeline for any user.

=head1 LICENSE

Copyright (C) zoncoen.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

zoncoen E<lt>zoncoen@gmail.comE<gt>

=cut

