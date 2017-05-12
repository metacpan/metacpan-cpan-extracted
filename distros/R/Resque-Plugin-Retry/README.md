<div>
    <a href="https://travis-ci.org/meru-akimbo/resque-retry-perl"><img src="https://travis-ci.org/meru-akimbo/resque-retry-perl.svg?branch=master"></a>
</div>

# NAME

Resque::Plugin::Retry - Retry the fail job

# SYNOPSIS

    use Resque;

    my $resque = Resque->new(redis => $redis_server, plugins => ['Retry']);
    $resque->push('test-job' => +{
            class => 'Hoge',
            args  => [+{ cat => 'nyaaaa' }, +{ dog => 'bow' }],
            max_retry => 3,
        }
    );

# DESCRIPTION

Retry when the job fails

# LICENSE

Copyright (C) meru\_akimbo.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

meru\_akimbo <merukatoruayu0@gmail.com>
