#!/usr/bin/perl
use Test::More tests => 6;
use Net::SMS::Massenversand;


my $foo = new Net::SMS::Massenversand;

$foo->test(1);
$foo->user('xxx');
is( $foo->user, 'xxx' );
$foo->password('xxx');
is( $foo->password, 'xxx' );
ok(
    !$foo->send(
        message  => "message",
        sender   => '00000',
        receiver => '00000'
    )
);

like( $foo->error, qr/access error/ );

ok( !$foo->limit );

like( $foo->error, qr/access error/ );
