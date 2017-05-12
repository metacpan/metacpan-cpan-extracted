package IntegrationTest;

# Run the mappings tests as fully integrated tests, i.e. use a client to send requests to an SRS EPP Proxy, and on to
#  an SRS.
# Only runs if appropriate environment vars are set, i.e. not usually run as part of 'make test', unless you have
#  a proxy configured and running, and the environment vars setup to point to it.
use strict;
use warnings;

use Test::More;
use FindBin qw($Bin);
use YAML qw(LoadFile);
use XMLMappingTests;
use Data::Dumper;
use Scriptalicious;
use File::Basename;

use lib "$Bin/../../../lib/perl5";

use SRS::EppClient;

# run_tests expects a list of files to be passed in containing the test YAML
# If the first item passed in is a hashref, it's assumed to be 'stash' variables. These
#  variables will replace anything in 'vars' with the same key name. This replacement won't
#  happen if 'int_dont_use_stash' is true
# If the stash_map variable is set (a hashref), the stash key names are first mapped from
#  the keys to the values of stash_map
sub run_tests {
	my @files = @_;

	my $stash = {};
	if (ref $files[0] eq 'HASH') {
		$stash = shift @files;
	}

	unless ($ENV{SRS_PROXY_HOST}) {
		plan 'skip_all';
		exit 0;
	}

	my $test_dir = "$Bin/../../../submodules/SRS-EPP-Proxy/t/";

	@files = map { s|^t/||; $_ } @files;

	my @testfiles = @files ? @files : XMLMappingTests::find_tests('mappings');
	
	our $tt = Template->new({
		INCLUDE_PATH => $test_dir . 'templates',
	});

	foreach my $testfile (sort @testfiles) {
		my $data = XMLMappingTests::read_yaml($testfile);

    	my $client = SRS::EppClient->new(
        	host => $ENV{SRS_PROXY_HOST},
        	port => 700,
    		key  => exists $data->{ssl_key}
    		  ?  $test_dir . 'auth/' . $data->{ssl_key}
    		  : $test_dir . '/auth/client-key.pem',
    		cert => exists $data->{ssl_cert}
    		  ? $test_dir . 'auth/' . $data->{ssl_cert}
    		  : $test_dir . '/auth/client-cert.pem',
    		lazy_connect => 1,
    	);

		diag("Processing: " . $testfile);

		if ($data->{integration_skip}) {
		SKIP: {
				skip "Skipping in integration mode", 1;
			}
			next;
		}

		$stash = map_stash_vars($data->{stash_map}, $stash);

		unless ($data->{no_auto_login}) {
		    my $xml = get_command_xml(
    			command => 'login.tt',
    			user => '100',
    			pass => 'foobar',
    			$data->{extensions} ? (extSvcs => $data->{extensions}) : (), 
            );
            $client->send($xml);
		};

		my $vars = { %{$data->{vars} || {}}, ($data->{int_dont_use_stash} ? () : %$stash) };
		$vars->{command} = $data->{template};
		$vars->{transaction_id} = time;
        my $test_xml = get_command_xml(%$vars);

		my $response = eval { $client->send($test_xml) };
		if ($@) {
			if ($data->{expect_failure}) {
				pass("Couldn't login to proxy: $@");
				next;
			}

			fail("Couldn't talk to Epp proxy: $@");
		}

		if ($response) {
			XMLMappingTests::check_xml_assertions(
				$response,
				$data->{output_assertions}, basename $testfile
			);
		}
		else {
			fail("No response received")
		}
		
	    my $xml = get_command_xml(
			command => 'logout.tt', 
        );
        $client->send($xml);		
	}

	done_testing();
}

sub map_stash_vars {
	my $map = shift;
	my $stash = shift;

	return $stash unless ref $map eq 'HASH' && ref $stash eq 'HASH';

	foreach my $key (keys %$map) {
		if ($stash->{$key}) {
			$stash->{$map->{$key}} = $stash->{$key};
			delete $stash->{$key};
		}
	}

	return $stash;
}

sub get_command_xml {
    my %vars = @_;
    
    our $tt;
    
    my $output;
    $tt->process('frame.tt', \%vars, \$output)
        || die $tt->error(), "\n";
    return $output;   
       
}

1;
