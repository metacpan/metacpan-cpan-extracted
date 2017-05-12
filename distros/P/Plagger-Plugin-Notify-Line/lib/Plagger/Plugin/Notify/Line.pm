package Plagger::Plugin::Notify::Line;

use strict;
use warnings;
use 5.008_001;
use parent qw(Plagger::Plugin);
use Encode;
use Furl;

our $VERSION = '0.02';

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'publish.entry' => \&notify_entry,
    );
}

sub initialize {
    my($self, $context) = @_;
}

sub notify_entry {
    my($self, $context, $args) = @_;

    my $endpoint =
        $self->conf->{endpoint_url}
            || 'https://notify-api.line.me/api/notify';

    my $token = $self->conf->{access_token};
    unless ($token) {
        $context->log(
            error => q|You must configure your LINE Notify's | .
                     q|personal access token as "access_token".|
        );
        return;
    }

    my $message = $self->templatize('notify_line.tt', $args);
    $message = encode_utf8($message);

    my $ua = Furl->new;

    my $res = $ua->post(
        $endpoint,
        [ 'Authorization' => 'Bearer ' . $token ],
        [ 'message'       => $message           ],
    );

    unless ($res->is_success) {
        $context->log(
            error => qq|LINE Notify failed:\n| .
                     qq|status: | . $res->status_line . qq|\n| .
                     qq|body: | . $res->content
        );
        return;
    }

    $context->log(info => qq|LINE Notify Succeed:\nbody: | . $res->content);
}

1;
__END__

=head1 NAME

Plagger::Plugin::Notify::Line - Notify feed updates to LINE Notify

=head1 SYNOPSIS

 - module: Notify::Line
   config:
     access_token: SEtYoUrpeRsOnaLLInEnOtiFysaCceSStOkeNaTHEre

=head1 DESCRIPTION

Plagger::Plugin::Notify::Line allows to you to notify feed updates
to specified friends, groups or you.
You need to register you as LINE developer and then you need to be issued
your personal access token at LINE Notify's website,
L<https://notify-bot.line.me/my/>.

=head1 AUTHOR

Koichi Taniguchi (a.k.a. nipotan) E<lt>taniguchi@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Plagger>, L<Plagger::Plugin>

=cut
