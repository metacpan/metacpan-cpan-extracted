#!/usr/bin/perl
# $Id: log-resolver.perl 147 2007-01-21 07:57:35Z rcaputo $

# Resolve IP addresses in log files into their hosts, in some number
# of parallel requests.  This example exercises the system's ability
# to manage and track multiple consumer requests to a single producer.

{
	package App;

	use POE::Stage::App qw(:base self expose);
	use POE::Stage::Resolver;

	sub on_run {

		# Create a single resolver to be used multiple times.

		my $req_resolver = POE::Stage::Resolver->new();

		# Start a handful of initial requests.
		for (1..5) {
			my $next_address = read_next_address();
			last unless defined $next_address;

			self->resolve_address({ addr => $next_address });
		}
	}

	sub handle_host :Handler {
		my ($arg_input, $arg_packet);

		my ($req, $rsp, $rsp_itself);

		my @answers = $arg_packet->answer();
		foreach my $answer (@answers) {
			print(
				"Resolved: $arg_input = type(", $answer->type(), ") data(",
				$answer->rdatastr, ")\n"
			);
		}

		my $next_address = read_next_address();
		return unless defined $next_address;
		self->resolve_address({ addr => $next_address });
	}

	# Handle some error.
	sub handle_error :Handler {
		my ($arg_input, $arg_error);

		print "Error: $arg_input = $arg_error\n";

		my $next_address = read_next_address();
		last unless defined $next_address;

		self->resolve_address({ addr => $next_address });
	}

	# Plain old subroutine.  Doesn't handle events.
	sub read_next_address :Handler {
		while (<main::DATA>) {
			chomp;
			s/\s*\#.*$//;     # Discard comments.
			next if /^\s*$/;  # Discard blank lines.
			return $_;        # Return a significant line.
		}
		return;             # EOF.
	}

	# Plain old method.  Doesn't handle events.
	sub resolve_address :Handler {
		my $arg_addr;
		return unless defined $arg_addr;

		my %req_subs;

		my $resolve_request = POE::Request->new(
			stage => my $req_resolver,
			method => "resolve",
			on_success  => "handle_host",
			on_error    => "handle_error",
			args        => {
				input     => $arg_addr,
			},
		);

		expose $resolve_request => my $moo_itself;
		$moo_itself = $resolve_request;

		$req_subs{$resolve_request} = $resolve_request;
	}
}

# Main program.

App->new()->run();
exit;

# 198.252.144.2
# 198.175.186.5

__DATA__
141.213.238.252
192.116.231.44
193.109.122.77
193.163.220.3
193.201.200.130
194.109.129.220
195.111.64.195
195.82.114.48
198.163.214.60
198.3.160.3
204.92.73.10
205.210.145.2
209.2.32.38
216.193.223.223
216.32.207.207
217.17.33.10
64.156.25.83
65.77.140.140
66.225.225.225
66.243.36.134
66.33.204.143
66.33.218.20
68.213.211.142
69.16.172.2
80.240.238.17
