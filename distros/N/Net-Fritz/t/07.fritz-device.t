#!perl
use Test::More tests => 20;
use warnings;
use strict;

use Net::Fritz::Box;

BEGIN { use_ok('Net::Fritz::Device') };


### public tests

subtest 'check fritz getter, set via new()' => sub {
    # given
    my $fritz = Net::Fritz::Box->new();
    my $device = new_ok( 'Net::Fritz::Device', [ fritz => $fritz, xmltree => undef ] );

    # when
    my $result = $device->fritz;

    # then
    is( $result, $fritz, 'get fritz' );
};

subtest 'check xmltree getter, set via new()' => sub {
    # given
    my $xmltree = [ some => 'thing' ];
    my $device = new_ok( 'Net::Fritz::Device', [ fritz => undef, xmltree => $xmltree ] );

    # when
    my $result = $device->xmltree;

    # then
    is( $result, $xmltree, 'get xmltree' );
};

subtest 'check service_list getter and converter' => sub {
    # given
    my $fritz = Net::Fritz::Box->new();
    my $xmltree = {
	'serviceList' => [
	    { 'service' => [
		  'FAKE_SERVICE_0',
		  'FAKE_SERVICE_1'
		  ]
	    }
	    ]
    };
    my $device = new_ok( 'Net::Fritz::Device', [ fritz => $fritz, xmltree => $xmltree ] );

    # when
    my $result = $device->service_list;

    # then
    is( ref $device->service_list, 'ARRAY', 'service_list yields arrayref'  );
    my @service_list = @{$device->service_list};
    is( scalar @service_list, 2, 'service_list length' );
    foreach my $i ( 0, 1 ) {
	my $service = $service_list[$i];
	isa_ok( $service, 'Net::Fritz::Service', "service_list[$i]" );
	is( $service->fritz, $fritz, "service_list[$i]->fritz" );
	is( $service->xmltree, "FAKE_SERVICE_$i", "service_list[$i]->xmltree" );
    }

    is( scalar @{$device->device_list}, 0, 'device_list is empty' );
};

subtest 'check device_list getter and converter' => sub {
    # given
    my $fritz = Net::Fritz::Box->new();
    my $xmltree = {
	'deviceList' => [
	    { 'device' => [
		  'FAKE_SUBDEVICE_0',
		  'FAKE_SUBDEVICE_1'
		  ]
	    }
	    ]
    };
    my $device = new_ok( 'Net::Fritz::Device', [ fritz => $fritz, xmltree => $xmltree ] );

    # when
    my $result = $device->device_list;

    # then
    is( ref $device->device_list, 'ARRAY', 'device_list yields arrayref'  );
    my @device_list = @{$device->device_list};
    is( scalar @device_list, 2, 'device_list length' );
    foreach my $i ( 0, 1 ) {
	my $device = $device_list[$i];
	isa_ok( $device, 'Net::Fritz::Device', "device_list[$i]" );
	is( $device->fritz, $fritz, "device_list[$i]->fritz" );
	is( $device->xmltree, "FAKE_SUBDEVICE_$i", "device_list[$i]->xmltree" );
    }

    is( scalar @{$device->service_list}, 0, 'service_list is empty' );
};

subtest 'check attribute getters' => sub {
    # given
    my $xmltree = {
	'deviceType' => [ 'DEV_TYPE' ],
	'friendlyName' => [ 'F_NAME' ],
	'manufacturer' => [ 'MAN' ],
	'manufacturerURL' => [ 'MAN_URL' ],
	'modelDescription' => [ 'MOD_DESC' ],
	'modelName' => [ 'MOD_NAME' ],
	'modelNumber' => [ 'MOD_NUMBER' ],
	'modelURL' => [ 'MOD_URL' ],
	'UDN' => [ 'UDN' ],
	'presentationURL' => [ 'P_URL' ],
	'fake_key' => [ 'does_not_exist' ]
    };
    my $device = new_ok( 'Net::Fritz::Device', [ fritz => undef, xmltree => $xmltree ] );

    foreach my $key (keys %{$xmltree}) {
	# when
	my $result = $device->attributes->{$key};

	# then
	if ($key =~ /^fake/) {
	    is( $result, undef, "attributes->{$key} is undefined" );
	    ok( ! exists $device->attributes->{$key}, "attributes->{$key} does not exist" );
	} else {
	    is( $result, $xmltree->{$key}->[0], "attributes->{$key} content" );
	}    
    }
};

subtest 'check Net::Fritz::IsNoError role' => sub {
    # given

    # when
    my $device = new_ok( 'Net::Fritz::Device' );

    # then
    ok( $device->does('Net::Fritz::IsNoError'), 'does Net::Fritz::IsNoError role' );
};

## get_service()

subtest 'check get_service() w/success' => sub {
    # given
    my $xmltree = get_xmltree();
    my $device = new_ok( 'Net::Fritz::Device', [ fritz => undef, xmltree => $xmltree ] );
    my $service_type = 'FAKE_SERVICE_0';
    
    # when
    my $service = $device->get_service($service_type);

    # then
    isa_ok( $service, 'Net::Fritz::Service', 'response' );
    is( $service->serviceType, $service_type, 'serviceType matches' );
};

subtest 'check get_service() w/recursion' => sub {
    # given
    my $xmltree = get_xmltree();
    my $device = new_ok( 'Net::Fritz::Device', [ fritz => undef, xmltree => $xmltree ] );
    my $service_type = 'FAKE_SERVICE_3';
    
    # when
    my $service = $device->get_service($service_type);

    # then
    isa_ok( $service, 'Net::Fritz::Service', 'response' );
    is( $service->serviceType, $service_type, 'serviceType matches' );
};

subtest 'check get_service() w/not found' => sub {
    # given
    my $xmltree = get_xmltree();
    my $device = new_ok( 'Net::Fritz::Device', [ fritz => undef, xmltree => $xmltree ] );
    my $service_type = 'FAKE_SERVICE_x';
    
    # when
    my $error = $device->get_service($service_type);

    # then
    isa_ok( $error, 'Net::Fritz::Error', 'response' );
    like( $error->error, qr/not found/, 'error text as expected' );
};

## find_service()

subtest 'check find_service() w/success' => sub {
    # given
    my $xmltree = get_xmltree();
    my $device = new_ok( 'Net::Fritz::Device', [ fritz => undef, xmltree => $xmltree ] );
    my $service_type = 'FAKE_SERVICE_0';
    
    # when
    my $service = $device->find_service('SERVICE.0');

    # then
    isa_ok( $service, 'Net::Fritz::Service', 'response' );
    is( $service->serviceType, $service_type, 'serviceType matches' );
};

subtest 'check find_service() w/recursion' => sub {
    # given
    my $xmltree = get_xmltree();
    my $device = new_ok( 'Net::Fritz::Device', [ fritz => undef, xmltree => $xmltree ] );
    my $service_type = 'FAKE_SERVICE_3';
    
    # when
    my $service = $device->find_service('S[A-Z]+_3');

    # then
    isa_ok( $service, 'Net::Fritz::Service', 'response' );
    is( $service->serviceType, $service_type, 'serviceType matches' );
};

subtest 'check find_service() w/not found' => sub {
    # given
    my $xmltree = get_xmltree();
    my $device = new_ok( 'Net::Fritz::Device', [ fritz => undef, xmltree => $xmltree ] );
    
    # when
    my $error = $device->find_service('^$');

    # then
    isa_ok( $error, 'Net::Fritz::Error', 'response' );
    like( $error->error, qr/not found/, 'error text as expected' );
};

## find_service_names()

subtest 'check find_service_names() w/succeed' => sub {
    # given 
    my $xmltree = get_xmltree();
    my $device = new_ok( 'Net::Fritz::Device', [ fritz => undef, xmltree => $xmltree ] );

    # when
    my $data = $device->find_service_names('[1-5]');

    # then
    isa_ok( $data, 'Net::Fritz::Data', 'response' );
    isa_ok( $data->data, 'ARRAY', 'data->data' );

    my @actual_types = map { $_->serviceType } @{$data->data};
    my @expected_types = qw( FAKE_SERVICE_1 FAKE_SERVICE_2 FAKE_SERVICE_3 FAKE_SERVICE_4 );
    is_deeply ( \@actual_types, \@expected_types, 'list contents' );
};

subtest 'check find_service_names() w/not found' => sub {
    # given 
    my $xmltree = get_xmltree();
    my $device = new_ok( 'Net::Fritz::Device', [ fritz => undef, xmltree => $xmltree ] );

    # when
    my $data = $device->find_service_names('12345');

    # then
    isa_ok( $data, 'Net::Fritz::Data', 'response' );
    isa_ok( $data->data, 'ARRAY', 'data->data' );
    is ( scalar @{$data->data}, 0, 'empty result' );
};

## find_device()

subtest 'check find_device() w/success' => sub {
    # given
    my $xmltree = get_xmltree();
    my $given_device = new_ok( 'Net::Fritz::Device', [ fritz => undef, xmltree => $xmltree ] );
    my $device_type = 'SUBDEVICE_C';
    
    # when
    my $device = $given_device->find_device($device_type);

    # then
    isa_ok( $device, 'Net::Fritz::Device', 'response' );
    is( $device->attributes->{deviceType}, $device_type, 'serviceType matches' );
};

subtest 'check find_device() w/recursion' => sub {
    # given
    my $xmltree = get_xmltree();
    my $given_device = new_ok( 'Net::Fritz::Device', [ fritz => undef, xmltree => $xmltree ] );
    my $device_type = 'SUBDEVICE_B';
    
    # when
    my $device = $given_device->find_device($device_type);

    # then
    isa_ok( $device, 'Net::Fritz::Device', 'response' );
    is( $device->attributes->{deviceType}, $device_type, 'serviceType matches' );
};

subtest 'check find_device() w/not found' => sub {
    # given
    my $xmltree = get_xmltree();
    my $given_device = new_ok( 'Net::Fritz::Device', [ fritz => undef, xmltree => $xmltree ] );
    
    # when
    my $error = $given_device->find_device('not found');

    # then
    isa_ok( $error, 'Net::Fritz::Error', 'response' );
    like( $error->error, qr/not found/, 'error text as expected' );
};


### internal tests

subtest 'check new()' => sub {
    # given

    # when
    my $device = new_ok( 'Net::Fritz::Device' );

    # then
    isa_ok( $device, 'Net::Fritz::Device' );
};

subtest 'check dump()' => sub {
    # TODO: don't test Net::Fritz::Service::dump(), use a mock.  Net::Fritz::Box instance can go, too

    # given
    my $xmltree = {
	'modelName' => [ 'SOME_MODEL_NAME' ],
	'presentationURL' => [ 'SOME_PRESENTATION_URL' ],
	'serviceList' => [
	    { 'service' => [
		  {'serviceType' => [ 'SOME_SERVICE_TYPE' ],
		   'controlURL' => [ 'SOME_CONTROL_URL' ],
		   'SCPDURL' => [ 'SOME_SCPD_URL' ],
		  }
		  ],
	    }
	    ],
	'deviceList' => [
	    { 'device' => [
		  {'modelName' => [ 'SOME_OTHER_MODEL_NAME' ],
		  }
		  ],
	    }
	    ],
    };
    my $fritz = new_ok( 'Net::Fritz::Box' );
    my $device = new_ok( 'Net::Fritz::Device', [ fritz => $fritz, xmltree => $xmltree ] );

    # when
    my $dump = $device->dump();

    # then
    foreach my $line (split /\n/, $dump) {
	like( $line, qr/^(Net::Fritz|  )/, 'line starts as expected' );
    }

    like( $dump, qr/^Net::Fritz::Device/, 'class name is dumped' );
    my $model_name = $device->attributes->{modelName};
    like( $dump, qr/$model_name/, 'modelName is dumped' );
    my $presentation_url = $device->attributes->{presentationURL};
    like( $dump, qr/$presentation_url/, 'presentationURL is dumped' );
    
    like( $dump, qr/^    Net::Fritz::Service/sm, 'sub-service is dumped' );
    like( $dump, qr/^    Net::Fritz::Device/sm, 'sub-device is dumped' );
};


### helper methods

sub get_xmltree
{
    my $xmltree = {
	'serviceList' => [
	    { 'deviceType' => [ 'MAIN_DEVICE' ],
	      'service' => [
		  { serviceType => [ 'FAKE_SERVICE_0' ] },
		  { serviceType => [ 'FAKE_SERVICE_1' ] }
		  ]
	    }
	    ],
	'deviceList' => [
	    { 'device' => [
		  { 'deviceType' => [ 'SUBDEVICE_A' ],
		    'serviceList' => [
			{ 'service' => [
			      { serviceType => [ 'FAKE_SERVICE_2' ] }
			      ]
			}
			],
		    'deviceList' => [
			{ 'device' => [
			      { 'deviceType' => [ 'SUBDEVICE_B' ],
				'serviceList' => [
				    { 'service' => [
					  { serviceType => [ 'FAKE_SERVICE_3' ] }
					  ]
				    }
				    ]
			      }
			      ]
			}
			]
		  },
		  { 'deviceType' => [ 'SUBDEVICE_C' ],
		    'serviceList' => [
			{ 'service' => [
			      { serviceType => [ 'FAKE_SERVICE_4' ] }
			      ]
			}
			]
		  }
		  ]
	    }
	    ]
    }
}
