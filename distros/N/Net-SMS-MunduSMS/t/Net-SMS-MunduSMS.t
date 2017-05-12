use Test::More;

plan tests => 6;

use_ok('Net::SMS::MunduSMS');
require_ok('Net::SMS::MunduSMS');

use Net::SMS::MunduSMS;
my $ms = Net::SMS::MunduSMS->new( username => '919988445566', password => 'passme' );

isa_ok( $ms, 'Net::SMS::MunduSMS' );
ok( $ms->can('add_sms'),  'Has method add_sms' );
ok( $ms->can('send_sms'), 'Has method send_sms' );
ok( !$ms->_login, 'Works OK, did not login' );
