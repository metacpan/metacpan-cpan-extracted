
package XMLMappingTests;

BEGIN {
	*$_ = \&{"main::$_"} for qw(ok diag fail pass);
}

use Scriptalicious;
use File::Find;
use FindBin qw($Bin $Script);
use strict;
use YAML qw(LoadFile Load Dump);
use XML::LibXML;
use Test::XML::Assert;
use Test::More;

our $grep;
getopt_lenient( "test-grep|t=s" => \$grep );

# get an XML parser
our $parser = XML::LibXML->new();

# namespaces, used for various XML::Compare etc tests
my $xmlns = {
	epp => 'urn:ietf:params:xml:ns:epp-1.0',
	domain => 'urn:ietf:params:xml:ns:domain-1.0',
	host => 'urn:ietf:params:xml:ns:host-1.0',
	contact => 'urn:ietf:params:xml:ns:contact-1.0',
	secDNS => 'urn:ietf:params:xml:ns:secDNS-1.1',
};

# get a template object
use Template;
our $tt = Template->new({

		# FIXME: this shouldn't be relative
		INCLUDE_PATH => $Bin.'/templates/',
	}
);

sub find_tests {
	my $group = shift || ($Script=~/(.*)\.t$/)[0];

	my @tests;
	find(
		sub {
			if ( m{\.yaml$} && (!$grep||m{$grep}) ) {
				my $name = $File::Find::name;
				$name =~ s{^\Q$Bin\E/}{} or die;
				push @tests, $name;
			}
		},
		"$Bin/$group"
	);
	@tests;
}

sub find_file {
	my $file = shift;

	if (-f $file) {
		return $file;
	} elsif (-f "$Bin/$file") {
		return "$Bin/$file";
	}

	die "Unable to find $file!\n";
}

sub read_xml {
	my $test = shift;

	my $file = find_file($test);

	open XML, "<", $file or return undef;
	binmode XML, ":utf8";
	my $xml = do {
		local($/);
		<XML>;
	};
	close XML;
	$xml;
}

sub read_yaml {
	my $test = shift;

	my $file = find_file($test);

	LoadFile $file;
}

sub check_xml_assertions {
	my ($xml, $testset, $desc) = @_;

	# firstly, make an XML document with the input $xml
	my $doc = $parser->parse_string($xml)->documentElement();

	my $failure = 0;

	# if we have some count tests, run those first
	if ( defined $testset->{count} ) {
		for my $t ( @{$testset->{count}} ) {

			# print Dumper($t);
			# print "Doing test $t->[2]\n";
			$failure ||= !is_xpath_count(
				$doc, $xmlns, $t->[0], $t->[1],
				"$desc - $t->[2]",
			);

			# print "Done\n";
		}
	}

	# if we have some matches
	if ( defined $testset->{match} ) {
		for my $t ( @{$testset->{match}} ) {
			if ( $t->[1] =~ m{^/(.*)/$} ) {
				$t->[1] = qr/$1/;
			}
			$failure ||= !does_xpath_value_match(
				$doc, $xmlns, $t->[0], eval{$t->[1]}||$t->[1],
				"$desc - $t->[2]",
			);
		}
	}

	# if we have some match_all
	if ( defined $testset->{match_all} ) {
		for my $t ( @{$testset->{match_all}} ) {
			$failure ||= !do_xpath_values_match(
				$doc, $xmlns, $t->[0], $t->[1],
				"$desc - $t->[2]",
			);
		}
	}

	# if we some attribute checks
	if ( defined $testset->{attr_is} ) {
		for my $t ( @{$testset->{attr_is}} ) {
			$failure ||= !does_attr_value_match(
				$doc, $xmlns,
				$t->[0], $t->[1], $t->[2],
				"$desc - $t->[3]",
			);
		}
	}

	if ($failure) {
		diag "failed $desc:\n".$doc->toString(1);
	}
}

{

	package XMLMappingTest;
	use Moose;
	has filename => (
		is => "ro",
		isa => "Str",
		required => 1,
	);
	has desc => (
		is => "ro",
		isa => "Str",
		lazy => 1,
		default => sub {
			my $self = shift;
			my $desc = $self->filename;
			$desc =~ s{.*/}{};
			$desc =~ s{\.yaml$}{};
			$desc;
		},
	);
	has data => (
		is => "ro",
		lazy => 1,
		default => sub {
			my $self = shift;
			XMLMappingTests::read_yaml($self->filename);
		},
	);
	has template => (
		is => "ro",
		lazy => 1,
		default => sub {
			my $self = shift;
			$self->data->{template};
			}
	);
	has vars => (
		is => "ro",
		lazy => 1,
		default => sub {
			my $self = shift;
			my $vars = $self->data->{vars} ||= {};
			$vars->{command} = $self->template;
			$vars;
		},
	);
	has 'xml' => (
		is => "ro",
		lazy => 1,
		default => sub {
			my $self = shift;
			
			return $self->data->{xml} if defined $self->data->{xml}; 
			
			my $xml_str;
			$XMLMappingTests::tt->process(
				'frame.tt',
				$self->vars,
				\$xml_str,
			);
			$xml_str;
		},
	);
	has 'input_assertions' => (
		is => "ro",
		lazy => 1,
		default => sub {
			my $self = shift;
			$self->data->{input_assertions};
		},
	);
	has 'expected_cycles' => (
		is => "ro",
		lazy => 1,
		default => sub {
			my $self = shift;
			scalar @{ $self->data->{SRS}||[] };
		},
	);
	has 'session' => (
		is => "rw",
		isa => "SRS::EPP::Session",
		weak_ref => 1,
	);
	has 'command_object' => (
		is => "rw",
		isa => "SRS::EPP::Command",
	);
}

sub load_test {
	my $test_name = shift;

	my $test = XMLMappingTest->new(filename => $test_name);

	return $test if $test->data->{skip};

	print 'EPP request  = ', $test->xml if $VERBOSE>0;

	# test this XML against our initial assertions
	if ( $test->input_assertions ) {
		check_xml_assertions(
			$test->xml, $test->input_assertions,
			"load $test_name",
		);
	}

	return $test;
}

# input_packet_test: tests the input parsing and mapping machinery
#
# true return means that a packet was queued; false means nothing was
# and subsequent tests should be skipped.
sub input_packet_test {
	my $test = shift;
	my $session = shift;
	if ($session) {
		$test->session($session);
	}
	else {
		$session = $test->session;
	}
	my $desc = $test->desc;

	my $queue_size = $session->commands_queued;

	$session->input_packet( $test->xml );

	my $commands_queued = $session->commands_queued - $queue_size;

	if ( !$commands_queued ) {

		# hoist the main::fail!
		main::fail("$desc: no command queued");
		return;
	}
	elsif ( $commands_queued > 1 ) {
		main::fail("$desc: multiple commands queued");
	}

	my $queued_command = $session->processing_queue->queue->[-1];
	$test->command_object($queued_command);

	if ( my $class = eval{$test->input_assertions->{class}} ) {

		# Make sure that the queue_item is the right class
		isa_ok( $queued_command, $class, "$desc queued command");
	}
	main::pass("$desc: command queued");
}

sub _test_backend_messages {
	my $messages = shift;
	my $srs_assertions = shift;
	my $desc = shift;

	# back-end messages were queued; test them.
	my $tx = XML::SRS::Request->new(
		version => "auto",
		requests => [ map { $_->message } @$messages ],
	);
	my $xmlstring = $tx->to_xml();
	if ( $main::VERBOSE > 0 ) {
		main::diag("back-end message:\n".$tx->to_xml(1));
	}

	XMLMappingTests::check_xml_assertions(
		$xmlstring, $srs_assertions, $desc,
	);
}

sub _test_response {
	my $test = shift;
	my $rs = shift;
	my $desc = shift;

	if ( my $class = $test->data->{output_assertions}{class} ) {
		isa_ok( $rs, $class, $desc );
	}

	if ( $main::VERBOSE > 0 ) {
		main::diag("response:\n".$rs->message->to_xml(1));
	}
	check_xml_assertions(
		$rs->message->to_xml, $test->data->{output_assertions},
		$desc,
	);
}

sub _test_session_change {
	my $test = shift;
	my $session = shift;
	my $index = shift;
	my $cycle = $index + 1;
	my $pre_be_queue_tip = shift;
	my $desc = $test->desc;

	my $be_q = $session->backend_queue;
	my $cmd_q = $session->processing_queue;
	my $new_tip = $be_q->queue->[-1];

	if (
		do { no warnings 'uninitialized'; $new_tip != $pre_be_queue_tip }
		and $new_tip
		)
	{

		my $messages = $new_tip;

		# process resulted in a new command.  should they have?
		my $assertions = eval{$test->data->{SRS}[$index]{assertions}};
		if ( $@ or !$test->data->{SRS}[$index] ) {
			fail("$desc - unexpected SRS cycle ($cycle)");
			return;
		}
		pass("$desc: back-end cycle ($cycle)");

		# yes - go ahead and test them.
		_test_backend_messages(
			$messages,
			$assertions,
			"$desc - SRS rq ($cycle)",
		) if $assertions;

		# FIXME - somewhat inelegant; copied from
		# Session::next_message
		my @next = $session->backend_next(
			$session->backend_queue->queue_size,
		);
		my $tx = XML::SRS::Request->new(
			version => "auto",
			requests => [ map { $_->message } @next ],
		);
		my $rq = SRS::EPP::SRSMessage->new(
			message => $tx,
			parts => \@next,
		);
		$session->active_request($rq);

		return 2;
	}
	elsif ( my $rs = $cmd_q->responses->[ $cmd_q->next-1 ] ) {

		# process resulted in an immediate response (eg, an
		# error)
		use Data::Dumper;
		ok(
			!$test->data->{SRS}[$index],
			"$desc: immediate error returned (and no assertions provided in test file)"
			)
			or diag "Found these SRS assertions in test file:\n"
			.  Dumper $test->data->{SRS}[$index];
		_test_response( $test, $rs, "$desc - epp rs", );
		return 1;
	}
	else {

		# neither happened - not even an internal error wtf?
		fail(
			"$desc: nothing queued/returned from "
				."mapping (cycle $cycle)"
		);
		return;
	}
}

# process_command_test : test that a command becomes the expected
# set of SRS messages and/or response messages.
# return: 1: response ready.  2: back-end cycle required
sub process_command_test {
	my $test = shift;
	my $desc = $test->desc;

	my $session = $test->session;

	my $cmd_q = $session->processing_queue;

	my $c;
	while ( $cmd_q->commands_queued > ($cmd_q->next+1) ) {

		# junk extra commands, try to skip them.
		$session->process_queue(1);
		die if ++$c > 10;
	}

	my $be_q = $session->backend_queue;
	my $queue_tip = $be_q->queue->[-1];

	# first time around, just fire the 'process_queue'
	# event, this will do what is required.
	$DB::single = 1;
	$session->process_queue();

	_test_session_change(
		$test,
		$session,
		0,
		$queue_tip,
	);
}

# test a return cycle.
sub backend_return_test {
	my $test = shift;
	my $cycle = shift;
	my $rs = shift;
	my $desc = $test->desc;

	if ( !$rs ) {
		$rs = $test->data->{SRS}[$cycle-1]{fake_response};
		if ( !$rs ) {
			my $rs_filename = $test->filename;
			$rs_filename =~ s{\.ya?ml$}{.$cycle.xml};
			$rs = read_xml($rs_filename);
		}
		if ( !$rs ) {
			fail("no response in test case for cycle $cycle");
			return 0;
		}
	}

	my $session = $test->session;
	my $be_q = $session->backend_queue;
	my $queue_tip = $be_q->queue->[-1];

	my $rs_tx = $session->parse_be_response($rs); 

	$session->be_response($rs_tx) if $rs_tx;
	$DB::single = 1;
	$session->process_responses;

	_test_session_change(
		$test,
		$session,
		$cycle,
		$queue_tip,
	);
}

sub response_test {
	my $test = shift;
	my $desc = $test->desc;

	my $response = $test->session->dequeue_response;
	if ( !$response ) {
		return fail("$desc: no response ready");
	}

	my $rs_xml = $response->message->to_xml;
	check_xml_assertions(
		$rs_xml,
		$test->data->{output_assertions},
		$desc,
	);
}

use Storable qw(dclone);

sub run_unit_tests {
	my $gen_session = shift;
	my @testfiles = @_;
	
	for my $testfile ( sort @testfiles ) {
		diag("Reading $testfile") if $main::VERBOSE>0;
		my $test = load_test($testfile);
		if ($test->data->{skip}) {
		SKIP: {
				skip $test->data->{skip}, 1;

			}
			next if $test->data->{skip};
		}
		my $session = $gen_session->();
		if ( exists $test->data->{user} ) {
			$session->user($test->data->{user});
		}
		
		if ( $test->data->{extensions} ) {
			$session->extensions->set(@{$test->data->{extensions}});
		}
	SKIP:{
			input_packet_test($test, $session)
				or skip "no command logged", 1;

			my $test_rs = process_command_test($test)
				or skip "processing failed", 1;

			my $cycle = 1;
			while ( $test_rs == 2 ) {
				$test_rs = backend_return_test(
					$test,
					$cycle,
					)
					or skip "processing failed", 1;
				$cycle++;
			}
		}
	}
}

no strict;
use Sub::Exporter -setup => {
	exports => [
		grep { !/^_/ && defined &$_ }
			keys %{__PACKAGE__.::},
	],
};

1;
