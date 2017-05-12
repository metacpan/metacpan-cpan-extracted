use warnings;
use strict;
use lib 't';
use Test::Moose;
use Test::More tests => 13;

my $class = 'Siebel::Srvrmgr::Connection';

require_ok($class);
can_ok(
    $class,
    qw(get_server set_server get_gateway set_gateway get_enterprise set_enterprise get_user set_user get_password set_password get_lang_id set_lang_id get_field_del get_params get_params_pass)
);
foreach my $attrib (
    qw(server gateway enterprise user password lang_id field_delimiter))
{
    has_attribute_ok( $class, $attrib );
}
ok(
    my $instance = $class->new(
        {
            server          => 'foobar',
            gateway         => 'foobar.com.br',
            enterprise      => 'foobar',
            user            => 'foo',
            password        => 'bar',
            lang_id         => 'PTB',
            bin             => '/usr/local/siebel/bin/srvrmgr',
            field_delimiter => '|'
        }
    ),
    'constructor works'
);
is( ref( $instance->get_params ),
    'ARRAY', 'get_params returns an array reference' );
is(
    join( ' ', @{ $instance->get_params } ),
'/usr/local/siebel/bin/srvrmgr /e foobar /g foobar.com.br /u foo /l PTB /s foobar /k |',
    'get_params has the expected parameters'
);
is(
    join( ' ', @{ $instance->get_params_pass } ),
'/usr/local/siebel/bin/srvrmgr /e foobar /g foobar.com.br /u foo /l PTB /s foobar /k | /p bar',
    'get_params_pass has the expected parameters'
);

