package Plack::Middleware::HubSignature;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.02";

use parent 'Plack::Middleware';
use Plack::Util;
use Plack::Util::Accessor qw/secret/;
use Plack::Request;

use Digest::SHA;
use String::Compare::ConstantTime;

sub call {
    my ($self, $env) = @_;

    my $req = Plack::Request->new($env);
    my $expected = 'sha1=' . Digest::SHA::hmac_sha1_hex($req->content, $self->secret);
    my $actual = $req->header('X-Hub-Signature') || '';
    if (!String::Compare::ConstantTime::equals($expected, $actual)) {
        return [403, ['Content-Type' => 'text/plain', 'Content-Length' => 9], ['Forbidden'] ];
    }

    $self->app->($env);
}

1;
__END__

=encoding utf-8

=head1 NAME

Plack::Middleware::HubSignature - Validating payloads from GitHub

=head1 SYNOPSIS

    use Plack::Builder;
    my $app = sub { ... };
    builder {
        enable "Plack::Middleware::HubSignature",
            secret => 'YOUR SECRET';
        $app;
    };

=head1 DESCRIPTION

Plack::Middleware::HubSignature is for validating payloads from GitHub Webhooks.

=head1 CONFIGURATION

=head2 C<secret>

Secret token set at GitHub Webhook setting. See L<https://developer.github.com/webhooks/securing/> for more details.

=head1 SEE ALSO

See L<Github::Hooks::Receiver> and L<Plack::App::GitHub::WebHook> for apps to
receive GitHub Webhooks.

=head1 LICENSE

Copyright (C) Songmu.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Songmu E<lt>y.songmu@gmail.comE<gt>

=head1 CONTRIBUTORS

Jakob Voß E<lt>jako.voss@gbv.deE<gt>

=cut
