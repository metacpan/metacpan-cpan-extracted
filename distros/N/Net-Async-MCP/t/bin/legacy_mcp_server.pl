#!/usr/bin/env perl
# A strictly legacy MCP server for the tests: the initialize handshake of the
# 2024-11-05 .. 2025-11-25 revisions, hand-rolled JSON-RPC over stdin/stdout,
# and deliberately no part of the MCP distribution, whose server speaks the
# modern revision too. Configured through the environment:
#
#   LEGACY_MCP_VERSIONS  comma-separated revisions it accepts, newest first;
#                        initialize is answered with the requested one if it
#                        is among them, else with the first
#   LEGACY_MCP_DISCOVER  how server/discover is met: error (-32601, the
#                        default), silent (never answered), late (answered
#                        with a DiscoverResult only once initialize arrives,
#                        right before its answer), unsupported (-32022 naming
#                        LEGACY_MCP_VERSIONS)
#
# Everything but initialize, ping and test/transcript is refused until
# notifications/initialized has arrived, so a client that forgets it fails.
# test/transcript answers with every line received so far.
use strict;
use warnings;

use Cwd qw( getcwd );
use JSON::MaybeXS;

my $json     = JSON::MaybeXS->new(utf8 => 1, canonical => 1);
my @versions = split /,/, $ENV{LEGACY_MCP_VERSIONS}
  // '2025-11-25,2025-06-18,2025-03-26,2024-11-05';
my $discover = $ENV{LEGACY_MCP_DISCOVER} // 'error';

binmode STDIN,  ':raw';
binmode STDOUT, ':raw';
$| = 1;

print STDERR "legacy test server starting\n";

my ( @seen, $answered_initialize, $initialized, $late_discover );

sub send_message { print $json->encode({ jsonrpc => '2.0', %{ $_[0] } }), "\n" }

sub result { send_message({ id => $_[0], result => $_[1] }) }

sub error {
  my ( $id, $code, $message, $data ) = @_;
  send_message({ id => $id, error => {
    code    => $code,
    message => $message,
    defined $data ? ( data => $data ) : (),
  } });
}

sub text { return { content => [ { type => 'text', text => $_[0] } ] } }

sub read_message {
  my $line = <STDIN>;
  return unless defined $line;
  chomp $line;
  push @seen, $line;
  return eval { $json->decode($line) } // {};
}

my %tools = (
  echo => sub {
    my ( $args ) = @_;
    send_message({ method => 'notifications/message',
      params => { level => 'info', data => 'echoing' } });
    return text('Echo: ' . ( $args->{message} // '' ));
  },
  whoami => sub {
    my ( $args ) = @_;
    return text($json->encode({
      cwd => getcwd(),
      env => { map { $_ => $ENV{$_} } @{ $args->{vars} // [] } },
    }));
  },
  # Asks the client something and reports what came back - result or error -
  # as the tool's text.
  ask_client => sub {
    my ( $args ) = @_;
    my $id = 'srv-' . scalar @seen;
    send_message({ id => $id, method => $args->{method}, params => {} });
    while (defined( my $message = read_message() )) {
      next unless defined $message->{id} && $message->{id} eq $id;
      my %answer = map { exists $message->{$_} ? ( $_ => $message->{$_} ) : () }
        qw( result error );
      return text($json->encode(\%answer));
    }
    exit 0;
  },
  crash => sub {
    print STDERR "crash line $_\n" for 1 .. 25;
    exit 3;
  },
);

while (defined( my $message = read_message() )) {
  my ( $id, $method ) = @{$message}{qw( id method )};
  next unless defined $method;

  if ($method eq 'notifications/initialized') {
    $initialized = 1 if $answered_initialize;
    next;
  }
  next unless defined $id;

  if ($method eq 'test/transcript') {
    result($id, { lines => [@seen] });
  }
  elsif ($method eq 'ping') {
    result($id, {});
  }
  elsif ($method eq 'server/discover') {
    if    ($discover eq 'silent') { }
    elsif ($discover eq 'late')   { $late_discover = $id }
    elsif ($discover eq 'unsupported') {
      error($id, -32022, 'Unsupported protocol version',
        { supported => [@versions], requested => 'whatever' });
    }
    else { error($id, -32601, "Method not found: $method") }
  }
  elsif ($method eq 'initialize') {
    if (defined $late_discover) {
      result($late_discover, {
        supportedVersions => ['2026-07-28'],
        capabilities      => { tools => {} },
      });
      undef $late_discover;
    }
    my $asked  = $message->{params}{protocolVersion} // '';
    my ($agree) = grep { $_ eq $asked } @versions;
    $answered_initialize = 1;
    result($id, {
      protocolVersion => $agree // $versions[0],
      capabilities    => { tools => {} },
      serverInfo      => { name => 'LegacyServer', version => '1.0' },
      instructions    => 'Use echo to echo.',
    });
  }
  elsif (!$initialized) {
    error($id, -32600, "Server not initialized: $method before notifications/initialized");
  }
  elsif ($method eq 'tools/list') {
    result($id, { tools => [ map { {
      name        => $_,
      description => "The $_ tool",
      inputSchema => { type => 'object' },
    } } sort keys %tools ] });
  }
  elsif ($method eq 'tools/call') {
    my $tool = $tools{ $message->{params}{name} // '' };
    $tool ? result($id, $tool->($message->{params}{arguments} // {}))
          : error($id, -32602, 'Unknown tool');
  }
  else {
    error($id, -32601, "Method not found: $method");
  }
}
