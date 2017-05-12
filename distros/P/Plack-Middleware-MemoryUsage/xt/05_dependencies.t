# -*- mode: cperl; -*-
use Test::Dependencies
    exclude => [qw(Test::Dependencies Test::Base Test::Perl::Critic
                   Plack::Util::Accessor
                   Plack::Middleware::MemoryUsage)],
    style   => 'light';
ok_dependencies();
