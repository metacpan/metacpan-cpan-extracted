package POE::Component::FastCGI::Stream;
BEGIN {
  $POE::Component::FastCGI::Stream::VERSION = '0.19';
}
use strict;
use warnings;
use Carp;

use POE qw(Component::FastCGI);
use Digest::MD5 qw(md5_hex);
use CGI::Util qw(escape);

sub new {
	my($class, %params) = @_;

	my $prefix = defined $params{Prefix} ? $params{Prefix} : "";
	my $cookiename = defined $params{Cookie} ? $params{Cookie} : undef;
	my $states = delete $params{States};
	my $handlers = delete $params{Handlers};

	carp "No states defined!" unless defined $states;

	POE::Component::FastCGI->new(
		%params,
		Handlers => [
		   defined $handlers ? @$handlers : (),
			[ qr!^$prefix/[a-f0-9]{32}(?:/.*|$)! => sub { #/
				my($request) = @_;

				my($id, $param) = ($request->uri->path =~
					qr!^$prefix/([a-f0-9]{32})(/.*|$)!); #/

				$param =~ s!^/!!;

				print $request->method . " " . $request->uri . "\n";

				my $session = $poe_kernel->alias_resolve("client-$id");
				if(not defined $session) {
					$request->make_response->code(404);
					return;
				}

				return unless check_cookie($session->get_heap, $request);

				$param = "default" unless defined $param and $param;

				# If this wants to set streaming post won't do
				$poe_kernel->call($session => "in_$param", $request);

				if(not defined $request->{_res}) {
					$request->make_response->code(404);
				}
			} ],
			[ "$prefix/new" => sub {
				my($request) = @_;

				my $type = $request->query("type");
				return unless $type eq "xmlhttp" or $type eq "iframe";

				my $id = md5_hex(rand() . join "", values %{$request->{env}});

				my $session = POE::Session->create(
					inline_states => {
						# Include all states passed to us in constructor
						%$states,
						_start => sub {
							my($heap, $session) = @_[HEAP, SESSION];
							$poe_kernel->alias_set("client-$heap->{sessid}");
							$heap->{alive} = $poe_kernel->delay_set("keepalive", 25);
							$poe_kernel->yield("out_id", "$prefix/$heap->{sessid}/");
							$poe_kernel->yield('initalize');
						},
						shutdown => sub {
							my($heap) = $_[HEAP];
							#print "Got shutdown\n";
							$heap->{stream}->close if $heap->{stream};
							delete $heap->{stream};
							$poe_kernel->alias_remove("client-$heap->{sessid}");
						},
						in_stream => \&stream,
						keepalive => \&keepalive,
						_default => sub {
							my($heap, $event, $args) = @_[HEAP, ARG0, ARG1];
							if($event =~ /^out_(.*)/) {
								my $out = out($heap, $1, $args->[0]);
								if($heap->{stream}) {
									$heap->{stream}->write(wrap_output($heap, $out));
								}else{
									$heap->{buffer} .= $out;
								}
							}
						}
					},
					heap => {
						sessid => $id,
						type => $type,
						msgid => 0,
						buffer => "",
						cookiename => $cookiename
					},
				);
				my $response = $request->make_response;
				$response->redirect("$prefix/$id/stream");
				$response->header("Set-cookie" => "$cookiename=" .
					md5_hex($id . rand())) if defined $cookiename
						and not $request->cookie($cookiename);
			}
		],
	]);
	return;
};

sub check_cookie {
	my($heap, $request) = @_;
	if(defined $heap->{cookiename}) {
		if(defined $heap->{cookie}) {
			if($request->cookie($heap->{cookiename}) ne $heap->{cookie}) {
				$request->make_response->code(403);
				return 0;
			}
		}elsif($request->cookie($heap->{cookiename})) {
			$heap->{cookie} = $request->cookie($heap->{cookiename});
		}
	}
	return 1;
}

sub stream {
	my($heap, $request) = @_[HEAP, ARG0];

	return unless check_cookie($heap, $request);

	delete $heap->{stream} if exists $heap->{stream};

	my $response = $request->make_response;
	$response->write("Content-type: text/html\r\n\r\n");
	$response->streaming(1);
	$response->closed(\&stream_closed);
	$response->{id} = $heap->{sessid};

	if($heap->{type} eq 'iframe') {
		$response->write("<html>\nstream $request->{requestid}\n<!-- "
			. ("padding " x 10) . "-->\n\n");
	}
	$heap->{stream} = $response;
	$response->write(wrap_output($heap, delete $heap->{buffer}));
}

sub keepalive {
	my($heap) = $_[HEAP];

	if($heap->{stream}) {
		if($heap->{type} eq 'iframe') {
			$heap->{stream}->write("<!-- keepalive -->\n");
		}else{
			$heap->{stream}->write("keepalive\n");
		}
	}
	$poe_kernel->delay_set("keepalive", 25);
}

sub stream_closed {
	my($stream) = @_;
	my $session = $poe_kernel->alias_resolve("client-$stream->{id}");
	if(defined $session) {
		print "closed $stream->{id} - $session\n";
		$poe_kernel->post($session => "disconnected");
	}
}

sub out {
	my($heap, $func, $e) = @_;
	$heap->{msgid}++;
	if($heap->{type} eq 'iframe') {
		if(defined $e) {
			$e =~ s/\\/\\\\/g;
			$e =~ s/"/\\"/g;
			$e =~ s/'/\\'/g;
		}
		return "parent.s1('$func','" . $e . "', $heap->{msgid})\n";
	}else{
		return "$func " . escape($e) . "\n";
	}
}

sub wrap_output {
	my($heap, $output) = @_;
	return $output unless $heap->{type} eq 'iframe';
	return "<script>\n$output</script>\n<!-- padding -->\n";
}

1;
