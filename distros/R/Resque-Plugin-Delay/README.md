<div>
    <a href="https://travis-ci.org/meru-akimbo/resque-delay-perl"><img src="https://travis-ci.org/meru-akimbo/resque-delay-perl.svg?branch=master"></a>
</div>

# NAME

Resque::Plugin::Delay - Delay the execution of job

# SYNOPSIS

    use Resque;

    my $start_time = time + 100;

    my $resque = Resque->new(redis => $redis_server, plugins => ['Delay']);
    $resque->push('test-job' => +{
            class => 'Hoge',
            args  => [+{ cat => 'nyaaaa' }, +{ dog => 'bow' }],
            start_time => $start_time,
        }
    );

# DESCRIPTION

Passing epoch to the start\_time attribute of payload makes it impossible to execute work until that time.

# LICENSE

Copyright (C) meru\_akimbo.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

meru\_akimbo <merukatoruayu0@gmail.com>
