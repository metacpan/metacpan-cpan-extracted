package Telebot::Task::Update;
use Mojo::Base 'Minion::Job', -signatures;

sub run ($job, $payload) {
    my $app = $job->app;
    if ($payload->{update_id}) {
        if (my $handler = $app->tg->handler('update')) {
            $handler->new(
                app => $app,
                update_id => $payload->{update_id},
                payload => $payload,
            )->run;
        }
        for ($app->tg->allowed_updates->each) {
            $app->minion->enqueue($_ => [
                $payload->{$_},
                $payload->{update_id}
            ]) if exists $payload->{$_};
        }
    }
    else {
        $job->note(warning => 'No update_id');
    }
    return $job->finish;
}

1;

=pod
 
=encoding utf8

=head1 NAME
 
Telebot::Task::Update - Minion job for processing update.

=head1 SYNOPSIS

    use Telebot::Task::Update;
    $app->minion->add_task(update => 'Telebot::Task::Update');
    $app->minion->enqueue(update => [$payload]);

=head1 DESCRIPTION

L<Telebot::Task::Update> is the task for processing incoming telegram update.
This task is executed if app have handler for update.

=head1 ATTRIBUTES

L<Telebot::Task::Update> inherits all attributes from L<Minion::Job>.

=head1 METHODS

L<Telebot::Task::Update> inherits all methods from L<Minion::Job>.

=head2 run
    
    $job->run($payload);

This is overloaded method which creates instance of update handler
and call handler's B<run> with payload. After executing handler, task
enqueues tasks for parts of update with this part payload and update_id.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022, Igor Lobanov.
This program is free software, you can redistribute it and/or modify it under the terms of the Artistic License version
2.0.

=head1 SEE ALSO

L<https://github.com/igorlobanov/telebot>, L<Mojolicious::Guides>, L<https://mojolicious.org>,
L<https://core.telegram.org/bots/api>.

=cut
