
use Test::More tests => 7;
use HTTP::Response;

package API;

use Moose;
use Test::Mock::LWP::Dispatch;
extends 'NSMS::API';

package main;

my $sms = API->new(
    username => 'sppm',
    password => 'sppm0808',
    debug    => 0
);

$sms->ua->map( $sms->url_auth, HTTP::Response->new( '200', undef, undef, '{"sms":{"ok":1}}' ) );
ok( $sms->auth );

$sms->to('1183302233');
$sms->text('test');

$sms->ua->map( $sms->url_sendsms,
    HTTP::Response->new( '200', undef, undef, '{"sms":{"ok":"F2820346-8345-11E0-8747-45B8E5EB3B8E"}}' ) );

ok( $sms->send );

eval { $sms->to('asdfsfas') };
ok($@);
eval { $sms->to('+551193322332') };
ok($@);
eval { $sms->to('1188338833') };
is( $@, '' );
eval { $sms->text('teste de sms') };
is( $@, '' );
eval { $sms->text( 'x' x 150 ) };
ok($@);

