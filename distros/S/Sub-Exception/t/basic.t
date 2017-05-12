use strict;
use warnings;
use Test::More;

use Sub::Exception
    database_do => sub { die sprintf 'DB Error: %s', $_  },
    redis_do    => sub { die sprintf 'Redis Error: %s', $_ };
    
eval {
    database_do {
        die "some db error";
    }
};
like $@, qr/^DB Error: some db error/, 'err ok';

eval {
    redis_do {
        die "some redis error";
    }
};
like $@, qr/^Redis Error: some redis error/, 'err ok';

done_testing;
