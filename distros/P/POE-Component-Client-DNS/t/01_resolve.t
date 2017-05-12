#!/usr/bin/perl -w

use strict;

use lib '/home/troc/perl/poe';
sub POE::Kernel::ASSERT_DEFAULT () { 1 }
use POE qw(Component::Client::DNS);
use Test::More tests => 4;
use Test::NoWarnings;

sub DNS_TIMEOUT () { 3 };
sub DEBUG       () { 0 };

#------------------------------------------------------------------------------
# A bunch of hostnames to resolve.

my @hostnames = qw(
  altavista.com google.com yahoo.com 127.0.0.1 10.0.0.25 localhost
  poe.dynodns.net poe.perl.org poe.whee efnet.demon.co.uk
  efnet.telstra.net.au irc.Prison.NET irc.best.net irc.ced.chalmers.se
  irc.colorado.edu irc.concentric.net irc.core.com irc.du.se
  irc.east.gblx.net irc.ef.net irc.emory.edu irc.enitel.no
  irc.etsmtl.ca irc.exodus.net irc.fasti.net irc.freei.net
  irc.gigabell.de irc.homelien.no irc.ins.net.uk irc.inter.net.il
  irc.lagged.org irc.lightning.net irc.magic.ca irc.mcs.net
  irc.mindspring.com irc.mpl.net irc.plur.net irc.powersurfr.com
  irc.rt.ru irc.skynetweb.com irc.stanford.edu irc.total.net
  irc.umich.edu irc.umn.edu irc.west.gblx.net irc2.home.com
  poe.dynodns.net poe.perl.org
);

#------------------------------------------------------------------------------
# This session uses the resolver component to resolve things.

sub client_start {
  my ($kernel, $heap) = @_[KERNEL, HEAP];

  # We should not hang even if we have an alias.
  $kernel->alias_set("oh, something");

  # Response types.
  $heap->{answers}       = 0;
  $heap->{timeouts}      = 0;
  $heap->{no_answers}    = 0;
  $heap->{errors}        = 0;

  # Response record types.
  $heap->{a_records}     = 0;
  $heap->{mx_records}    = 0;
  $heap->{cname_records} = 0;
  $heap->{other_records} = 0;

  # Post a bunch of requests all at once.  I have seen this fail with
  # more than 16 requests.

  foreach my $hostname (@hostnames) {
    $kernel->post(
      'resolver',  # Post the request to the 'resolver'.
      'resolve',   # Ask it to 'resolve' an address.
      'response',  # Have it post a reply to my 'response' state.
      $hostname,   # This is the host we are asking about.
      'ANY',       # This is the list of records we want.
    );
  }

  DEBUG and warn "client started...\n";

  # Start time to make sure the resolver's working in parallel.
  $heap->{start_time} = time();
}

sub client_got_response {
  my $heap = $_[HEAP];
  my $request_address = $_[ARG0]->[0];
  my ($net_dns_packet, $net_dns_resolver_errorstring) = @{$_[ARG1]};

  unless (defined $net_dns_packet) {
    DEBUG and warn
      sprintf(
        "%25s (%-10.10s) %s\n",
        $request_address, 'error', $net_dns_resolver_errorstring
      );
    if ($net_dns_resolver_errorstring eq 'timeout') {
      $heap->{timeouts}++;
    }
    else {
      $heap->{errors}++;
    }
    return;
  }

  my @answers = $net_dns_packet->answer;

  unless (@answers) {
    DEBUG and warn
      sprintf(
        "%25s (%-10.10s) %s\n",
        $request_address, '...none...', 'no resolver response'
      );
    $heap->{no_answers}++;
    return;
  }

  $heap->{answers}++;

  foreach (@answers) {
    my $response_data_string = $_->rdatastr;
    my $response_data_type   = $_->type;

    DEBUG and warn
      sprintf(
        "%25s (%-10.10s) %-s\n",
        $request_address, $_->type, $response_data_string
      );

    if ($response_data_type eq 'A') {
      $heap->{a_records}++;
    }
    elsif ($response_data_type eq 'MX') {
      $heap->{mx_records}++;
    }
    elsif ($response_data_type eq 'CNAME') {
      $heap->{cname_records}++;
    }
    else {
      $heap->{other_records}++;
    }
  }
}

sub client_stop {
  my $heap = $_[HEAP];

  if (DEBUG) {
    warn "answers      : $heap->{answers}\n";
    warn "timeouts     : $heap->{timeouts}\n";
    warn "no answers   : $heap->{no_answers}\n";
    warn "errors       : $heap->{errors}\n";
    warn "a records    : $heap->{a_records}\n";
    warn "mx records   : $heap->{mx_records}\n";
    warn "cname records: $heap->{cname_records}\n";
    warn "other records: $heap->{other_records}\n";
  }

	is(
		$heap->{answers} + $heap->{no_answers} +
		$heap->{timeouts} + $heap->{errors},
		scalar(@hostnames),
		"expected number of outcomes"
	);

	ok(
		$heap->{a_records} + $heap->{mx_records}
		+ $heap->{cname_records} + $heap->{other_records}
		>= $heap->{answers},
		"got enough records"
	);

  # Cut some slack for people running on really really slow systems.

	ok(
		time() - $heap->{start_time} < (DNS_TIMEOUT * @hostnames) / 2,
		"tests ran sufficiently quickly"
	);

  DEBUG and warn "client stopped...\n";
}

#------------------------------------------------------------------------------

# Create a resolver component.
POE::Component::Client::DNS->spawn(
  Alias       => 'resolver',     # This is the name it'll be know by.
  Timeout     => DNS_TIMEOUT,    # This is the query timeout.
);

# Create a session that will use the resolver.
POE::Session->create(
  inline_states => {
    _start   => \&client_start,
    _stop    => \&client_stop,
    response => \&client_got_response,
  }
);

# Run it all until done.
$poe_kernel->run();

exit;
