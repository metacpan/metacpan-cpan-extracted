use strict;
use warnings;
use Test::Spec;
use HTTP::Request;
use HTTP::Response;
use Test::Deep;
use Test::Fatal qw(lives_ok dies_ok);
use Net::Kubernetes;
use Test::Mock::Wrapper 0.18;
use vars qw($lwpMock $sut %config);

describe "Net::Kubernetes" => sub {
	before sub {
		$lwpMock = Test::Mock::Wrapper->new('LWP::UserAgent');
		lives_ok {
			$sut = Net::Kubernetes->new;
		}
	};
	spec_helper "resource_lister_examples.pl";
	it "can be instantiated" => sub {
		ok($sut);
		isa_ok($sut, 'Net::Kubernetes');
	};

	it_should_behave_like "Pod Lister";
	it_should_behave_like "Endpoint Lister";
	it_should_behave_like "Replication Controller Lister";
	it_should_behave_like "Service Lister";
	it_should_behave_like "Secret Lister";

	describe "get_namespace" => sub {
		it "can get a namespace" => sub {
			can_ok($sut, 'get_namespace');
		};
		it "throws an exception if namespace is not passed in" => sub {
			$lwpMock->addMock('request')->returns(HTTP::Response->new(200, "ok", undef, '{"status":"ok", "apiVersion":"v1beta3", "metadata":{"selfLink":"/path/to/me"}}'));
			dies_ok {
				$sut->get_namespace;
			};
		};
		it "throws an exception if the call returns an error" => sub {
			$lwpMock->addMock('request')->returns(HTTP::Response->new(401, "you suck"));
			dies_ok {
				$sut->get_namespace('foo');
			};
		};
		it "doesn't throw an exception if the call succeeds" => sub {
			$lwpMock->addMock('request')->returns(HTTP::Response->new(200, "ok", undef, '{"status":"ok", "apiVersion":"v1beta3", "metadata":{"selfLink":"/path/to/me"}}'));
			lives_ok {
				$sut->get_namespace('myNamespace');
			};
		};
		it "returns a new Net::Kubernetes::Namespace object set to the requested namespace" => sub {
			$lwpMock->addMock('request')->returns(HTTP::Response->new(200, "ok", undef, '{"status":"ok", "apiVersion":"v1beta3", "metadata":{"selfLink":"/path/to/me"}}'));
			my $res = $sut->get_namespace('myNamespace');
			isa_ok($res, 'Net::Kubernetes::Namespace');
			is($res->namespace, 'myNamespace');
		};
	};
	describe "list_nodes" => sub {
		before sub {
			$config{method} = 'list_nodes';
		};
		it_should_behave_like "all_list_methods";
		it "returns a list of Net::Kubernetes::Node objects" => sub {
			$lwpMock->addMock('request')->returns(HTTP::Response->new(200, "ok", undef, '{ "kind": "NodeList", "apiVersion": "v1beta3", "metadata":{ "selfLink": "/api/v1beta3/nodes", "resourceVersion": "60116" }, "items": [ { "metadata": { "name": "name", "selfLink": "/api/v1beta3/nodes/name", "labels": { "kubernetes.io/hostname": "name" } }, "spec": { "externalID": "name" }, "status": { "field": "woot" } }] }'));
			my(@nodes) = $sut->list_nodes();
			is(scalar(@nodes), 1);
			isa_ok($nodes[0], 'Net::Kubernetes::Resource::Node');
		};
	};
	describe "list_service_accounts" => sub {
		before sub {
			$config{method} = 'list_service_accounts';
		};
		it_should_behave_like "all_list_methods";
		it "returns a list of Net::Kubernetes::Node objects" => sub {
			$lwpMock->addMock('request')->returns(HTTP::Response->new(200, "ok", undef, '{ "kind": "NodeList", "apiVersion": "v1beta3", "metadata":{ "selfLink": "/api/v1beta3/nodes", "resourceVersion": "60116" }, "items": [ { "metadata": { "name": "name", "selfLink": "/api/v1beta3/nodes/name", "labels": { "kubernetes.io/hostname": "name" } }, "secrets": [{ "externalID": "name" }], "imagePullSecrets":[], "status": { "field": "woot" } }] }'));
			my(@nodes) = $sut->list_service_accounts();
			is(scalar(@nodes), 1);
			isa_ok($nodes[0], 'Net::Kubernetes::Resource::ServiceAccount');
		};
	};
};

runtests;
