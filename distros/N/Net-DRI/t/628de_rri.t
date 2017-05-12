#!/usr/bin/perl -w

use Net::DRI;
use Net::DRI::Data::Raw;

use Test::More tests => 77;

eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
*{'main::is_string'}=\&main::is if $@;

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="yes"?><registry-response xmlns="http://registry.denic.de/global/1.0" xmlns:tr="http://registry.denic.de/transaction/1.0" xmlns:domain="http://registry.denic.de/domain/1.0" xmlns:contact="http://registry.denic.de/contact/1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:dnsentry="http://registry.denic.de/dnsentry/1.0">';
our $E2='</registry-response>';
our $TRID='<tr:ctid>ABC-12345</tr:ctid><tr:stid>54322-XYZ</tr:stid>';

our $R1;
sub mysend
{
 my ($transport,$count,$msg)=@_;
 $R1=$msg->as_string();
 return 1;
}

our $R2;
sub myrecv
{
 return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<registry-response>'.r().$TRID.'</registry-response>'.$E2);
}

my $dri=Net::DRI::TrapExceptions->new(10);
$dri->{trid_factory}=sub { return 'ABC-12345'; };
$dri->add_registry('DENIC');
$dri->target('DENIC')->add_current_profile('p1','test=RRI',{f_send=>\&mysend,f_recv=>\&myrecv});

my $rc;
my $s;
my $d;
my ($dh,@c);

####################################################################################################
## Session Management
$R2 = $E1 . '<tr:transaction><tr:stid>' . $TRID .
	'</tr:stid><tr:result>success</tr:result></tr:transaction>' . $E2;

$rc = $dri->process('session', 'login', ['user','password']);
isa_ok($rc, 'Net::DRI::Protocol::ResultStatus');
is($rc->is_success(), 1, 'Login successful');
is($R1, '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><registry-request xmlns="http://registry.denic.de/global/1.0"><login><user>user</user><password>password</password></login><ctid>ABC-12345</ctid></registry-request>', 'Login XML correct');

####################################################################################################
## Contact Operations
$R2 = $E1 . '<tr:transaction><tr:stid>' . $TRID .
	'</tr:stid><tr:result>success</tr:result><tr:data><contact:checkData>' .
	'<contact:handle>DENIC-12345-BSP</contact:handle><contact:status>free' .
	'</contact:status></contact:checkData></tr:data></tr:transaction>' .
	$E2;

$rc = $dri->contact_check($dri->local_object('contact')->srid('DENIC-12345-BSP'));
isa_ok($rc, 'Net::DRI::Protocol::ResultStatus');
is(defined($rc) && $rc->is_success(), 1, 'Contact successfully checked');
is($R1, '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><registry-request xmlns="http://registry.denic.de/global/1.0" xmlns:contact="http://registry.denic.de/contact/1.0"><contact:check><contact:handle>DENIC-12345-BSP</contact:handle></contact:check></registry-request>', 'Check Contact XML correct');
is($dri->get_info('exist', 'contact', 'DENIC-12345-BSP'), 0, 'Contact does not exist');

$R2 = $E1 . '<tr:transaction><tr:stid>' . $TRID .
	'</tr:stid><tr:result>success</tr:result></tr:transaction>' . $E2;

my $c = $dri->local_object('contact');
$c->srid('DENIC-99990-10240-BSP');
$c->type('PERSON');
$c->name('Theobald Tester');
$c->org('Test-Org');
$c->street(['Kleiner Dienstweg 17']);
$c->pc('09538');
$c->city('Gipsnich');
$c->cc('DE');
$c->voice('+49.123456');
$c->fax('+49.123457');
$c->email('email@denic.de');
$c->sip('sip:benutzer@denic.de');

$rc = $dri->contact_create($c);
isa_ok($rc, 'Net::DRI::Protocol::ResultStatus');
is($rc->is_success(), 1, 'Contact successfully created');
is($R1, '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><registry-request xmlns="http://registry.denic.de/global/1.0" xmlns:contact="http://registry.denic.de/contact/1.0"><contact:create><contact:handle>DENIC-99990-10240-BSP</contact:handle><contact:type>PERSON</contact:type><contact:name>Theobald Tester</contact:name><contact:organisation>Test-Org</contact:organisation><contact:postal><contact:address>Kleiner Dienstweg 17</contact:address><contact:postalCode>09538</contact:postalCode><contact:city>Gipsnich</contact:city><contact:countryCode>DE</contact:countryCode></contact:postal><contact:phone>+49.123456</contact:phone><contact:fax>+49.123457</contact:fax><contact:email>email@denic.de</contact:email><contact:sip>sip:benutzer@denic.de</contact:sip></contact:create><ctid>ABC-12345</ctid></registry-request>', 'Create Contact XML correct');

my $todo = $dri->local_object('changes');
$todo->set('info', $c);

$rc = $dri->contact_update($c, $todo);
isa_ok($rc, 'Net::DRI::Protocol::ResultStatus');
is($rc->is_success(), 1, 'Contact successfully updated');
is($R1, '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><registry-request xmlns="http://registry.denic.de/global/1.0" xmlns:contact="http://registry.denic.de/contact/1.0"><contact:update><contact:handle>DENIC-99990-10240-BSP</contact:handle><contact:type>PERSON</contact:type><contact:name>Theobald Tester</contact:name><contact:organisation>Test-Org</contact:organisation><contact:postal><contact:address>Kleiner Dienstweg 17</contact:address><contact:postalCode>09538</contact:postalCode><contact:city>Gipsnich</contact:city><contact:countryCode>DE</contact:countryCode></contact:postal><contact:phone>+49.123456</contact:phone><contact:fax>+49.123457</contact:fax><contact:email>email@denic.de</contact:email><contact:sip>sip:benutzer@denic.de</contact:sip></contact:update><ctid>ABC-12345</ctid></registry-request>', 'Update Contact XML correct');

$R2 = $E1 . '<tr:transaction><tr:stid>' . $TRID .
	'</tr:stid><tr:result>success</tr:result><tr:data><contact:checkData><contact:handle>DENIC-99990-10240-BSP</contact:handle><contact:status>failed</contact:status></contact:checkData></tr:data></tr:transaction>' . $E2;

$rc = $dri->contact_check($c);
isa_ok($rc, 'Net::DRI::Protocol::ResultStatus');
is(defined($rc) && $rc->is_success(), 1, 'Contact successfully checked');
is($R1, '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><registry-request xmlns="http://registry.denic.de/global/1.0" xmlns:contact="http://registry.denic.de/contact/1.0"><contact:check><contact:handle>DENIC-99990-10240-BSP</contact:handle></contact:check></registry-request>', 'Check Contact XML correct');
is($dri->get_info('exist', 'contact', 'DENIC-99990-10240-BSP'), 1, 'Contact exists');

$R2 = $E1 . '<tr:transaction><tr:stid>' . $TRID .
	'</tr:stid><tr:result>success</tr:result><tr:data><contact:infoData>' .
	'<contact:handle>DENIC-99989-BSP</contact:handle>' .
	'<contact:type>ROLE</contact:type>' .
	'<contact:name>SyGroup GmbH</contact:name>' .
	'<contact:organisation>SyGroup GmbH</contact:organisation>' .
	'<contact:postal>' .
	'<contact:address>Gueterstrasse 86</contact:address>' .
	'<contact:city>Basel</contact:city>' .
	'<contact:postalCode>4053</contact:postalCode>' .
	'<contact:countryCode>CH</contact:countryCode>' .
	'</contact:postal>' .
	'<contact:phone>+41.613338033</contact:phone>' .
	'<contact:fax>+41.613831467</contact:fax>' .
	'<contact:email>info@sygroup.ch</contact:email>' .
	'<contact:sip>sip:secretary@sygroup.ch</contact:sip>' .
	'<contact:remarks>Live penguins in the office</contact:remarks>' .
	'<contact:changed>2007-05-23T22:55:33+02:00</contact:changed>' .
	'</contact:infoData></tr:data></tr:transaction>' . $E2;

$rc = $dri->contact_info($dri->local_object('contact')->srid('DENIC-99989-BSP'));
isa_ok($rc, 'Net::DRI::Protocol::ResultStatus');
is($rc->is_success(), 1, 'Contact successfully queried');
is($R1, '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><registry-request xmlns="http://registry.denic.de/global/1.0" xmlns:contact="http://registry.denic.de/contact/1.0"><contact:info><contact:handle>DENIC-99989-BSP</contact:handle></contact:info></registry-request>', 'Query Contact XML correct');


$c = $dri->get_info('self', 'contact', 'DENIC-99989-BSP');
isa_ok($c, 'Net::DRI::Data::Contact::DENIC');
is($c->name() . '|' . $c->org() . '|' . $c->sip() . '|' . $c->type(),
	'SyGroup GmbH|SyGroup GmbH|sip:secretary@sygroup.ch|ROLE',
	'Selected info from contact');

my $mod = $dri->get_info('upDate', 'contact', 'DENIC-99989-BSP');
isa_ok($mod, 'DateTime');
is($mod->ymd . 'T' . $mod->hms, '2007-05-23T22:55:33', 'Update Date');

$R2 = $E1 . '<tr:transaction><tr:stid>' . $TRID .
	'</tr:stid><tr:result>success</tr:result><tr:data><domain:checkData>' .
	'<domain:handle>rritestdomain.de</domain:handle><domain:ace>' .
	'rritestdomain.de</domain:ace><domain:status>free</domain:status>' .
	'</domain:checkData></tr:data></tr:transaction>' . $E2;

####################################################################################################

$rc = $dri->domain_check('rritestdomain.de');
isa_ok($rc, 'Net::DRI::Protocol::ResultStatus');

is($R1, '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><registry-request xmlns="http://registry.denic.de/global/1.0" xmlns:domain="http://registry.denic.de/domain/1.0"><domain:check><domain:handle>rritestdomain.de</domain:handle><domain:ace>rritestdomain.de</domain:ace></domain:check></registry-request>', 'Check Domain XML correct');

is($dri->get_info('exist', 'domain', 'rritestdomain.de'), 0, 'Domain does not exist');


$R2 = $E1 . '<tr:transaction><tr:stid>' . $TRID .
	'</tr:stid><tr:result>success</tr:result></tr:transaction>' . $E2;

$cs = $dri->local_object('contactset');

$cs->add($dri->local_object('contact')->srid('DENIC-99990-10240-BSP'), 'registrant');
$cs->add($dri->local_object('contact')->srid('DENIC-99990-10240-BSP1'), 'admin');
$cs->add($dri->local_object('contact')->srid('DENIC-99990-10240-BSP2'), 'tech');

$rc = $dri->domain_create('rritestdomain.de', {
	pure_create =>  1,
	contact =>	$cs,
	ns =>		$dri->local_object('hosts')->
	add('dns1.syhosting.ch',['193.219.115.46'])
	});
isa_ok($rc, 'Net::DRI::Protocol::ResultStatus');
is($rc->is_success(), 1, 'Domain successfully created');

is($R1, '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><registry-request xmlns="http://registry.denic.de/global/1.0" xmlns:domain="http://registry.denic.de/domain/1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:dnsentry="http://registry.denic.de/dnsentry/1.0"><domain:create><domain:handle>rritestdomain.de</domain:handle><domain:ace>rritestdomain.de</domain:ace><domain:contact role="admin-c">DENIC-99990-10240-BSP1</domain:contact><domain:contact role="holder">DENIC-99990-10240-BSP</domain:contact><domain:contact role="tech-c">DENIC-99990-10240-BSP2</domain:contact><dnsentry:dnsentry xsi:type="dnsentry:NS"><dnsentry:owner>rritestdomain.de.</dnsentry:owner><dnsentry:rdata><dnsentry:nameserver>dns1.syhosting.ch.</dnsentry:nameserver><dnsentry:address>193.219.115.46</dnsentry:address></dnsentry:rdata></dnsentry:dnsentry></domain:create><ctid>ABC-12345</ctid></registry-request>', 'Create Domain XML correct');

$R2 = $E1 . '<tr:transaction><tr:stid>' . $TRID .
	'</tr:stid><tr:result>success</tr:result><tr:data><domain:checkData><domain:handle>denic.de</domain:handle><domain:ace>denic.de</domain:ace><domain:status>connect</domain:status></domain:checkData></tr:data></tr:transaction>' . $E2;

$rc = $dri->domain_check('denic.de');
isa_ok($rc, 'Net::DRI::Protocol::ResultStatus');
is($rc->is_success(), 1, 'Domain successfully checked');

is($R1, '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><registry-request xmlns="http://registry.denic.de/global/1.0" xmlns:domain="http://registry.denic.de/domain/1.0"><domain:check><domain:handle>denic.de</domain:handle><domain:ace>denic.de</domain:ace></domain:check></registry-request>', 'Check Domain XML correct');

is($dri->get_info('exist', 'domain', 'denic.de'), 1, 'Domain exists');


$R2 = $E1 . '<tr:transaction><tr:stid>' . $TRID .
	'</tr:stid><tr:result>success</tr:result><tr:data><domain:infoData>' .
	'<domain:handle>rritestdomain.de</domain:handle>' .
	'<domain:ace>rritestdomain.de</domain:ace>' .
	'<domain:status>connect</domain:status>' .
	'<domain:regAccId>DENIC-1000006</domain:regAccId>' .
	'<domain:contact role="holder"><contact:handle>' .
	'DENIC-1000006-1</contact:handle></domain:contact>' .
	'<domain:contact role="holder"><contact:handle>' .
	'DENIC-1000006-2</contact:handle></domain:contact>' .
	'<domain:contact role="admin-c"><contact:handle>' .
	'DENIC-1000006-SD</contact:handle></domain:contact>' .
	'<domain:contact role="tech-c"><contact:handle>' .
	'DENIC-1000006-OPS</contact:handle></domain:contact>' .
	'<domain:contact role="zone-c"><contact:handle>' .
	'DENIC-1000006-OPS</contact:handle></domain:contact>' .
	'<dnsentry:dnsentry xsi:type="dnsentry:NS">' .
	'<dnsentry:owner>rritestdomain.de</dnsentry:owner>' .
	'<dnsentry:rdata><dnsentry:nameserver>dns1.rritestdomain.de' .
	'</dnsentry:nameserver><dnsentry:address>194.25.2.129' .
	'</dnsentry:address><dnsentry:address>' .
	'2001:4d88:ffff:ffff:2:b345:af62:2</dnsentry:address>' .
	'</dnsentry:rdata></dnsentry:dnsentry>' .
	'<domain:changed>2001-09-11T11:45:23-07:00</domain:changed>' .
	'</domain:infoData></tr:data></tr:transaction>' . $E2;

$rc = $dri->domain_info('rritestdomain.de');
isa_ok($rc, 'Net::DRI::Protocol::ResultStatus');
is($rc->is_success(), 1, 'Domain successfully queried');
is($R1, '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><registry-request xmlns="http://registry.denic.de/global/1.0" xmlns:domain="http://registry.denic.de/domain/1.0"><domain:info recursive="false" withProvider="true"><domain:handle>rritestdomain.de</domain:handle><domain:ace>rritestdomain.de</domain:ace></domain:info></registry-request>', 'Query Domain XML correct');

$mod = $dri->get_info('upDate', 'domain', 'rritestdomain.de');
isa_ok($mod, 'DateTime');
is($mod->ymd . 'T' . $mod->hms, '2001-09-11T11:45:23', 'Update Date');
is($dri->get_info('contact', 'domain', 'rritestdomain.de')->
	get('registrant')->srid(), 'DENIC-1000006-1',
	'Random contact is correct');
my $ns = $dri->get_info('ns', 'domain', 'rritestdomain.de');
is(join(',', $ns->get_names()), 'dns1.rritestdomain.de', 'Name server records');
is(join(',', map { my ($name, $v4, $v6) = $ns->get_details($_); $v4->[0] }
	$ns->get_names()), '194.25.2.129', 'Name server v4 IPs');
is(join(',', map { my ($name, $v4, $v6) = $ns->get_details($_); $v6->[0] }
	$ns->get_names()), '2001:4d88:ffff:ffff:2:b345:af62:2',
	'Name server v6 IPs');

$R2 = $E1 . '<tr:transaction><tr:stid>' . $TRID .
	'</tr:stid><tr:result>success</tr:result><tr:data><domain:infoData>' .
	'<domain:handle>rritestdomain2.de</domain:handle>' .
	'<domain:ace>rritestdomain2.de</domain:ace>' .
	'<domain:status>connect</domain:status>' .
	'<domain:regAccId>DENIC-1000006</domain:regAccId>' .
	'<domain:contact role="holder"><contact:handle>' .
	'DENIC-1000006-1</contact:handle></domain:contact>' .
	'<domain:contact role="holder"><contact:handle>' .
	'DENIC-1000006-2</contact:handle></domain:contact>' .
	'<domain:contact role="admin-c"><contact:handle>' .
	'DENIC-1000006-SD</contact:handle></domain:contact>' .
	'<domain:contact role="tech-c"><contact:handle>' .
	'DENIC-1000006-OPS</contact:handle></domain:contact>' .
	'<domain:contact role="zone-c"><contact:handle>' .
	'DENIC-1000006-OPS</contact:handle></domain:contact>' .
	'<dnsentry:dnsentry xsi:type="dnsentry:NS">' .
	'<dnsentry:owner>rritestdomain2.de</dnsentry:owner>' .
	'<dnsentry:rdata><dnsentry:nameserver>dns1.rritestdomain2.de' .
	'</dnsentry:nameserver><dnsentry:address>194.25.2.129' .
	'</dnsentry:address><dnsentry:address>' .
	'2001:4d88:ffff:ffff:2:b345:af62:2</dnsentry:address>' .
	'</dnsentry:rdata></dnsentry:dnsentry>' .
	'<domain:chprovData><domain:chprovTo>DENIC-1000002</domain:chprovTo>' .
	'<domain:chprovStart>2005-11-20T00:00:00+01:00</domain:chprovStart>' .
	'<domain:chprovReminder>2005-11-23T00:00:00+01:00' .
	'</domain:chprovReminder><domain:chprovEnd>2005-11-25T00:00:00+01:00' .
	'</domain:chprovEnd><domain:chprovStatus>ACTIVE' .
	'</domain:chprovStatus></domain:chprovData>' .
	'<domain:changed>2001-09-11T11:45:23-07:00</domain:changed>' .
	'</domain:infoData></tr:data></tr:transaction>' . $E2;

$rc = $dri->domain_transfer_query('rritestdomain2.de');
isa_ok($rc, 'Net::DRI::Protocol::ResultStatus');
is($rc->is_success(), 1, 'Domain successfully transferred');
is($dri->get_info('trStatus', 'domain', 'rritestdomain2.de'), 'pending',
	'Transfer status set correctly');
$mod = $dri->get_info('reDate', 'domain', 'rritestdomain2.de');
is($mod->ymd . 'T' . $mod->hms, '2005-11-20T00:00:00', 'Update Date');

is($R1, '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><registry-request xmlns="http://registry.denic.de/global/1.0" xmlns:domain="http://registry.denic.de/domain/1.0"><domain:info recursive="true" withProvider="false"><domain:handle>rritestdomain2.de</domain:handle><domain:ace>rritestdomain2.de</domain:ace></domain:info><ctid>ABC-12345</ctid></registry-request>', 'Accept Transfer XML correct');

$R2 = $E1 . '<tr:transaction><tr:stid>' . $TRID .
	'</tr:stid><tr:result>success</tr:result></tr:transaction>' . $E2;

$rc = $dri->domain_transfer_start('sygroup.de', {
	contact =>	$cs,
	ns =>		$dri->local_object('hosts')->
		add('dns1.syhosting.ch',['193.219.115.46'])
});
isa_ok($rc, 'Net::DRI::Protocol::ResultStatus');
is($rc->is_success(), 1, 'Domain successfully transferred');

is($R1, '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><registry-request xmlns="http://registry.denic.de/global/1.0" xmlns:domain="http://registry.denic.de/domain/1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:dnsentry="http://registry.denic.de/dnsentry/1.0"><domain:chprov><domain:handle>sygroup.de</domain:handle><domain:ace>sygroup.de</domain:ace><domain:contact role="admin-c">DENIC-99990-10240-BSP1</domain:contact><domain:contact role="holder">DENIC-99990-10240-BSP</domain:contact><domain:contact role="tech-c">DENIC-99990-10240-BSP2</domain:contact><dnsentry:dnsentry xsi:type="dnsentry:NS"><dnsentry:owner>sygroup.de.</dnsentry:owner><dnsentry:rdata><dnsentry:nameserver>dns1.syhosting.ch.</dnsentry:nameserver><dnsentry:address>193.219.115.46</dnsentry:address></dnsentry:rdata></dnsentry:dnsentry></domain:chprov><ctid>ABC-12345</ctid></registry-request>', 'Transfer Domain XML correct');

$rc = $dri->domain_transfer_refuse('rritestdomain.de');
isa_ok($rc, 'Net::DRI::Protocol::ResultStatus');
is($rc->is_success(), 1, 'Domain transfer successfully refused');

is($R1, '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><registry-request xmlns="http://registry.denic.de/global/1.0" xmlns:domain="http://registry.denic.de/domain/1.0"><domain:chprovNack><domain:handle>rritestdomain.de</domain:handle><domain:ace>rritestdomain.de</domain:ace></domain:chprovNack><ctid>ABC-12345</ctid></registry-request>', 'Refuse Transfer XML correct');

$rc = $dri->domain_transfer_accept('rritestdomain2.de');
isa_ok($rc, 'Net::DRI::Protocol::ResultStatus');
is($rc->is_success(), 1, 'Domain transfer successfully approved');

is($R1, '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><registry-request xmlns="http://registry.denic.de/global/1.0" xmlns:domain="http://registry.denic.de/domain/1.0"><domain:chprovAck><domain:handle>rritestdomain2.de</domain:handle><domain:ace>rritestdomain2.de</domain:ace></domain:chprovAck><ctid>ABC-12345</ctid></registry-request>', 'Accept Transfer XML correct');

$rc = $dri->domain_delete('rritestdomain3.de', {
	contact =>	$cs
});
isa_ok($rc, 'Net::DRI::Protocol::ResultStatus');
is($rc->is_success(), 1, 'Domain successfully deleted');

is($R1, '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><registry-request xmlns="http://registry.denic.de/global/1.0" xmlns:domain="http://registry.denic.de/domain/1.0"><domain:delete><domain:handle>rritestdomain3.de</domain:handle><domain:ace>rritestdomain3.de</domain:ace><domain:contact role="holder">DENIC-99990-10240-BSP</domain:contact></domain:delete><ctid>ABC-12345</ctid></registry-request>', 'Delete Domain XML correct');

$cs = $dri->local_object('contactset');
$cs->add($dri->local_object('contact')->srid('DENIC-99990-10240-BSP5'), 'registrant');

$rc = $dri->domain_trade('rritestdomain2.de', {
	contact =>	$cs
});
isa_ok($rc, 'Net::DRI::Protocol::ResultStatus');
is($rc->is_success(), 1, 'Domain successfully traded');

is($R1, '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><registry-request xmlns="http://registry.denic.de/global/1.0" xmlns:domain="http://registry.denic.de/domain/1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:dnsentry="http://registry.denic.de/dnsentry/1.0"><domain:chholder><domain:handle>rritestdomain2.de</domain:handle><domain:ace>rritestdomain2.de</domain:ace><domain:contact role="holder">DENIC-99990-10240-BSP5</domain:contact></domain:chholder><ctid>ABC-12345</ctid></registry-request>', 'Trade Domain XML correct');

# Pre-cache info
$R2 = $E1 . '<tr:transaction><tr:stid>' . $TRID .
	'</tr:stid><tr:result>success</tr:result><tr:data><domain:infoData>' .
	'<domain:handle>rritestdomain.de</domain:handle>' .
	'<domain:ace>rritestdomain.de</domain:ace>' .
	'<domain:status>connect</domain:status>' .
	'<domain:regAccId>DENIC-1000006</domain:regAccId>' .
	'<domain:contact role="holder"><contact:handle>' .
	'DENIC-1000006-1</contact:handle></domain:contact>' .
	'<domain:contact role="holder"><contact:handle>' .
	'DENIC-1000006-2</contact:handle></domain:contact>' .
	'<domain:contact role="admin-c"><contact:handle>' .
	'DENIC-1000006-SD</contact:handle></domain:contact>' .
	'<domain:contact role="tech-c"><contact:handle>' .
	'DENIC-1000006-OPS</contact:handle></domain:contact>' .
	'<domain:contact role="zone-c"><contact:handle>' .
	'DENIC-1000006-OPS</contact:handle></domain:contact>' .
	'<dnsentry:dnsentry xsi:type="dnsentry:NS">' .
	'<dnsentry:owner>rritestdomain.de</dnsentry:owner>' .
	'<dnsentry:rdata><dnsentry:nameserver>dns1.rritestdomain.de' .
	'</dnsentry:nameserver><dnsentry:address>194.25.2.129' .
	'</dnsentry:address><dnsentry:address>' .
	'2001:4d88:ffff:ffff:2:b345:af62:2</dnsentry:address>' .
	'</dnsentry:rdata></dnsentry:dnsentry>' .
	'<domain:changed>2001-09-11T11:45:23-07:00</domain:changed>' .
	'</domain:infoData></tr:data></tr:transaction>' . $E2;

$rc = $dri->domain_info('rritestdomain.de');
$R2 = $E1 . '<tr:transaction><tr:stid>' . $TRID .
	'</tr:stid><tr:result>success</tr:result></tr:transaction>' . $E2;

my $changes = $dri->local_object('changes');
$cs = $dri->local_object('contactset');
$cs->add($dri->local_object('contact')->srid('ALFRED-RIPE'), 'tech');
$changes->add('contact', $cs);
$cs = $dri->local_object('contactset');
$cs->add($dri->local_object('contact')->srid('DENIC-1000006-OPS'), 'tech');
$changes->del('contact', $cs);
$changes->add('ns', $dri->local_object('hosts')->add('dns1.syhosting.ch',
	['193.219.115.46']));
$changes->del('ns', $dri->local_object('hosts')->add('dns1.rritestdomain.de'));

$rc = $dri->domain_update('rritestdomain.de', $changes);
isa_ok($rc, 'Net::DRI::Protocol::ResultStatus');
is($rc->is_success(), 1, 'Domain successfully updated');
is($R1, '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><registry-request xmlns="http://registry.denic.de/global/1.0" xmlns:domain="http://registry.denic.de/domain/1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:dnsentry="http://registry.denic.de/dnsentry/1.0"><domain:update><domain:handle>rritestdomain.de</domain:handle><domain:ace>rritestdomain.de</domain:ace><domain:contact role="admin-c">DENIC-1000006-SD</domain:contact><domain:contact role="holder">DENIC-1000006-1</domain:contact><domain:contact role="holder">DENIC-1000006-2</domain:contact><domain:contact role="tech-c">ALFRED-RIPE</domain:contact><domain:contact role="zone-c">DENIC-1000006-OPS</domain:contact><dnsentry:dnsentry xsi:type="dnsentry:NS"><dnsentry:owner>rritestdomain.de.</dnsentry:owner><dnsentry:rdata><dnsentry:nameserver>dns1.syhosting.ch.</dnsentry:nameserver><dnsentry:address>193.219.115.46</dnsentry:address></dnsentry:rdata></dnsentry:dnsentry></domain:update><ctid>ABC-12345</ctid></registry-request>', 'Update Domain XML correct');

####################################################################################################

$R2 = $E1 . '<tr:transaction><tr:stid>' . $TRID .
	'</tr:stid><tr:result>success</tr:result><tr:data><msg:message xmlns:msg="http://registry.denic.de/msg/1.0" msgid="423" msgcnt="42" msgtime="2007-12-27T14:52:13+02:00"><msg:chprovStart><msg:domain><msg:handle>blafasel.de</msg:handle><msg:ace>blafasel.de</msg:ace></msg:domain><msg:new>DENIC eG</msg:new><msg:old>RoedelDoedelCorp</msg:old><msg:start>2007-12-27T14:52:13+02:00</msg:start><msg:reminder>2007-12-31T14:52:13+02:00</msg:reminder><msg:end>2008-01-02T14:52:13+02:00</msg:end></msg:chprovStart></msg:message></tr:data></tr:transaction>' . $E2;

$rc = $dri->message_retrieve();
isa_ok($rc, 'Net::DRI::Protocol::ResultStatus');
is($rc->is_success(), 1, 'Message successfully deleted');
my $msgid = $dri->get_info('last_id', 'message', 'session');
is($msgid, 423, 'Message ID parsed successfully');
is($dri->get_info('id', 'message', $msgid), $msgid, 'Message ID correct');
is($dri->get_info('action', 'message', $msgid), 'chprov', 'Message type correct');
is($dri->get_info('objid', 'message', $msgid), 'blafasel.de', 'Message domain correct');
$mod = $dri->get_info('qdate', 'message', $msgid);
is($mod->ymd . 'T' . $mod->hms, '2007-12-27T14:52:13', 'Update Date');

is($R1, '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><registry-request xmlns="http://registry.denic.de/global/1.0" xmlns:msg="http://registry.denic.de/msg/1.0"><msg:queue-read/></registry-request>', 'Retrieve Message XML correct');

$R2 = $E1 . '<tr:transaction><tr:stid>' . $TRID .
	'</tr:stid><tr:result>success</tr:result></tr:transaction>' . $E2;

$rc = $dri->message_delete($msgid);
isa_ok($rc, 'Net::DRI::Protocol::ResultStatus');
is($rc->is_success(), 1, 'Message successfully deleted');
is($R1, '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><registry-request xmlns="http://registry.denic.de/global/1.0" xmlns:msg="http://registry.denic.de/msg/1.0"><msg:delete msgid="423"/><ctid>ABC-12345</ctid></registry-request>', 'Delete Message XML correct');

####################################################################################################
exit(0);

sub r
{
 my ($c,$m)=@_;
 return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>';
}
