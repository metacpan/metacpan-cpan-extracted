#!/usr/bin/perl -wI..

# This example script illustrates basic use of the Net::IMAP module.
# It shows how commands are issued, how the responses are checked, and
# how to configure callbacks to process data retrieved from the
# server.

# It assumes the use of the the University of Washington imap daemon,
# or any imap daemon that allows tty interaction with the daemon when
# invoked from the comand line.

use Net::IMAP;

my $host = '/usr/sbin/imapd';

my $imap = new Net::IMAP($host, Debug => 0)
  or die("can't connect to $host: $!\n");

$imap->set_untagged_callback('namespace', \&do_namespace);

$response = $imap->noop
  or die("noop failed");
print "noop returned: ", $response->status, "\n";
print "noop text: ", $response->text, "\n";

if ($imap->has_capability('namespace')) {
  $response = $imap->namespace
    or die("namespace command failed");
} else {
  warn("server doesn't implement namespace extension");
}

$response = $imap->logout
  or die "error sending logout: $!";

sub do_namespace {
	my $self = shift;
	my $resp = shift;

	print "Namespaces\n";
	print "  Personal:\n";
	for my $item (sort $resp->personal) {
	  printf("    %-12s %s\n", $item, $resp->personal($item));
	}
	print "  Other Users:\n";
	for my $item (sort $resp->other_users) {
	  printf("    %-12s %s\n", $item, $resp->other_users($item));
	}
	print "  Shared:\n";
	for my $item (sort $resp->shared) {
	  printf("    %-12s %s\n", $item, $resp->shared($item));
	}
}
