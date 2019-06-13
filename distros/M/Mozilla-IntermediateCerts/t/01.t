use Test::Spec;

use Data::Dumper;
use Test::HTTP::LocalServer;

use lib 'lib';

use Mozilla::IntermediateCerts;

describe "Can open local test server" => sub {

		my ($server, $url, $parsed);
		
		before sub {
			$server = Test::HTTP::LocalServer->spawn;
			$url = $server->local('test.csv');
		};

		it "has a local server" => sub {
			ok $server;
		};

		it "has a url" => sub {
			ok $url;
		};
	

		describe "Can load Mozilla::IntermediateCerts module" => sub {

			before sub {
				$parsed = Mozilla::IntermediateCerts->new( 
								moz_int_cert_path => $url
				);
			};
			
			it "should have an object defined" => sub {
				ok( defined( $parsed ) );
			};
			
			it "object should be of type Mozilla::IntermediateCerts" => sub {
				is( ref $parsed, 'Mozilla::IntermediateCerts' );
			};

			it "has no error" => sub {
				ok !$parsed->error;
			};


			describe "for certs" => sub {
				my $certs;
				before sub {
					$certs = $parsed->certs; 
				};
				
				it "has certificates" => sub {
					ok $certs;
				};

				it "certs are Mozilla::IntermediateCerts::Cert objects" => sub {
					is( ref $certs->[0], 'Mozilla::IntermediateCerts::Cert' );
				};

				it "has pem_info" => sub {
					ok $certs->[0]->pem_info;
				};
			};
		};
};
runtests unless caller;
