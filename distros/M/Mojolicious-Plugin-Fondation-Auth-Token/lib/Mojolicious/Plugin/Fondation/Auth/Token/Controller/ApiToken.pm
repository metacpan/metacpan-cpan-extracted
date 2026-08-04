package Mojolicious::Plugin::Fondation::Auth::Token::Controller::ApiToken;
$Mojolicious::Plugin::Fondation::Auth::Token::Controller::ApiToken::VERSION = '0.01';
use Mojo::Base 'Mojolicious::Controller', -signatures;

# ABSTRACT: REST controller for personal access token management

# ── List current user's tokens ───────────────────────────────────────

sub list ($self) {
    $self->render_later;

    return $self->render(
        json   => { errors => [{ message => 'Authentication required' }] },
        status => 401,
    ) unless $self->is_user_authenticated;

    my $uid = $self->current_user->{id};

    $self->model('api_token')->search(
        { user_id => $uid },
        { order_by => { -desc => 'created_at' } },
    )->all->then(sub ($tokens) {
        my @data = map { {
            id           => $_->id,
            name         => $_->name,
            scopes       => $_->scopes,
            last_used_at => $_->last_used_at,
            created_at   => $_->created_at,
        } } @$tokens;
        $self->render(json => \@data);
    })->on_fail(sub ($err) {
        $self->app->log->error("[ApiToken] list failed: $err");
        $self->render(
            json   => { errors => [{ message => 'Failed to list tokens' }] },
            status => 500,
        );
    })->retain;
}

# ── Revoke a token (own tokens only) ─────────────────────────────────

sub remove ($self) {
    $self->render_later;

    return $self->render(
        json   => { errors => [{ message => 'Authentication required' }] },
        status => 401,
    ) unless $self->is_user_authenticated;

    my $token_id = $self->param('id');
    my $user_id  = $self->current_user->{id};

    $self->model('api_token')->find($token_id)->then(sub ($token) {
        unless ($token && $token->user_id == $user_id) {
            $self->render(
                json   => { errors => [{ message => 'Token not found' }] },
                status => 404,
            );
            return;
        }
        $token->delete->then(sub {
            $self->render(json => {}, status => 204);
        })->retain;
    })->on_fail(sub ($err) {
        $self->render(
            json   => { errors => [{ message => 'Token not found' }] },
            status => 404,
        );
    })->retain;
}

# ── Generate a new token (returns raw token once) ────────────────────

use Digest::SHA qw(sha256_hex);
use Crypt::URandom qw(urandom);

sub generate ($self) {
    $self->render_later;

    return $self->render(
        json   => { errors => [{ message => 'Authentication required' }] },
        status => 401,
    ) unless $self->is_user_authenticated;

    my $json = $self->req->json // {};
    my $name = $json->{name};
    return $self->render(
        json   => { errors => [{ message => 'Name is required' }] },
        status => 400,
    ) unless $name && $name =~ /\S/;

    my $raw_token = unpack('H*', urandom(32));
    my $hash      = sha256_hex($raw_token);

    $self->model('api_token')->create({
        user_id    => $self->current_user->{id},
        token_hash => $hash,
        name       => $name,
        scopes     => $json->{scopes},
    })->then(sub ($api_token) {
        $self->render(
            json => {
                id         => $api_token->id,
                name       => $api_token->name,
                scopes     => $api_token->scopes,
                created_at => $api_token->created_at,
                raw_token  => $raw_token,
            },
            status => 201,
        );
    })->on_fail(sub ($err) {
        $self->app->log->error("[ApiToken] generate failed: $err");
        $self->render(
            json   => { errors => [{ message => 'Failed to create token' }] },
            status => 500,
        );
    })->retain;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Fondation::Auth::Token::Controller::ApiToken - REST controller for personal access token management

=head1 VERSION

version 0.01

=head1 AUTHOR

Daniel Brosseau <dab@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Daniel Brosseau.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
