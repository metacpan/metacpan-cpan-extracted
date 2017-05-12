package POE::Declare::HTTP::Online;

=pod

=head1 NAME

POE::Declare::HTTP::Online - Does your POE process have access to the web

=head1 SYNOPSIS

    my $online = POE::Declare::HTTP::Online->new(
        Timeout      => 10,
        OnlineEvent  => \&handle_online,
        OfflineEvent => \&handle_offline,
        ErrorEvent   => \&handle_unknown,
    );
    
    $online->run;

=head1 DESCRIPTION

This is a port of L<LWP::Online> to L<POE::Declare>. It behaves similarly to
the original, except that it does not depend on LWP and can execute the HTTP
probes in parallel.

=cut

use 5.008;
use strict;
use Carp                            ();
use Params::Util               1.00 ();
use POE::Declare::HTTP::Client 0.06 ();

our $VERSION = '0.02';

use POE::Declare 0.54 {
	Timeout      => 'Param',
	Tests        => 'Param',
	OnlineEvent  => 'Message',
	OfflineEvent => 'Message',
	ErrorEvent   => 'Message',
	client       => 'Internal',
	result       => 'Internal',
};

# Default test websites, representing major global properties that
# should not dissapear often in the future. We can tolerate the
# loss of any 3-4 of these before this module stops working.
my @DEFAULT = (
	'http://google.com',
	'http://yahoo.com/',
	'http://cnn.com/',
	'http://microsoft.com/',
	'http://ibm.com/',
	'http://amazon.com/',
);





######################################################################
# Constructor and Accessors

=pod

=head2 new

    my $online = POE::Declare::HTTP::Online->new(
        Timeout      => 10,
        OnlineEvent  => \&handle_online,
        OfflineEvent => \&handle_offline,
        ErrorEvent   => \&handle_unknown,
    );

The C<new> constructor sets up a reusable HTTP online status checker that can
be run as often as needed.

Unless actively in use, the online detection object will not consume a L<POE>
session.

=cut

sub new {
	my $self = shift->SUPER::new(@_);

	unless ( defined $self->Timeout ) {
		$self->{Timeout} = 10;
	}
	unless ( defined $self->Tests ) {
		$self->{Tests} = [ @DEFAULT ];
	}
	unless ( Params::Util::_ARRAY($self->Tests) ) {
		Carp::croak("Missing or invalid 'Test' param");
	}

	# Pre-generate a client for each request
	$self->{client} = [
		map {
			POE::Declare::HTTP::Client->new(
				Timeout       => $self->Timeout - 1,
				MaxRedirect   => 0,
				ResponseEvent => $self->lookback('http_response'),
				ShutdownEvent => $self->lookback('http_shutdown'),
			)
		} $self->urls
	];

	return $self;
}

sub urls {
	@{ $_[0]->Tests };
}

sub clients {
	@{ $_[0]->{client} }
}

sub running {
	grep { $_->running } $_[0]->clients;
}





######################################################################
# Methods

=pod

=head2 run

The C<run> method starts the online detection process, spawning the L<POE>
session and initiating HTTP Test to each of the test URLs in parallel.

Once a determination has been made as to our online state (positive, negative
or unknown) and the reporting event has been fired, the session will be
terminated immediately.

=cut

sub run {
	my $self = shift;
	unless ( $self->spawned ) {
		$self->spawn;
	}
	return 1;
}





######################################################################
# Event Handlers

sub _start :Event {
	$_[SELF]->SUPER::_start(@_[1..$#_]);

	# Initialise state variables and boot the HTTP clients
	$_[SELF]->{result} = {
		online  => 0,
		offline => 0,
		unknown => scalar($_[SELF]->urls),
	};
	foreach my $client ( $_[SELF]->clients ) {
		$client->start;
	}

	$_[SELF]->post('startup');
}

sub startup :Event {
	$_[SELF]->timeout_start($_[SELF]->Timeout);
	my @url    = $_[SELF]->urls;
	my @client = $_[SELF]->clients;
	foreach ( 0 .. $#client ) {
		$client[$_]->GET($url[$_]);
	}
}

# We're so slow that we should assume we're not online
sub timeout :Timeout(10) {
	$_[SELF]->call( respond => 0 );
}

sub http_response :Event {
	my $alias    = $_[ARG0];
	my $response = $_[ARG1];
	my $result   = $_[SELF]->{result};

	# Do we have a conformant response
	if ( $_[SELF]->conformant($response) ) {
		$result->{online}++;
	} else {
		$result->{offline}++;
	}

	# Are we online?
	if ( $result->{online} >= 2 ) {
		return $_[SELF]->call( respond => 1 );
	}

	# Are there any active clients left
	if ( $_[SELF]->running ) {
		# No definite answer yet
		return;
	}

	# We are not online, so far as we can tell
	return $_[SELF]->call( respond => 0 );
}

sub http_shutdown :Event {
	# Are there any active clients left
	if ( $_[SELF]->running ) {
		# No definite answer yet
		return;
	}

	# We are not online, so far as we can tell
	return $_[SELF]->call( respond => 0 );	
}

sub respond :Event {
	$_[SELF]->{result} = undef;

	# Abort any requests still running
	foreach my $client ( $_[SELF]->clients ) {
		$client->stop;
	}

	# Send the reponse message
	if ( $_[ARG0] ) {
		$_[SELF]->OnlineEvent;
	} elsif ( defined $_[ARG0] ) {
		$_[SELF]->OfflineEvent;
	} else {
		$_[SELF]->ErrorEvent;
	}

	# Clean up
	$_[SELF]->finish;
}





######################################################################
# Support Methods

sub conformant {
	my $self = shift;

	# A successful response should result in a redirect.
	my $response = shift;
	unless ( Params::Util::_INSTANCE($response, 'HTTP::Response') ) {
		return 0;
	}
	unless ( $response->is_redirect ) {
		return 0;
	}

	# Determine the location we are relocating to
	my $request  = $response->request;
	my $location = $response->header('Location') or return 0;
	my $uri      = $HTTP::URI_CLASS->new($location);
	unless ( Params::Util::_INSTANCE($uri, 'URI') and $uri->can('host') ) {
		return 0;
	}

	# It should redirect to the matching www.domain.com for some given domain.com
	my $original = quotemeta $request->uri->host;
	unless ( $uri->host =~ /^(?:.+\.)?$original$/ ) {
		return 0;
	}

	return 1;
}

compile;

=pod

=head1 SUPPORT

Bugs should be always be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=POE-Declare-HTTP-Online>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<LWP::Simple>

=head1 COPYRIGHT

Copyright 2011 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
