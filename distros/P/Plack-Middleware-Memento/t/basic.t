use strict;
use Test::More;
use Plack::Middleware::Memento;

my $pkg;

BEGIN {
    $pkg = 'Plack::Middleware::Memento';
    use_ok $pkg;
}

done_testing;
