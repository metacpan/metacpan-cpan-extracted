package Plack::Middleware::Zitadel;

# ABSTRACT: Verify Bearer tokens via ZITADEL OIDC in Plack apps

use strict;
use warnings;

use parent 'Plack::Middleware';
use Plack::Util::Accessor qw(issuer audience required_scopes claims_env_key realm oidc);
use JSON::MaybeXS qw(encode_json);
use WWW::Zitadel::OIDC;

our $VERSION = '0.010';

sub prepare_app {
    my ($self) = @_;

    $self->claims_env_key('zitadel.claims')
        unless defined $self->claims_env_key;
    $self->realm('api')
        unless defined $self->realm;

    my $oidc = $self->oidc;
    if (!$oidc) {
        die "issuer required\n" unless $self->issuer;
        $oidc = WWW::Zitadel::OIDC->new(issuer => $self->issuer);
    }

    die "oidc object must implement verify_token\n"
        unless $oidc->can('verify_token');

    $self->{_oidc} = $oidc;
}

sub call {
    my ($self, $env) = @_;

    my ($ok, $token_or_error) = $self->_extract_bearer($env->{HTTP_AUTHORIZATION});
    return $self->_unauthorized('invalid_request', $token_or_error)
        unless $ok;

    my %verify_args;
    if (defined $self->audience && length $self->audience) {
        $verify_args{audience} = $self->audience;
    }

    my $claims = eval {
        $self->{_oidc}->verify_token($token_or_error, %verify_args);
    };
    if (my $err = $@) {
        $err =~ s/\s+\z//;
        return $self->_unauthorized('invalid_token', $err || 'token verification failed');
    }

    my @required = $self->_required_scope_list;
    if (@required && !$self->_has_required_scopes($claims, \@required)) {
        return $self->_forbidden('insufficient_scope', 'required scopes are missing');
    }

    $env->{ $self->claims_env_key } = $claims;
    $env->{'zitadel.token'} = $token_or_error;

    return $self->app->($env);
}

sub _extract_bearer {
    my ($self, $header_value) = @_;

    return (0, 'missing Authorization header')
        unless defined $header_value && length $header_value;

    return (0, 'Authorization must use Bearer token')
        unless $header_value =~ /^Bearer\s+(.+)\z/i;

    my $token = $1;
    return (0, 'empty bearer token') unless defined $token && length $token;

    return (1, $token);
}

sub _required_scope_list {
    my ($self) = @_;
    my $scopes = $self->required_scopes;

    return () unless defined $scopes;

    if (ref($scopes) eq 'ARRAY') {
        return grep { defined $_ && length $_ } @$scopes;
    }

    return grep { length $_ } split /\s+/, "$scopes";
}

sub _has_required_scopes {
    my ($self, $claims, $required) = @_;

    my $scope_str = $claims->{scope} // '';
    my %have = map { $_ => 1 } grep { length $_ } split /\s+/, $scope_str;

    for my $need (@$required) {
        return 0 unless $have{$need};
    }

    return 1;
}

sub _unauthorized {
    my ($self, $error, $description) = @_;
    my $header = sprintf(
        'Bearer realm="%s", error="%s", error_description="%s"',
        $self->realm,
        $error,
        $description,
    );

    return [
        401,
        [
            'Content-Type' => 'application/json',
            'WWW-Authenticate' => $header,
        ],
        [ encode_json({ error => $error, error_description => $description }) ],
    ];
}

sub _forbidden {
    my ($self, $error, $description) = @_;

    return [
        403,
        [ 'Content-Type' => 'application/json' ],
        [ encode_json({ error => $error, error_description => $description }) ],
    ];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Plack::Middleware::Zitadel - Verify Bearer tokens via ZITADEL OIDC in Plack apps

=head1 VERSION

version 0.010

=head1 SYNOPSIS

    use Plack::Builder;

    my $app = sub { [200, ['Content-Type' => 'text/plain'], ['ok']] };

    my $wrapped = builder {
        enable 'Plack::Middleware::Zitadel',
            issuer          => 'https://zitadel.example.com',
            audience        => 'my-api',
            required_scopes => ['openid', 'profile'];
        $app;
    };

=head1 DESCRIPTION

Validates incoming Bearer tokens using L<WWW::Zitadel::OIDC> and injects
decoded claims into the PSGI environment.

On success, claims are available in C<$env->{'zitadel.claims'}> and the raw
token in C<$env->{'zitadel.token'}>.

On failure, responds with C<401> or C<403> and a JSON body plus a
C<WWW-Authenticate: Bearer> header per RFC 6750.

=head2 issuer

OIDC issuer URL. Required unless C<oidc> is provided.

=head2 audience

Optional audience string passed to C<verify_token>.

=head2 required_scopes

Optional scope requirement as an arrayref or space-separated string.  All
listed scopes must be present in the token's C<scope> claim.

=head2 claims_env_key

PSGI env key under which decoded claims are stored.  Defaults to
C<zitadel.claims>.

=head2 realm

Realm value in the C<WWW-Authenticate> response header.  Defaults to C<api>.

=head2 oidc

Optional pre-built OIDC object.  Must implement C<verify_token>.  When
provided, C<issuer> is not required.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-plack-middleware-zitadel/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
