use 5.12.1;
use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/lib";

use File::Temp;
use File::Basename;
use Test::More;
use Test::Trap qw/ :on_fail(diag_all_once) /;
use Data::Dump qw(pp);
use ORA_Test;

SKIP: {
    my $ora_test = ORA_Test->new();
    skip $@ if $@;

    $ora_test->login();
    my $result;

    $result = trap {
        $ora_test->rest->get( api => "config/host/1" );
    };
    $trap->did_return(" ... returned");
    $trap->quiet(" ... quietly");
    like( $result->{object}->{name},
        qr/^\w+/, "Pulled opview host configuration" );
    note( "result from import: ", pp($result) );

    # create a new host
    $result = trap {
        $ora_test->rest->put(
            api  => 'config/host',
            data => {
                ip   => "127.0.100.1",
                name => "OpsviewRestAPI_test"
            },
        );
    };
    $trap->did_return(" ... returned");
    $trap->quiet(" ... quietly");

    ok( $result->{object}->{id} > 1,
        "test host 'OpsviewRestAPI_test' created" );

    note( "Result from create: ", pp($result) );

    my $hostid = $result->{object}->{id};

    # amend the host - add some hostattributes in
    $result = trap {
        $ora_test->rest->put(
            api  => 'config/host/' . $hostid,
            data => {
                hostattributes => [
                    { 'name' => 'WINCREDENTIALS', 'value' => 'VALS' },
                    { 'name' => 'WINSERVICE',     'value' => 'something' },
                ]
            }
        );
    };
    $trap->did_return(" ... returned");
    $trap->quiet(" ... quietly");

    is( ref( $result->{object}->{hostattributes} ),
        "ARRAY", "hostattr is array" );
    is( scalar( @{ $result->{object}->{hostattributes} } ),
        2, "2 x hostattr" );

    note( "Result from amend ", pp($result) );

    # tidy up after outselves -remove the example host
    $result = trap {
        $ora_test->rest->delete( api => 'config/host/' . $hostid, );
    };
    $trap->did_return(" ... returned");
    $trap->quiet(" ... quietly");

    is( $result->{success}, 1, "test host 'OpsviewRestAPI_test' deleted" );

    note( "Result from delete ", pp($result) );

    $ora_test->logout();
}

done_testing();
