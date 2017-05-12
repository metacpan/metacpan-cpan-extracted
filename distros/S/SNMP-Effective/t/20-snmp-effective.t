use strict;
use warnings;
use lib qw(lib);
use Test::More;
use SNMP::Effective;
use SNMP::Effective::Host;

plan tests => 24;

{
    is_deeply(
        { SNMP::Effective::_format_arguments(MyKey1 => 1, my_key2 => 2, My_Key3 => 3, mYK__EY4 => 4 ) },
        { mykey1 => 1, mykey2 => 2, mykey3 => 3, mykey4 => 4 },
        '_format_arguments() normalized arguments',
    );
}

{
    use POSIX qw(:errno_h);

    is_deeply( [ SNMP::Effective->_check_errno(0) ], [0, "Couldn't resolve hostname"], 'errno = 0 failed as expected' );
    is_deeply( [ SNMP::Effective->_check_errno(200) ], [0, "200"], 'errno = 200 failed as expected' );

    for(EINTR, EAGAIN, ENOMEM, ENFILE, EMFILE) {
        is_deeply(
            [ SNMP::Effective->_check_errno($_) ],
            [ 1, "$_ (will retry)" ],
            "errno = $_ will retry"
        );
    }
}

{
    my $host = SNMP::Effective::Host->new('127.0.0.1');
    my $snmp;

    ok($snmp = SNMP::Effective->_create_session($host), 'created SNMP::Session');
    is($snmp->{'Version'}, '2c', 'default SNMP::Session Version is "2c"');
    is($snmp->{'Community'}, 'public', 'default SNMP::Session Community is "public"');
    is($snmp->{'Timeout'}, 1e6, 'default SNMP::Session Timeout is 1e6');
    is($snmp->{'Retries'}, '2', 'default SNMP::Session Retries is 2');
}

{
    my $effective = SNMP::Effective->new;

    is($effective->master_timeout, undef, 'master_timeout is undef by default');
    is($effective->max_sessions, 1, 'max_sessions is 1 by default');
    isa_ok($effective->hostlist, 'SNMP::Effective::HostList');
    is_deeply($effective->arg, {}, 'arg is empty hash-ref by default');
    is(ref $effective->callback, 'CODE', 'callback is an empty code-ref by default');
    is_deeply($effective->_varlist, [], '_varlist is empty by default');
}

{
    is(SNMP::Effective::match_oid('1.3.6.10', '1.3.6'), '10', 'oid 1.3.6.10 and 1.3.6 match');
    is(SNMP::Effective::match_oid('1.3.6.10.1', '1.3.6'), '10.1', 'oid 1.3.6.10.1 and 1.3.6 match');
    is(SNMP::Effective::match_oid('1.3.6.10', '1.3.6.11'), undef, 'oid 1.3.6.10 and 1.3.6.11 does not match');
}

TODO: {
    local $TODO = 'something is wrong with the loaded MIB';
    is(SNMP::Effective::make_name_oid('1.3.6.1.2.1.1.1'), 'sysDescr', 'make_name_oid(1.3.6.1.2.1.1.1)');
    is(SNMP::Effective::make_numeric_oid('sysDescr'), '.1.3.6.1.2.1.1.1', 'make_numeric_oid(sysDescr)');
}
