#!/usr/bin/perl -w
use strict;
use Test::More tests => 4;
use Data::Dumper;

use Net::Pcap;
diag 'Using ' . &Net::Pcap::lib_version;
use Net::Pcap::FindDevice;
use LWP::Simple;

use Sniffer::HTTP;
use Net::Pcap::FindDevice;
if ($^O ne "MSWin32" and $> != 0) {
    diag "We are not root. find_device() might be unreliable and tests might fail.";
};

my $name;
my $ok = eval { $name = find_device(); 1 };
{
    my $err = $@;
    if (not $ok) {
        SKIP: {
            skip "Did not find any capture device", 4;
        };
        exit
    };
};

my $s = Sniffer::HTTP->new(
  callbacks => {
    log      => sub { diag "HTTP: $_[0]" },
    tcp_log  => sub { diag "TCP : $_[0]" },
    request  => \&collect_request,
    response => \&collect_response,
  },
);

my (@responses,@requests);
sub collect_response {
  my ($res,$req,$conn) = @_;
  push @responses, [$res,$req];
  diag "Breaking out of Pcap loop";
  Net::Pcap::breakloop($s->pcap_device);
};
sub collect_request {
  my ($req,$conn) = @_;
  diag "Got request";
  push @requests, $req;
};


my $url = 'http://www.cpan.org/';
diag "*** Doing live capture of an LWP request to $url";
diag "*** If that is blocked or you live behind a proxy, this test will fail.";
diag "*** The dump-to-file feature is untested then.";

my $dumpfile = 't/05-capture_to_file.dump';
if (-f $dumpfile) {
  diag "Removing old dumpfile '$dumpfile'";
  unlink $dumpfile
    or diag "Couldn't remove '$dumpfile': $!";
};

my $dev = eval { find_device() };
{
    my $err = $@;
    if (not is $err, '', "No error looking for device") {
        SKIP: {
	    skip $err, 3
	};
	exit
    };
}

diag "Using device '$dev'";
SKIP: {
    if ($ENV{HTTP_PROXY}) {
        skip "Proxy settings detected - sniffing will not work", 3;
    };

    my $failed;

    # This version of fork() works even on Win32:
    if (fork()) {
      alarm 65; # Emergency breakout
      eval {
          $s->run($dev,"((dst www.cpan.org || src www.cpan.org)) && (tcp port 80)", capture_file => $dumpfile);
      };
      $failed = $@;
      alarm 0;
    } else {
      diag "Launching request to '$url'";
      sleep 1;
      alarm 55; # Emergency breakout
      get $url or diag "Couldn't retrieve '$url'";
      diag "Child done.";
      alarm 0;
      exit;
    };

    SKIP: {
        if ($failed && $< != 0) {
            diag "Couldn't sniff: $failed";
            diag "Are you sure you have the proper permissions?";
            diag "Maybe you need to be root to get the proper permissions. Your user id is $<";
            skip "Couldn't sniff: $failed", 3;
        } else {
            ok -f $dumpfile, "A dump was created in '$dumpfile'";
    
            my @stale = $s->stale_connections();
            is_deeply(\@stale,[],"No stale connections");
    
            my @live = $s->live_connections();
            # Well, not actually, but close enough. The live connection
            # gets closed one TCP packet later, but we trigger the break
            # out of the loop too early for that.
            is scalar(@live), 1, "One live connection";
    
            if (-f $dumpfile) {
                diag "Removing dumpfile '$dumpfile'";
                unlink $dumpfile
                  or diag "Couldn't remove '$dumpfile': $!";
            };
        };
    };
};
