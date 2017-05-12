use strict;

use Test::More;

use PagSeguro::API;

subtest 'pagseguro instance' => sub {
    my $p = PagSeguro::API->new;
    isa_ok $p, 'PagSeguro::API';
};


subtest 'pagseguro constructor' => sub {
    my $p = PagSeguro::API->new(
        email => 'foo', token => 'bar'
    );
    
    is $p->email, 'foo';
    is $p->token, 'bar';
};


subtest 'pagseguro accessors' => sub {
    my $p = PagSeguro::API->new;
    $p->email('foo');
    $p->token('bar');

    is $p->email, 'foo';
    is $p->token, 'bar';

    # default values
    is $p->environment, 'production';
    is $p->debug, 0;

    # custom values
    $p->environment('sandox');
    $p->debug(1);

    is $p->environment, 'sandox';
    is $p->debug, 1;
};


done_testing;
