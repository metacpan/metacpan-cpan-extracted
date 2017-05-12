use strict;
use warnings;
use Test::Spec;
use HTTP::Request;
use HTTP::Response;
use Test::Deep;
use Test::Fatal qw(lives_ok dies_ok);
use Net::Kubernetes;
use Net::Kubernetes::Namespace;
use MIME::Base64;
use Test::Mock::Wrapper 0.18;
use File::Temp qw/tempdir/;
use File::Slurp qw/read_file/;
use File::stat;
use syntax 'try';

use vars qw($lwpMock $sut $ns);

shared_examples_for "All Resources" => sub {
	it "has a 'kind'" => sub {
		ok($sut->kind);
	};
	it "has an 'api_version'" => sub {
		ok($sut->api_version);
	};
	it "has 'metadata'" => sub {
		ok($sut->metadata);
	};
	describe "update" => sub {
		it "makes a PUT request" => sub {
			$sut->update();
			my($call) = $lwpMock->verify('request')->once->getCalls->[0];
			isa_ok($call->[1], 'HTTP::Request');
			is($call->[1]->method, 'PUT');
		};
	};
	describe "delete" => sub {
		it "makes a DELETE request" => sub {
			$sut->delete();
			my($call) = $lwpMock->verify('request')->once->getCalls->[0];
			isa_ok($call->[1], 'HTTP::Request');
			is($call->[1]->method, 'DELETE');
		};
	};
        describe "as_hashref" => sub {
            it "deletes metadata's resource version" => sub {
                $sut->metadata->{resourceVersion} = 'lolVersion';
                is($sut->metadata->{resourceVersion}, 'lolVersion');
                my $object_data = $sut->as_hashref;
                ok(!exists($object_data->{metadata}{resourceVersion}));
            };
        };
};

shared_examples_for "Stateful Resources" => sub {
	it "has a status" => sub {
		ok($sut->status);
	};

	describe "Refresh" => sub {
		it "Can be refreshed" => sub {
			can_ok($sut, 'refresh');
		};

		it "makes a GET request to its selfLink" => sub {
			$sut->refresh();
			my($call) = $lwpMock->verify('request')->once->getCalls->[0];
			isa_ok($call->[1], 'HTTP::Request');
			is($call->[1]->method, 'GET');
			ok(index($call->[1]->uri, $sut->metadata->{selfLink}) > 0);
		};
	};
};

shared_examples_for "Pod Container" => sub {
	it "can get a list of pods" => sub {
		can_ok($sut, 'get_pods');
	};
	it "makes a get request" => sub {
		$sut->get_pods();
		my($call) = $lwpMock->verify('request')->once->getCalls->[0];
		isa_ok($call->[1], 'HTTP::Request');
		is($call->[1]->method, 'GET');
	};
	it "Requests relative to its 'selfLink'" => sub {
		$sut->get_pods();
		my($call) = $lwpMock->verify('request')->once->getCalls->[0];
		isa_ok($call->[1], 'HTTP::Request');
		like($call->[1]->uri, qr{/api/v1beta3/namespaces/default/pods});
	};
};

describe "Net::Kubernetes - All Resource Objects" => sub {
	before all => sub {
		$lwpMock = Test::Mock::Wrapper->new('LWP::UserAgent');
		$lwpMock->addMock('request')->returns(HTTP::Response->new(200, "ok", undef, '{"spec":{}, "metadata":{"selfLink":"/api/v1beta3/namespaces/default/pods/myPod"}, "status":{}, "kind":"Pod", "apiVersion":"v1beta3"}'));
		$sut = Net::Kubernetes::Resource->new(metadata=>{selfLink=>'/api/v1beta3/namespaces/default/pods/myPod'}, status => {}, kind => "Pod", api_version =>"v1beta3");
	};
	before sub {
		$lwpMock->resetCalls;
	};

	it_should_behave_like "All Resources";
};

describe "Net::Kubernetes - Replication Controller Objects " => sub {
	before all => sub {
		$lwpMock = Test::Mock::Wrapper->new('LWP::UserAgent');
		lives_ok {
			$ns = Net::Kubernetes::Namespace->new(base_path=>'/api/v1beta3/namespaces/default');
		};
		$lwpMock->addMock('request')->returns(HTTP::Response->new(200, "ok", undef, '{"spec":{"selector":{"name":"myReplicates"}}, "metadata":{"selfLink":"/api/v1beta3/namespaces/default/replicationcontrollers/myRc"}, "status":{}, "kind":"ReplicationController", "apiVersion":"v1beta3"}'));
		$sut = $ns->get_rc('myRc');
	};
	before sub {
		$lwpMock->resetCalls;
	};

	it_should_behave_like "All Resources";
	it_should_behave_like "Stateful Resources";
	it_should_behave_like "Pod Container";

	it "has a spec" => sub {
		ok($sut->spec);
	};

};

describe "Net::Kubernetes - Pod Objects " => sub {
	before all => sub {
		$lwpMock = Test::Mock::Wrapper->new('LWP::UserAgent');
		lives_ok {
			$ns = Net::Kubernetes::Namespace->new(base_path=>'/api/v1beta3/namespaces/default');
		};
		$lwpMock->resetMocks;
		$lwpMock->addMock('request')->with(code(sub{my($mo,$re) = @{$_[0]}; return $re->uri =~ m/myPod$/ ? 1 : 0;}))->returns(HTTP::Response->new(200, "ok", undef, '{"spec":{"selector":{"name":"myReplicates"}, "containers":[{}]}, "metadata":{"selfLink":"/api/v1beta3/namespaces/default/pods/myPod"}, "status":{}, "kind":"Pod", "apiVersion":"v1beta3"}'));
		$sut = $ns->get_pod('myPod');
	};
	before sub {
		$lwpMock->resetCalls;
	};

	it_should_behave_like "All Resources";
	it_should_behave_like "Stateful Resources";

	describe "container logs" => sub {
		it "has logs" => sub {
			can_ok($sut, 'logs');
		};
		it "fetches logs from kubernetes on demand" => sub {
			$lwpMock->addMock('request')->with(code(sub{my($mo,$re) = @{$_[0]}; return $re->uri =~ m{myPod/log$} ? 1 : 0;}))->returns(HTTP::Response->new(200, "ok", undef, 'LOGS, LOGS, LOGS'));
			$sut->logs();
			my($call) = $lwpMock->verify('request')->once->getCalls->[0];
			isa_ok($call->[1], 'HTTP::Request');
			is($call->[1]->method, 'GET');
			ok(index($call->[1]->uri, $sut->metadata->{selfLink}.'/log') > 0);
		};
		it "passes container name to kubernetes as a parameter if recieved" => sub {
			$lwpMock->addMock('request')->with(code(sub{my($mo,$re) = @{$_[0]}; return $re->uri =~ m{myPod/log\?container=foo$} ? 1 : 0;}))->returns(HTTP::Response->new(200, "ok", undef, 'LOGS, LOGS, LOGS'));
			$sut->logs(container=>'foo');
			my($call) = $lwpMock->verify('request')->once->getCalls->[0];
			isa_ok($call->[1], 'HTTP::Request');
			is($call->[1]->method, 'GET');
			ok(index($call->[1]->uri, $sut->metadata->{selfLink}.'/log') > 0);
		};
		it "throws client side exception if called on a multi-container pod without a container argument" => sub {
			push @{ $sut->spec->{containers} }, {};
			try{
				$sut->logs();
				fail("Should have thrown excpetion");
			}
			catch(Net::Kunbernetes::Exception::ClientException $e) {
				# pass('Horay')
			}
			catch ($e) {
				fail("Should have thrown Net::Kunbernetes::Exception::ClientException, not '$e'");
			}
		};
	}
};

describe "Net::Kubernetes - Node Objects " => sub {
	my $kube;
	before all => sub {
		$lwpMock = Test::Mock::Wrapper->new('LWP::UserAgent');
		lives_ok {
			$kube = Net::Kubernetes->new(url => 'http://localhost:8080', api_version => 'v1');
		};
		$lwpMock->resetMocks;
		$lwpMock->addMock('request')->with(code(sub{my($mo,$re) = @{$_[0]}; return $re->uri =~ m/myNode$/ ? 1 : 0;}))->returns(HTTP::Response->new(200, "ok", undef, '{"spec":{"externalId":"172.18.8.102"}, "metadata":{"selfLink":"/api/v1beta3/nodes/myNode", "name":"myNode"}, "status":{}, "kind":"Node", "apiVersion":"v1"}'));
		$sut = $kube->get_node('myNode');
	};
	before sub {
		$lwpMock->resetCalls;
	};

	it_should_behave_like "All Resources";
	it_should_behave_like "Stateful Resources";

	describe "get_pods" => sub {
		it "has pods" => sub {
			can_ok($sut, 'get_pods');
		};
		it "gets a list of pods from kubernetes on demand" => sub {
			$lwpMock->addMock('request')->with(code(sub{my($mo,$re) = @{$_[0]}; return $re->uri =~ m{pods\?fieldSelector} ? 1 : 0;}))->returns(HTTP::Response->new(200, "ok", undef, '{"status":"ok", "apiVersion":"v1beta3", "items":[{"spec":{}, "metadata":{"selfLink":"/path/to/me"}, "status":{}}]}'));
			$sut->get_pods();
			my($call) = $lwpMock->verify('request')->once->getCalls->[0];
		};
		it "uses nodeName for v1 api" => sub {
			$lwpMock->addMock('request')->with(code(sub{my($mo,$re) = @{$_[0]}; return $re->uri =~ m{pods\?fieldSelector} ? 1 : 0;}))->returns(HTTP::Response->new(200, "ok", undef, '{"status":"ok", "apiVersion":"v1beta3", "items":[{"spec":{}, "metadata":{"selfLink":"/path/to/me"}, "status":{}}]}'));
			$sut->get_pods();
			my($call) = $lwpMock->verify('request')->once->getCalls->[0];
			ok($call->[1]->uri =~ m/nodeName/);
		};
		it "uses host for v1beta3 api" => sub {
			$lwpMock = Test::Mock::Wrapper->new('LWP::UserAgent');
			lives_ok {
				$kube = Net::Kubernetes->new(url => 'http://localhost:8080', api_version => 'v1');
			};
			$lwpMock->resetMocks;
			$lwpMock->addMock('request')->with(code(sub{my($mo,$re) = @{$_[0]}; return $re->uri =~ m/myNode$/ ? 1 : 0;}))->returns(HTTP::Response->new(200, "ok", undef, '{"spec":{"externalId":"172.18.8.102"}, "metadata":{"selfLink":"/api/v1beta3/nodes/myNode", "name":"myNode"}, "status":{}, "kind":"Node", "apiVersion":"v1"}'));
			$sut = $kube->get_node('myNode');
			$lwpMock->resetCalls;
			$lwpMock->addMock('request')->with(code(sub{my($mo,$re) = @{$_[0]}; return $re->uri =~ m{pods\?fieldSelector} ? 1 : 0;}))->returns(HTTP::Response->new(200, "ok", undef, '{"status":"ok", "apiVersion":"v1beta3", "items":[{"spec":{}, "metadata":{"selfLink":"/path/to/me"}, "status":{}}]}'));
			$sut->get_pods();
			my($call) = $lwpMock->verify('request')->once->getCalls->[0];
			ok($call->[1]->uri =~ m/host/);
		}
	};
};

describe "Net::Kubernetes - Secret Objects " => sub {
	before all => sub {
		$lwpMock = Test::Mock::Wrapper->new('LWP::UserAgent');
		lives_ok {
			$ns = Net::Kubernetes::Namespace->new(base_path=>'/api/v1beta3/namespaces/default');
		};
		$lwpMock->addMock('request')->returns(HTTP::Response->new(200, "ok", undef, '{"type":"opaque", "data":{ "readme": "VGVzdCBmaWxlIGZvciBOZXQ6Okt1YmVybmV0ZXMgdGVzdHMuICBUaGlzIGdldHMgY3JlYXRlZCB3aGVuIHRlc3RpbmcgdGhlCk5ldDo6S3ViZXJuZXRlczo6UmVzb3VyY2U6OlNlY3JldC0+cmVuZGVyIG1ldGhvZCwgYW5kIGlzIHVzZWQgdG8gY29uZmlybSB0aGF0Cml0IHdhcyB3cml0dGVuIG91dCBjb3JyZWN0bHkuCgpJdCBjYW4gYmUgc2FmZWx5IGRlbGV0ZWQuICBZb3Ugc2hvdWxkbid0IGV2ZXIgc2VlIGl0LCBhY3R1YWxseS4K", "super-secret-app-password": "Q2FyZXNzIG9mIFN0ZWVsCg==" }, "metadata":{"selfLink":"/api/v1beta3/namespaces/default/replicationcontrollers/myRc"}, "kind":"Secret", "apiVersion":"v1beta3"}'));
		$sut = $ns->get_rc('mySecret');
	};
	before sub {
		$lwpMock->resetCalls;
	};

	it_should_behave_like "All Resources";

	it "has a type" => sub {
		ok($sut->type);
	};
	it "has data" => sub {
		ok($sut->data);
	};
    describe "rendering secrets to a directory" => sub {
        my $directory = tempdir(CLEANUP => 1);

        it "should write two files" => sub {
            is($sut->render(directory => $directory), 2);
        };
        it "writes the correct contents to a file" => sub {
            my $password = read_file("$directory/super-secret-app-password");
            is($password, "Caress of Steel\n");
        };
        it "has the correct size on a larger file" => sub {
            my $stat = stat("$directory/readme") or die "Can't open $directory/readme : $!";
            is($stat->size, 246);
        };

    };
};

describe "Net::Kubernetes - Service Objects " => sub {
	before all => sub {
		$lwpMock = Test::Mock::Wrapper->new('LWP::UserAgent');
		lives_ok {
			$ns = Net::Kubernetes::Namespace->new(base_path=>'/api/v1beta3/namespaces/default');
		};
		$lwpMock->addMock('request')->returns(HTTP::Response->new(200, "ok", undef, '{"spec":{"selector":{"name":"myReplicates"}}, "status":{}, "metadata":{"selfLink":"/api/v1beta3/namespaces/default/replicationcontrollers/myRc"}, "kind":"Service", "apiVersion":"v1beta3"}'));
		$sut = $ns->get_service('myService');
	};
	before sub {
		$lwpMock->resetCalls;
	};

	it_should_behave_like "All Resources";
	it_should_behave_like "Stateful Resources";
	it_should_behave_like "Pod Container";
};

runtests;
