use Test::More;
use URI;

{
    package My::Test;
    use Any::Moose;
    use Net::Google::DataAPI::Types;

    has url => (
        is => 'rw',
        isa => 'Net::Google::DataAPI::Types::URI',
        coerce => 1,
    );
}

ok my $t = My::Test->new;
isa_ok $t, 'My::Test';
ok $t->url('test.com');
is $t->url->scheme, 'http';
is $t->url->as_string, 'http://test.com';

ok $t->url('http://test.com/');
is $t->url->as_string, 'http://test.com/';

ok $t->url('https://test.com/');
is $t->url->as_string, 'https://test.com/';

done_testing;
