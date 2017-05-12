#!/usr/bin/perl
use Net::ASN qw(:all);
use Test::More tests =>74;

##OO tests
print "Starting OO Tests..\n";

ok(	$asn16 = Net::ASN->new(12345)	,			'asn16 parsing'		);
ok(	defined($asn16)			,			'asn16 defined'		);
ok(	$asn16->isa('Net::ASN')		,			'asn16 correct class'	);
is(	$asn16->gettype			,	'asplain'	,'asn16 type test'	);
is(	$asn16->toasplain		,	12345		,'asn16 asplain test'	);
is(	$asn16->toasdot			,	12345		,'asn16 asdot test'	);
is(	$asn16->toasdotplus		,	'0.12345'	,'asn16 asdotplus test'	);

ok(	$asn32 = Net::ASN->new(65536)	,			'asn32 parsing'		);
ok(	defined($asn32)			,			'asn32 defined'		);
ok(	$asn32->isa('Net::ASN')         ,                       'asn32 correct class'	);
is(	$asn32->gettype			,	'asplain'	,'asn32 type test'	);
is(     $asn32->toasplain16             ,       23456           ,'asn32 asplain16 test' );
is(     $asn32->toasplain               ,       65536           ,'asn32 asplain test'   );
is(     $asn32->toasdot                 ,       '1.0'           ,'asn32 asdot test'     );
is(     $asn32->toasdotplus             ,       '1.0'       	,'asn32 asdotplus test' );

ok(     $asn32 = Net::ASN->new('0.9')   ,                       'asn32 parsing'         );
ok(     defined($asn32)                 ,                       'asn32 defined'         );
ok(     $asn32->isa('Net::ASN')         ,                       'asn32 correct class'   );
is(	$asn32->gettype			,	'asdotplus'	,'asn32 type test'	);
is(     $asn32->toasplain16             ,       9	        ,'asn32 asplain16 test' );
is(     $asn32->toasplain               ,       9	        ,'asn32 asplain test'   );
is(     $asn32->toasdot                 ,       9               ,'asn32 asdot test'     );
is(     $asn32->toasdotplus             ,       '0.9'           ,'asn32 asdotplus test' );

ok(     $asn32 = Net::ASN->new('1.1')   ,                       'asn32 parsing'         );
ok(     defined($asn32)                 ,                       'asn32 defined'         );
ok(     $asn32->isa('Net::ASN')         ,                       'asn32 correct class'   );
is(	$asn32->gettype			,	'asdotplus'	,'asn32 type test'	);
is(     $asn32->toasplain16             ,       23456           ,'asn32 asplain16 test' );
is(     $asn32->toasplain               ,       65537           ,'asn32 asplain test'   );
is(     $asn32->toasdot                 ,       '1.1'           ,'asn32 asdot test'     );
is(     $asn32->toasdotplus             ,       '1.1'           ,'asn32 asdotplus test' );

#Test ASDOT forcing
ok(     $asn16 = Net::ASN->new(12345,1) ,                       'asn16 parsing as ASDOT'         );
ok(     defined($asn16)                 ,                       'asn16 defined'         );
ok(     $asn16->isa('Net::ASN')         ,                       'asn16 correct class'   );
is(     $asn16->gettype                 ,       'asdot'         ,'asn16 type test'      );
is(     $asn16->toasplain               ,       12345           ,'asn16 asplain test'   );
is(     $asn16->toasdot                 ,       12345           ,'asn16 asdot test'     );
is(     $asn16->toasdotplus             ,       '0.12345'       ,'asn16 asdotplus test' );

ok(     $asn32 = Net::ASN->new('1.1',1) ,                       'asn32 parsing as ASDOT'         );
ok(     defined($asn32)                 ,                       'asn32 defined'         );
ok(     $asn32->isa('Net::ASN')         ,                       'asn32 correct class'   );
is(     $asn32->gettype                 ,       'asdot'         ,'asn32 type test'      );
is(     $asn32->toasplain16             ,       23456           ,'asn32 asplain16 test' );
is(     $asn32->toasplain               ,       65537           ,'asn32 asplain test'   );
is(     $asn32->toasdot                 ,       '1.1'           ,'asn32 asdot test'     );
is(     $asn32->toasdotplus             ,       '1.1'           ,'asn32 asdotplus test' );

ok(     $private_asn16 = Net::ASN->new(64512) ,                 'private 16 bit ASN'    );
is(     $private_asn16->isprivate      ,       1               ,'16 bit ASN corrected marked as private' );
ok(     $private_asn32 = Net::ASN->new(4200000000) ,            'private 32 bit ASN'    );
is(     $private_asn32->isprivate      ,       1               ,'32 bit ASN corrected marked as private' );

ok(     $public_asn16 = Net::ASN->new(64511) ,                 'public 16 bit ASN'    );
is(     $public_asn16->isprivate      ,       0               ,'16 bit ASN corrected marked as private' );
ok(     $public_asn32 = Net::ASN->new(4199999999) ,            'public 32 bit ASN'    );
is(     $public_asn32->isprivate      ,       0               ,'32 bit ASN corrected marked as private' );

##Non-OO Tests
print "Starting non-OO tests..\n";

is(	plaintodot(12345)		,	12345		,'plaintodot(1)'	);
is(	plaintodot(65536)		,	'1.0'		,'plaintodot(2)'	);
is(	plaintodotplus(12345)		,	'0.12345'	,'plaintodotplus(1)'	);
is(	plaintodotplus(65536)		,	'1.0'		,'plaintodotplus(2)'	);
is(	dotplustodot('0.12345')		,	12345		,'dotplustodot(1)'	);
is(	dotplustodot('1.0')		,	'1.0'		,'dotplustodot(2)'	);
is(	dotplustoplain('0.12345')	,	12345		,'dotplustoplain(1)'	);
is(	dotplustoplain('1.0')		,	65536		,'dotplustoplain(2)'	);
is(	dotplustoplain16('0.12345')	,	12345		,'dotplustoplain16(1)'	);
is(	dotplustoplain16('1.0')		,	23456		,'dotplustoplain16(2)'	);
is(     dottodotplus('12345')         	,       '0.12345'       ,'dottodotplus(1)'      );
is(     dottodotplus('1.0')             ,       '1.0'           ,'dottodotplus(2)'      );
is(     dottoplain('12345')       	,       12345           ,'dottoplain(1)'    	);
is(     dottoplain('1.0')           	,       65536           ,'dottoplain(2)'    	);
is(     dottoplain16('12345')     	,       12345           ,'dottoplain16(1)'  	);
is(     dottoplain16('1.0')         	,       23456           ,'dottoplain16(2)'  	);

is( isprivateasn(64512)     , 1, 'isprivateasn reports private for 16 bit ASN' );
is( isprivateasn(4200000000), 1, 'isprivateasn reports private for 32 bit ASN' );
is( isprivateasn(64511)     , 0, 'isprivateasn reports public for 16 bit ASN'  );
is( isprivateasn(4199999999), 0, 'isprivateasn reports public for 32 bit ASN'  );
