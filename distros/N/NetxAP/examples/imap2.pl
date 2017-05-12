#!/usr/bin/perl -wI..

# This example illustrates using a callback to process "list" data.

use Net::IMAP;

my $host = '/usr/sbin/imapd';

my $imap = new Net::IMAP($host, Debug => 0)
  or die("can't connect to $host: $!\n");

$imap->set_untagged_callback('list', \&do_list);

$response = $imap->list('~/Mail/', '%')
  or warn("failed sending list command");
if ($response->status ne 'ok') {
  warn("list command returned ",
       $response->status, " ", $response->text, "\n");
}

$response = $imap->logout or die "error sending logout: $!";

sub do_list {
	my $self = shift;
	my $resp = shift;
	print "List: ", join(',', $resp->mailbox,
				  $resp->delimiter,
				  $resp->flags), "\n";
}
