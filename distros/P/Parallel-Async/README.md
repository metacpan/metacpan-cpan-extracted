# NAME

Parallel::Async - run parallel task with fork to simple.

# SYNOPSIS

    use Parallel::Async;

    my $task = async {
        print "[$$] start!!\n";
        my $msg = "this is run result of pid:$$."; # MSG
        return $msg;
    };

    my $msg = $task->recv;
    say $msg; # same as MSG

# DESCRIPTION

Parallel::Async is yet another fork tool.
Run parallel task with fork to simple.

See also [Parallel::Async::Task](http://search.cpan.org/perldoc?Parallel::Async::Task) for more usage.

# SEE ALSO

[Parallel::ForkManager](http://search.cpan.org/perldoc?Parallel::ForkManager) [Parallel::Prefork](http://search.cpan.org/perldoc?Parallel::Prefork)

# LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

karupanerura <karupa@cpan.org>
