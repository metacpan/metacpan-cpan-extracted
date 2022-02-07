package Telebot::Controller::Tg;
use Mojo::Base 'Mojolicious::Controller', -signatures;

sub update ($c) {
    my $data = $c->req->json;
    $c->dump($data) if $c->app->config->{trace};
    if ($data->{update_id}) {
        $c->minion->enqueue(update => [$data]);
    }
    $c->render(json => {ok => \1});
}

sub index ($c) {
    $c->render;
}

1;

=pod
 
=encoding utf8

=head1 NAME
 
Telebot::Controller::Tg - Controller for telegram webhook processing.

=head1 SYNOPSIS

    use Telebot::Controller::Tg;
    my $app = Telebot::Controller::Tg->new;

=head1 DESCRIPTION

L<Telebot::Controller::Tg> is controller for processing incoming webhook requests.

=head1 ATTRIBUTES

L<Telebot::Controller::Tg> inherits all attributes from L<Mojolicious::Controller>.

=head1 METHODS

L<Telebot::Controller::Tg> inherits all methods from L<Mojolicious::Controller> and implements the following new ones.

=head2 index
    
    $app->index;

Root page.

=head2 update
    
    $app->update;

Process incoming webhook.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022, Igor Lobanov.
This program is free software, you can redistribute it and/or modify it under the terms of the Artistic License version
2.0.

=head1 SEE ALSO

L<https://github.com/igorlobanov/telebot>, L<Mojolicious::Guides>, L<https://mojolicious.org>,
L<https://core.telegram.org/bots/api>.

=cut
