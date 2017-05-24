use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;

BEGIN {
    $pkg = 'Plack::Middleware::Memento::Handler::Catmandu::Bag';
    use_ok $pkg;
}

done_testing;
