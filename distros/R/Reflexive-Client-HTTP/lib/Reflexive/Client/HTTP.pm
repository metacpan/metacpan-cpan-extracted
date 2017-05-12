package Reflexive::Client::HTTP;
BEGIN {
  $Reflexive::Client::HTTP::AUTHORITY = 'cpan:GETTY';
}
{
  $Reflexive::Client::HTTP::VERSION = '0.007';
}
# ABSTRACT: A Reflex(ive) HTTP Client

our $VERSION ||= '0.000';


use Moose;
extends 'Reflex::Base';

use POE::Component::Client::HTTP;
use Reflex::POE::Event;
use Reflexive::Client::HTTP::ResponseEvent;

use HTTP::Request;
use HTTP::Response;

use Carp qw( croak );


has agent => (
	is      => 'ro',
	isa     => 'Str',
	default => sub { (ref $_[0] ? ref $_[0] : $_[0]).'/'.$VERSION },
);


has from => (
	is        => 'ro',
	isa       => 'Str',
	predicate => 'has_from',
);


has protocol => (
	is        => 'ro',
	isa       => 'Str',
	predicate => 'has_protocol',
);


has timeout => (
	is        => 'ro',
	isa       => 'Str',
	predicate => 'has_timeout',
);


has max_size => (
	is        => 'ro',
	isa       => 'Int',
	predicate => 'has_max_size',
);


has follow_redirects => (
	is        => 'ro',
	isa       => 'Int',
	predicate => 'has_follow_redirects',
);


has proxy => (
	is        => 'ro',
	isa       => 'ArrayRef[Str]|Str',
	predicate => 'has_proxy',
);


has no_proxy => (
	is        => 'ro',
	isa       => 'ArrayRef[Str]|Str',
	predicate => 'has_no_proxy',
);


has bind_addr => (
	is        => 'ro',
	isa       => 'Str',
	predicate => 'has_bind_addr',
);

my $alias_id = 0;

has _alias => (
	is      => 'ro',
	isa     => 'Str',
	default => sub { 'reflexive_client_http_alias_'.(++$alias_id) },
);

sub BUILD {
	my ($self) = @_;

	# Start an HTTP user-agent when the object is created.

	POE::Component::Client::HTTP->spawn(
		Agent => $self->agent,
		$self->has_from ? ( From => $self->from ) : (),
		$self->has_protocol ? ( Protocol => $self->protocol ) : (),
		$self->has_max_size ? ( MaxSize => $self->max_size ) : (),
		$self->has_timeout ? ( Timeout => $self->timeout ) : (),
		$self->has_follow_redirects ? ( FollowRedirects => $self->follow_redirects ) : (),
		$self->has_proxy ? ( Proxy => $self->proxy ) : (),
		$self->has_no_proxy ? ( NoProxy => $self->no_proxy ) : (),
		$self->has_bind_addr ? ( BindAddr => $self->bind_addr ) : (),

		Alias => $self->_alias,
	);
}

sub DESTRUCT {
	my ($self) = @_;

	# Shut down POE::Component::Client::HTTP when this object is
	# destroyed.

	POE::Kernel->post( ua => $self->_alias );
}


sub request {
	# Make a request.

	my ($self, $http_request, @args) = @_;

	# There is no guarantee that the caller of request() is running in
	# the same POE session as this Reflexive::Client::HTTP object.
	#
	# Reflex::Base's run_within_session() method makes sure that the
	# right session is active when interacting with POE code.  This
	# ensures that POE-based responses are properly routed.

	# The Reflex::POE::Event object created here is an event for POE's
	# purpose, but it includes Reflex magic to route responses back to
	# the correct Reflex object.

	$self->run_within_session(
		sub {
			POE::Kernel->post(
				$self->_alias,
				'request',
				Reflex::POE::Event->new(
					object => $self,
					method => '_internal_http_response',
					context => { args => [@args] },
				),
				$http_request,
			);
		}
	);
}

sub _internal_http_response {
	my ($self, $args) = @_;

	my @request_args = @{ $args->{context}->{args} };

	my ($request, $response) = @{ $args->{response} };

	if (defined $request_args[0] && ref $request_args[0] eq 'CODE') {
		my $callback = shift @request_args;
		for ($response->[0]) {
			my @return = $callback->(@request_args);
			if (@return && ref $return[0] eq 'HTTP::Request') {
				$self->request(@return);
			}
		}
	} else {
		$self->emit_response($request->[0],$response->[0],@request_args);
	}
}

sub emit_response {
	my ( $self, $request, $response, @args ) = @_;
	$self->emit(
		-name => 'response',
		-type    => 'Reflexive::Client::HTTP::ResponseEvent',
		request  => $request,
		response => $response,
		@args ? ( args => [@args] ) : (),
	);
}

__PACKAGE__->meta->make_immutable;

1;


__END__
=pod

=head1 NAME

Reflexive::Client::HTTP - A Reflex(ive) HTTP Client

=head1 VERSION

version 0.007

=head1 SYNOPSIS

  my $ua = Reflexive::Client::HTTP->new;

  for my $url (qw( http://duckduckgo.com/ http://perl.org/ )) {
    $ua->request(
      HTTP::Request->new( GET => $url ),
	  sub { print $url." gave me a ".$_->code."\n" },
    );
  }

  Reflex->run_all();

=head1 DESCRIPTION

Reflexive::Client::HTTP is an HTTP user-agent for L<Reflex>. At the current
state it is only a wrapper around L<POE::Component::Client::HTTP>, but we will
try to assure stability to the API.

=head1 ATTRIBUTES

=head2 agent

The useragent to use for the HTTP client. Defaults to the package name and the
current version of it.

=head2 from

C<from> holds an e-mail address where the client's administrator and/or
maintainer may be reached.  It defaults to undef, which means no From header
will be included in requests.

=head2 protocol

C<protocol> advertises the protocol that the client wishes to see. Under
normal circumstances, it should be left to its default value: "HTTP/1.1".

=head2 timeout

So far see L<POE::Component::Client::HTTP/Timeout>.

=head2 max_size

C<max_size> specifies the largest response to accept from a server. The
content of larger responses will be truncated to OCTET octets. This has been
used to return the <head></head> section of web pages without the need to wade
through <body></body>.

=head2 follow_redirects

C<follow_redirects> specifies how many redirects (e.g. 302 Moved) to follow.
If not specified defaults to 0, and thus no redirection is followed. This
maintains compatibility with the previous behavior, which was not to follow
redirects at all.

If redirects are followed, a response chain should be built, and can be
accessed through $event->response->previous() or $_->previous() if you use a
callback on L</request>. See L<HTTP::Response> for details here.

=head2 proxy

C<proxy> specifies one or more proxy hosts that requests will be passed
through.  If not specified, proxy servers will be taken from the B<HTTP_PROXY>
(or B<http_proxy>) environment variable. No proxying will occur unless
C<proxy> is set or one of the environment variables exists.

The proxy can be specified either as a host and port, or as one or more URLs.
C<proxy> URLs must specify the proxy port, even if it is 80.

  proxy => [ "127.0.0.1", 80 ],
  proxy => "http://127.0.0.1:80/",

C<proxy> may specify multiple proxies separated by commas.
L<Reflexive::Client::HTTP> will choose proxies from this list at random. This is
useful for load balancing requests through multiple gateways.

  proxy => "http://127.0.0.1:80/,http://127.0.0.1:81/",

=head2 no_proxy

C<no_proxy> specifies a list of server hosts that will not be proxied. It is
useful for local hosts and hosts that do not properly support proxying. If
C<no_proxy> is not specified, a list will be taken from the B<NO_PROXY>
environment variable.

  no_proxy => [ "localhost", "127.0.0.1" ],
  no_proxy => "localhost,127.0.0.1",

=head2 bind_addr

Specify C<bind_addr> to bind all client sockets to a particular local address.

=head1 METHODS

=head2 request

This function takes as first argument a L<HTTP::Request> and any additional
number of arguments you want to give. If you are accessing the client via
C<watches> then the args are in the
L<Reflexive::Client::HTTP::ResponseEvent/args> attribute.

If you give as first additional argumnet a CodeRef, then this one gets
executed instead of the emitting of the
L<Reflexive::Client::HTTP::ResponseEvent>. It gets all other additional
arguments of the C<request> call given as own arguments. Additionall we set
B<$_> to the L<HTTP::Response> object.

  $ua->request( HTTP::Request->new( GET => "http://duckduckgo.com/" ), sub {
    print "DuckDuckGo gave me ".$_->code."\n";
  });

If you require access to the L<HTTP::Request> object via this method, you need
to apply it as one of your arguments yourself on the call of C<request>

A special feature of this fuction is the option to directly chain it. If you
are using the CodeRef callback, you can return a new L<HTTP::Request> from
this CodeRef together with a new CodeRef and more arguments, to trigger
another request for another callback.

  $ua->request( HTTP::Request->new( GET => "http://duckduckgo.com/" ), sub {
    print "DuckDuckGo gave me ".$_->code."\n";
    return HTTP::Request->new( GET => "http://perl.org/" ), sub {
      print "Perl gave me ".$_->code."\n";
      return HTTP::Request->new( GET => "http://metacpan.org/" ), sub {
        print "MetaCPAN gave me ".$_->code."\n";
      };
    };
  });

=head1 SEE ALSO

L<Reflexive::Client::HTTP::Role>

L<HTTP::Request> L<HTTP::Response>

L<Reflex>

=head1 THANKS

Big thanks to B<dngor> for helping me through the process to understand
L<Reflex> enough for making this. Most of this is based on his code.

=head1 SUPPORT

IRC

  Join #reflex on irc.perl.org. Highlight Getty or dngor for fast reaction :).

Repository

  http://github.com/Getty/p5-reflexive-client-http
  Pull request and additional contributors are welcome

Issue Tracker

  http://github.com/Getty/p5-reflexive-client-http/issues

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

