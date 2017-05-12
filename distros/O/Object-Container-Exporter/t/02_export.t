use strict;
use warnings;
use lib './t/lib';
use Test::More;
use Mock::Container qw/api form/;

subtest 'export api function' => sub {
    isa_ok api('User'), 'Mock::Api::User';
    isa_ok api('user'), 'Mock::Api::User';
    is api('User')->name, 'nekokak';

    eval { api('Oops') };
    ok $@;
};

subtest 'export form' => sub {
    isa_ok form('Foo'), 'Mock::Api::Form::Foo';
    is form('foo')->fillin, 'filled';

    eval { form('Oops') };
    ok $@;
};

subtest 'export form' => sub {
    isa_ok form('Foo'), 'Mock::Api::Form::Foo';
    is form('foo')->fillin, 'filled';

    eval { form('Oops') };
    ok $@;
};

done_testing;

