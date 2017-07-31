#!perl
use Test::More tests => 12;
use warnings;
use strict;

use Test::Mock::Simple;
use Test::Mock::LWP::Dispatch;
use HTTP::Response;

BEGIN { use_ok('Net::Fritz::Box') };


### public tests

subtest 'check new()' => sub {
    # given

    # when
    my $box = new_ok( 'Net::Fritz::Box' );

    # then
    is( $box->error,       '',                        'Net::Fritz::Box->error'       );
    is( $box->upnp_url,    'https://fritz.box:49443', 'Net::Fritz::Box->upnp_url'    );
    is( $box->trdesc_path, '/tr64desc.xml',           'Net::Fritz::Box->trdesc_path' );
    is( $box->username,    undef,                     'Net::Fritz::Box->username'    );
    is( $box->password,    undef,                     'Net::Fritz::Box->password'    );
    is( $box->configfile,  undef,                     'Net::Fritz::Box->configfile'  );
};

subtest 'check new() with parameters' => sub {
    # given

    # when
    my $box = new_ok( 'Net::Fritz::Box',
		      [ upnp_url    => 'U1',
			trdesc_path => 'T2',
			username    => 'U3',
			password    => 'P4'
		      ]
	);

    # then
    is( $box->error,       '',   'Net::Fritz::Box->error'       );
    is( $box->upnp_url,    'U1', 'Net::Fritz::Box->upnp_url'    );
    is( $box->trdesc_path, 'T2', 'Net::Fritz::Box->trdesc_path' );
    is( $box->username,    'U3', 'Net::Fritz::Box->username'    );
    is( $box->password,    'P4', 'Net::Fritz::Box->password'    );
};

subtest 'new() reads from configfile' => sub {
    # given

    # when
    my $box = new_ok( 'Net::Fritz::Box',
		      [ configfile  => 't/config.file'
		      ]
	);

    # then
    is( $box->error,       '',              'Net::Fritz::Box->error'       );
    is( $box->upnp_url,    'UPNP',          'Net::Fritz::Box->upnp_url'    );
    is( $box->trdesc_path, 'TRDESC',        'Net::Fritz::Box->trdesc_path' );
    is( $box->username,    'USER',          'Net::Fritz::Box->username'    );
    is( $box->password,    'PASS',          'Net::Fritz::Box->password'    );
    is( $box->configfile,  't/config.file', 'Net::Fritz::Box->configfile'  );
};

subtest 'empty configfile does not overwrite defaults' => sub {
    # given

    # when
    my $box = new_ok( 'Net::Fritz::Box',
		      [ configfile  => 't/empty.file'
		      ]
	);

    # then
    is( $box->error,       '',                        'Net::Fritz::Box->error'       );
    is( $box->upnp_url,    'https://fritz.box:49443', 'Net::Fritz::Box->upnp_url'    );
    is( $box->trdesc_path, '/tr64desc.xml',           'Net::Fritz::Box->trdesc_path' );
    is( $box->username,    undef,                     'Net::Fritz::Box->username'    );
    is( $box->password,    undef,                     'Net::Fritz::Box->password'    );
    is( $box->configfile,  't/empty.file',            'Net::Fritz::Box->configfile'  );
};

subtest 'new() parameters overwrite configfile values' => sub {
    # given

    # when
    my $box = new_ok( 'Net::Fritz::Box',
		      [ upnp_url    => 'U1',
			trdesc_path => 'T2',
			username    => 'U3',
			password    => 'P4',
			configfile  => 't/config.file'
		      ]
	);

    # then
    is( $box->error,       '',              'Net::Fritz::Box->error'       );
    is( $box->upnp_url,    'U1',            'Net::Fritz::Box->upnp_url'    );
    is( $box->trdesc_path, 'T2',            'Net::Fritz::Box->trdesc_path' );
    is( $box->username,    'U3',            'Net::Fritz::Box->username'    );
    is( $box->password,    'P4',            'Net::Fritz::Box->password'    );
    is( $box->configfile,  't/config.file', 'Net::Fritz::Box->configfile'  );
};

subtest 'check discover() without Fritz!Box present' => sub {
    # given
    my $box = new_ok( 'Net::Fritz::Box' );

    # when
    my $discovery = $box->discover();

    # then
    isa_ok( $discovery, 'Net::Fritz::Error' , 'failed discovery' );
};

subtest 'check discover() with mocked Fritz!Box' => sub {
    # given
    my $box = new_ok( 'Net::Fritz::Box' );
    $box->_ua->map('https://fritz.box:49443/tr64desc.xml', get_fake_device_response());

    # when
    my $discovery = $box->discover();

    # then
    isa_ok( $discovery, 'Net::Fritz::Device' , 'mocked discovery' );
};

subtest 'check discover() with mocked Net::Fritz!Box at non-standard URL' => sub {
    # given
    my $box = new_ok( 'Net::Fritz::Box',
		   [ upnp_url    => 'http://example.org:123',
		     trdesc_path => '/tr64'
		   ]
	);
    $box->_ua->map('http://example.org:123/tr64', get_fake_device_response());

    # when
    my $discovery = $box->discover();

    # then
    isa_ok( $discovery, 'Net::Fritz::Device' , 'mocked discovery' );
};


### internal tests

subtest 'check _sslopts' => sub {
    # given
    my $box = new_ok( 'Net::Fritz::Box' );

    # when
    my %box_sslopts = @{$box->_sslopts};

    # then
    is_deeply( [ sort keys %box_sslopts ], [ sort $box->_ua->ssl_opts ], 'SSL option keys' );
};

subtest 'check dump_without_indent()' => sub {
    # given
    my $box = new_ok( 'Net::Fritz::Box' );

    # when
    my $dump = $box->dump();

    # then
    foreach my $line (split /\n/, $dump) {
	like( $line, qr/^(Net::Fritz|  )/, 'line starts as expected' );
    }

    like( $dump, qr/Net::Fritz::Box/, 'class name is dumped' );

    my $upnp_url = $box->upnp_url;
    like( $dump, qr/$upnp_url/, 'upnp_url is dumped' );
    my $trdesc_path = $box->trdesc_path;
    like( $dump, qr/$trdesc_path/, 'trdesc_path is dumped' );
};

subtest 'check dump_with_indent()' => sub {
    # given
    my $box = new_ok( 'Net::Fritz::Box' );

    # when
    my $dump = $box->dump('xxx');

    # then
    foreach my $line (split /\n/, $dump) {
	like( $line, qr/^xxx/, 'line starts with given indent' );
    }
};


### helper methods

sub get_fake_device_response
{
    my $xml = get_tr64desc_xml();

    my $result = HTTP::Response->new( 200 );
    $result->content( $xml );
    return $result;
}

sub get_tr64desc_xml
{
    my $tr64_desc_xml = <<EOF;
<?xml version="1.0"?>
<root xmlns="urn:dslforum-org:device-1-0">
  <device>
    <deviceType>FakeDevice:1</deviceType>
    <friendlyName>UnitTest Unit</friendlyName>
    <manufacturer>fake</manufacturer>
    <manufacturerURL>http://example.org/1</manufacturerURL>
    <modelDescription>fake model description</modelDescription>
    <modelName>fake model name</modelName>
    <modelNumber>fake model number</modelNumber>
    <modelURL>http://example.org/2</modelURL>
    <UDN>uuid:1</UDN>
    <serviceList>
      <service>
	<serviceType>FakeService:1</serviceType>
	<serviceId>fakeService1</serviceId>
	<controlURL>/upnp/control/deviceinfo</controlURL>
	<eventSubURL>/upnp/control/deviceinfo</eventSubURL>
	<SCPDURL>fakeSCPD.xml</SCPDURL>
      </service>
    </serviceList>
    <deviceList>
      <device>
	<deviceType>FakeSubDevice:1</deviceType>
	<friendlyName>UnitTest Unit Subdevice</friendlyName>
	<manufacturer>fake</manufacturer>
	<manufacturerURL>http://example.org/3</manufacturerURL>
	<modelDescription>fake model description - subdevice</modelDescription>
	<modelName>fake model name - subdevice</modelName>
	<modelNumber>fake model number - subdevice</modelNumber>
	<modelURL>http://example.org/4</modelURL>
	<UDN>uuid:2</UDN>
	<serviceList>
	  <service>
	    <serviceType>FakeService:1</serviceType>
	    <serviceId>fakeService2</serviceId>
	    <controlURL>/upnp/control/deviceinfo</controlURL>
	    <eventSubURL>/upnp/control/deviceinfo</eventSubURL>
	    <SCPDURL>fakeSCPD.xml</SCPDURL>
	  </service>
	</serviceList>
      </device>
    </deviceList>
    <presentationURL>http://localhost</presentationURL>
  </device>
</root>
EOF
    ;
}
