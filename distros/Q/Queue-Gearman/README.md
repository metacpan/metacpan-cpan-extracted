# NAME

Queue::Gearman - Queue like low-level interface for Gearman.

# SYNOPSIS

    use Queue::Gearman;
    use JSON;

    sub add {
        my $args = shift;
        return $args->{left} + $args->{rigth};
    }

    my $queue = Queue::Gearman->new(
        servers            => ['127.0.0.1:6667'],
        serialize_method   => \&JSON::encode_json,
        deserialize_method => \&JSON::decode_json,
    );
    $queue->can_do('add');

    my $task = $queue->enqueue_forground(add => { left => 1, rigth => 2 })
        or die 'failure';
    $queue->enqueue_background(add => { left => 2, rigth => 1 })
        or die 'failure';

    my $job = $queue->dequeue();
    if ($job && $job->func eq 'add') {
        my $res = eval { add($job->arg) };
        if (my $e = $@) {
            $job->fail($e);
        }
        else {
            $job->complete($res);
        }
    }

    $task->wait();
    print $task->result, "\n"; ## => 3

# DESCRIPTION

Queue::Gearman is ...

# LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

karupanerura <karupa@cpan.org>
