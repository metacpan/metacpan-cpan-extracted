# NAME

Queue::Q4M::Worker - Worker Object Receiving Items From Q4M

# SYNOPSIS

    use Queue::Q4M::Worker;

    my $worker = Queue::Q4M::Worker->new(
        sql => "SELECT * FROM my_queue WHERE queue_wait(...)",
        max_workers => 10, # use Parallel::Prefork
        work_once => sub {
            my ($worker, $row) = @_;
            # $row is a HASH
        }
    );

    $worker->work;

# DESCRIPTION

Queue::Q4M::Worker abstracts a worker subscribing to a Q4M queue.

# CAVEATS

This is a proof of concept release. Please report bugs, and send pull
requests if you like the idea.

# AUTHOR

Daisuke Maki `<daisuke@endeworks.jp>`

# COPYRIGHT AND LICENSE

Copyright (C) 2011 by Daisuke Maki

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.
