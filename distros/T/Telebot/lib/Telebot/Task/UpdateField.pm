package Telebot::Task::UpdateField;
use Mojo::Base 'Minion::Job', -signatures;

sub run ($job, $payload, $update_id) {
    my $app = $job->app;
    if (my $handler = $app->tg->handler($job->task)) {
        $handler->new(
            app => $app,
            update_id => $update_id,
            payload => $payload,
        )->run;
    }
    else {
        $job->note(warning => 'No handler for '.$job->task);
    }
    return $job->finish;
}

1;

=pod
 
=encoding utf8

=head1 NAME
 
Telebot::Task::UpdateField - Minion job for processing part of update.

=head1 SYNOPSIS

    use Telebot::Task::UpdateField;
    $app->minion->add_task(message => 'Telebot::Task::UpdateField');
    $app->minion->enqueue(message => [$payload, $update_id]);

=head1 DESCRIPTION

L<Telebot::Task::UpdateField> is the task for processing part of incoming telegram update.
This task is setup in app for all allowed updates.

=head1 ATTRIBUTES

L<Telebot::Task::UpdateField> inherits all attributes from L<Minion::Job>.

=head1 METHODS

L<Telebot::Task::UpdateField> inherits all methods from L<Minion::Job>.

=head2 run
    
    $job->run($payload, $update_id);

This is overloaded method which determine what part of update must be processed,
creates instance of corresponding field handler and call handler's B<run>
with payload and update_id.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022, Igor Lobanov.
This program is free software, you can redistribute it and/or modify it under the terms of the Artistic License version
2.0.

=head1 SEE ALSO

L<https://github.com/igorlobanov/telebot>, L<Mojolicious::Guides>, L<https://mojolicious.org>,
L<https://core.telegram.org/bots/api>.

=cut
