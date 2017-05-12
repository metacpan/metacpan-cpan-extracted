use strict;
use Test::More;
use Test::Exception;
use Orochi::Declare;

dies_ok {
    inject_constructor '/foo/bar' => (
        class => 'Foo'
    );
};
like($@, qr/^Attempting to run Orochi::Declare::inject_constructor from outside a container/);

done_testing();