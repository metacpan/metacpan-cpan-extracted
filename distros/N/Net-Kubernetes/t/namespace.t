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
use vars qw($lwpMock $sut);


describe "Net::Kubernetes - Namespace" => sub {
	before sub {
		$lwpMock = Test::Mock::Wrapper->new('LWP::UserAgent');
		lives_ok {
			$sut = Net::Kubernetes::Namespace->new(base_path=>'/api/v1beta3/namespaces/default');
		};
	};
	it "can be instantiated" => sub {
		ok($sut);
		isa_ok($sut, 'Net::Kubernetes::Namespace');
	};
	spec_helper "resource_lister_examples.pl";
	it_should_behave_like "Pod Lister";
	it_should_behave_like "Endpoint Lister";
	it_should_behave_like "Replication Controller Lister";
	it_should_behave_like "Service Lister";
	it_should_behave_like "Secret Lister";

	describe "get_pod" => sub {
		it "throws an exception if not given a pod name" => sub {
			dies_ok { $sut->get_pod();   };
		};
		it "returns a Net::Kubernetes::Resource::Pod object on success" => sub {
			$lwpMock->addMock('request')->returns(HTTP::Response->new(200, "ok", undef, '{"spec":{}, "metadata":{"selfLink":"/path/to/me"}, "status":{}, "kind":"Pod", "apiVersion":"v1beta3"}'));
			my $pod;
			lives_ok { $pod = $sut->get_pod('myPod');   };
			isa_ok($pod, 'Net::Kubernetes::Resource::Pod');
		};
	};
	describe "get_rc" => sub {
		it "throws an exception if not given a pod name" => sub {
			dies_ok { $sut->get_rc();   };
		};
		it "returns a Net::Kubernetes::Resource::ReplicationController object on success" => sub {
			$lwpMock->addMock('request')->returns(HTTP::Response->new(200, "ok", undef, '{"spec":{}, "metadata":{"selfLink":"/path/to/me"}, "status":{}, "kind":"ReplicationController", "apiVersion":"v1beta3"}'));
			my $rc;
			lives_ok { $rc = $sut->get_rc('myRc');   };
			isa_ok($rc, 'Net::Kubernetes::Resource::ReplicationController');
		};
	};
	describe "get_service" => sub {
		it "throws an exception if not given a pod name" => sub {
			dies_ok { $sut->get_service();   };
		};
		it "returns a Net::Kubernetes::Resource::Service object on success" => sub {
			$lwpMock->addMock('request')->returns(HTTP::Response->new(200, "ok", undef, '{"spec":{}, "metadata":{"selfLink":"/path/to/me"}, "status":{}, "kind":"Service", "apiVersion":"v1beta3"}'));
			my $se;
			lives_ok { $se = $sut->get_service('myRc');   };
			isa_ok($se, 'Net::Kubernetes::Resource::Service');
		};
	};
	describe "get_secret" => sub {
		it "throws an exception if not given a pod name" => sub {
			dies_ok { $sut->get_secret();   };
		};
		it "returns a Net::Kubernetes::Resource::Secret object on success" => sub {
			$lwpMock->addMock('request')->returns(HTTP::Response->new(200, "ok", undef, '{"type":"hiddeen", "metadata":{"selfLink":"/path/to/me"}, "data":{"stuff":"here"}, "kind":"Secret", "apiVersion":"v1beta3"}'));
			my $secret;
			lives_ok { $secret = $sut->get_secret('myRc');   };
			isa_ok($secret, 'Net::Kubernetes::Resource::Secret');
		};
	};
};

runtests;
