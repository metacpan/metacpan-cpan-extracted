use Test::Spec;
use Net::Kubernetes;
use vars qw($sut $lwpMock %config);

shared_examples_for "all_list_methods" => sub {
	my($method);
	before all => sub {
		$method = $config{method};
	};
	it "can be called" => sub {
		can_ok($sut, 'list_pods');
	};
	it "throws an exception if the call returns an error" => sub {
		$lwpMock->addMock('request')->returns(HTTP::Response->new(401, "you suck"));
		dies_ok {
			$sut->$method;
		};
	};
	it "doesn't throw an exception if the call succeeds" => sub {
		$lwpMock->addMock('request')->returns(HTTP::Response->new(200, "ok", undef, '{"status":"ok", "apiVersion":"v1beta3"}'));
		lives_ok {
			$sut->$method;
		};
	};
	it "includes label selector in query if labels are passed in" => sub{
		$lwpMock->addMock('request')->returns(HTTP::Response->new(200, "ok", undef, '{"status":"ok", "apiVersion":"v1beta3", "items":[]}'));
		$sut->$method(labels=>{name=>'my-pod'});
		$lwpMock->verify('request')->once;
		my $req = $lwpMock->getCallsTo('request')->[0][1];
		cmp_deeply([ $req->uri->query_form ], supersetof('labelSelector'));
	};
	it "includes field selector in query if fields are passed in" => sub{
		$lwpMock->addMock('request')->returns(HTTP::Response->new(200, "ok", undef, '{"status":"ok", "apiVersion":"v1beta3", "items":[]}'));
		$sut->$method(fields=>{'status.phase'=>'Running'});
		$lwpMock->verify('request')->once;
		my $req = $lwpMock->getCallsTo('request')->[0][1];
		cmp_deeply([ $req->uri->query_form ], supersetof('fieldSelector'));
	};
};

shared_examples_for "Pod Lister" => sub{
	before sub {
		$config{method} = 'list_pods';
	};
	it_should_behave_like "all_list_methods";
	it "returns an array of pods" => sub {
		$lwpMock->addMock('request')->returns(HTTP::Response->new(200, "ok", undef, '{"status":"ok", "apiVersion":"v1beta3", "items":[{"spec":{}, "metadata":{"selfLink":"/path/to/me"}, "status":{}}]}'));
		my $res = $sut->list_pods;
		isa_ok($res, 'ARRAY');
		isa_ok($res->[0], 'Net::Kubernetes::Resource::Pod');
	};
};

shared_examples_for "Endpoint Lister" => sub{
	before sub {
		$config{method} = 'list_endpoints';
	};
	it_should_behave_like "all_list_methods";
	it "returns an array of pods" => sub {
		$lwpMock->addMock('request')->returns(HTTP::Response->new(200, "ok", undef, '{"status":"ok", "apiVersion":"v1beta3", "items":[{"metadata":{"selfLink":"/path/to/me"}, "subsets":[{}]}]}'));
		my $res = $sut->list_endpoints;
		isa_ok($res, 'ARRAY');
		isa_ok($res->[0], 'Net::Kubernetes::Resource::Endpoint');
	};
};

shared_examples_for "Replication Controller Lister" => sub {
	before sub {
		$config{method} = 'list_rc';
	};
	it_should_behave_like "all_list_methods";
	it "returns an array of ReplicationControllers" => sub {
		$lwpMock->addMock('request')->returns(HTTP::Response->new(200, "ok", undef, '{"status":"ok", "apiVersion":"v1beta3", "items":[{"spec":{}, "metadata":{"selfLink":"/path/to/me"}, "status":{}}]}'));
		my $res = $sut->list_rc;
		isa_ok($res, 'ARRAY');
		isa_ok($res->[0], 'Net::Kubernetes::Resource::ReplicationController');
	};
};

shared_examples_for "Service Lister" => sub {
	before sub {
		$config{method} = 'list_services';
	};
	it_should_behave_like "all_list_methods";
	it "returns an array of Services" => sub {
		$lwpMock->addMock('request')->returns(HTTP::Response->new(200, "ok", undef, '{"status":"ok", "apiVersion":"v1beta3", "items":[{"spec":{}, "metadata":{"selfLink":"/path/to/me"}, "status":{}}]}'));
		my $res = $sut->list_services;
		isa_ok($res, 'ARRAY');
		isa_ok($res->[0], 'Net::Kubernetes::Resource::Service');
	};
};

shared_examples_for "Secret Lister" => sub {
	before sub {
		$config{method} = 'list_secrets';
	};
	it_should_behave_like "all_list_methods";
	it "returns an array of secrets" => sub {
		$lwpMock->addMock('request')->returns(HTTP::Response->new(200, "ok", undef, '{"status":"ok", "apiVersion":"v1beta3", "items":[{"spec":{}, "metadata":{"selfLink":"/path/to/me"}, "status":{}}]}'));
		my $res = $sut->list_services;
		isa_ok($res, 'ARRAY');
		isa_ok($res->[0], 'Net::Kubernetes::Resource::Service');
	};
};
