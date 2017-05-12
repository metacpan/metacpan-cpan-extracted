#!/usr/bin/perl
# vim: filetype=perl

# Test the hosts file stuff.

use warnings;
use strict;
sub POE::Kernel::ASSERT_DEFAULT () { 1 }
use POE qw(Component::Client::DNS);
use Test::More tests => 5;
use Test::NoWarnings;

require Net::DNS;
my $can_resolve = Net::DNS::Resolver->new->search("poe.perl.org");

my %target_address;
if ($can_resolve) {
  foreach ($can_resolve->answer()) {
    $target_address{$_->address} = 1 if $_->type eq "A";
  }
}

use constant HOSTS_FILE => "./test-hosts";

my $resolver = POE::Component::Client::DNS->spawn(
  Alias     => 'named',
  Timeout   => 15,
  HostsFile => HOSTS_FILE,
);

POE::Session->create(
  inline_states  => {
    _start                  => \&start_tests,
    _stop                   => sub { }, # avoid assert problems
    response_no_hosts       => \&response_no_hosts,
    response_hosts_match_v4 => \&response_hosts_match_v4,
    response_hosts_match_v6 => \&response_hosts_match_v6,
    response_hosts_nomatch  => \&response_hosts_nomatch,
  }
);

POE::Kernel->run();
exit;

sub start_tests {
  # 1. Test without a hosts file.
  unlink HOSTS_FILE;

  $resolver->resolve(
    event   => "response_no_hosts",
    host    => "poe.perl.org",
    context => "whatever",
  );
}

sub response_no_hosts {
  my $response = $_[ARG0];
  my $address = a_data($response);
  SKIP: {
    skip "Can't resolve with Net::DNS, network probably not available", 1
      unless($can_resolve);
    ok(
      exists $target_address{$address},
      "lookup with no hosts file ($address)"
    );
  }

  # 2. Test with a hosts file that contains a host match.
  unlink HOSTS_FILE;  # Changes inode!
  open(HF, ">" . HOSTS_FILE) or die "couldn't write hosts file: $!";
  print HF "123.45.67.89 poe.perl.org\n";
  print HF "::1 hocallost\n";
  close HF;

  $resolver->resolve(
    event   => "response_hosts_match_v4",
    host    => "poe.perl.org",
    context => "whatever",
  );
}

sub response_hosts_match_v4 {
  my $response = $_[ARG0];
  my $address = a_data($response);

  ok(
    $address eq "123.45.67.89",
    "lookup when hosts file matches ($address)"
  );

  $resolver->resolve(
    event   => "response_hosts_match_v6",
    host    => "hocallost",
    context => "whatever",
    type    => "AAAA",
  );
}

sub response_hosts_match_v6 {
  my $response = $_[ARG0];
  my $address = aaaa_data($response);
  ok(
    ($address eq "0:0:0:0:0:0:0:1" or $address eq "::1"),
    "ipv6 lookup when hosts file matches ($address)"
  );

  # 3. Test against a hosts file without a host match.
  unlink HOSTS_FILE;  # Changes inode!
  open(HF, ">" . HOSTS_FILE) or die "couldn't write hosts file: $!";
  print HF "123.456.789.012 narf.barf.warf\n";
  close HF;

  $resolver->resolve(
    event   => "response_hosts_nomatch",
    host    => "poe.perl.org",
    context => "whatever",
  );
}

sub response_hosts_nomatch {
  my $response = $_[ARG0];
  my $address = a_data($response);
  SKIP: {
    skip "Can't resolve with Net::DNS, network probably not available", 1
      unless($can_resolve);
    ok(
      exists $target_address{$address},
      "lookup with hosts file but no match ($address)"
    );
  }

  unlink HOSTS_FILE;
}

### Not POE event handlers.

sub a_data {
  my $response = shift;
  return "" unless defined $response->{response};

  return (
    grep { ref() eq "Net::DNS::RR::A" } $response->{response}->answer()
  )[0]->rdatastr();
}


sub aaaa_data {
  my $response = shift;
  return "" unless defined $response->{response};
  return (
    grep { ref() eq "Net::DNS::RR::AAAA" } $response->{response}->answer()
  )[0]->rdatastr();
}


