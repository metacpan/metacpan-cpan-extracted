# NAME

Teamcity::Executor - Executor of TeamCity build configurations

# SYNOPSIS

    use Teamcity::Executor;
    use IO::Async::Loop;
    use Log::Any::Adapter;

    Log::Any::Adapter->set(
        'Dispatch',
        outputs => [
            [
                'Screen',
                min_level => 'debug',
                stderr    => 1,
                newline   => 1
            ]
        ]
    );

    my $loop = IO::Async::Loop->new;
    my $tc = Teamcity::Executor->new(
        credentials => {
            url  => 'https://teamcity.example.com',
            user => 'user',
            pass => 'password',
        },
        build_id_mapping => {
            hello_world => 'playground_HelloWorld',
            hello_name  => 'playground_HelloName',
        }
        poll_interval => 10,
        loop => $loop,
    );

    $tc->register_polling_timer();

    my $future = $tc->run('hello_name', { name => 'TeamCity' })->then(
        sub {
            my ($build) = @_;
            print "Build succeeded\n";
            my $greeting = $tc->get_artifact_content($build, 'greeting.txt');
            print "Content of greeting.txt artifact: $greeting\n";
        },
        sub {
            print "Build failed\n";
            exit 1
        }
    );

    my $touch_future = $tc->touch('hello_name', { name => 'TeamCity' })->then(
        sub {
            my ($build) = @_;
            print "Touch build started\n";
            $loop->stop();
        },
        sub {
            print "Touch build failed to start\n";
            exit 1
        }
    );

    $loop->run();

# DESCRIPTION

Teamcity::Executor is a module for executing Teamcity build configurations.
When you execute one, you'll receive a future of the build. Teamcity::Executor
polls TeamCity and when it finds the build has ended, it resolves the future.

# LICENSE

Copyright (C) Avast Software

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Miroslav Tynovsky <tynovsky@avast.com>
