#!/usr/bin/perl

use strict;
use warnings;

use Net::Nmsg;

use FindBin;
use Sys::Hostname;
use Path::Class;
use Email::MIME;

# pick one of 'unknown', 'spamtrap', 'rej_network', 'rej_content', 'rej_user'
use constant EMAIL_TYPE => 'unknown';

my $hostname = hostname;
my $nmsgtool = "nmsgtool -d -d -V base -T email -f - -w " .
               "/var/spool/isc-sie/new/$hostname" .
               " -t 60 -k nmsg-sie-relay nmsg-sie-ch25";

my $url_re = qr{(https?://\S+?)(?:[\s'"<>\(\)\[\]])};

my %needed_headers;
++$needed_headers{$_} foreach (qw(
  Return-Path
  Delivered-To
  X-Hello
  X-Peer-Address
  X-Peer-Host
));

my $dir = shift;
if (!$dir || ! -d $dir) {
  print STDERR "usage: $FindBin::Script <dirname>\n";
  exit 1;
}
-d $dir || die "not a directory: $dir";
$dir = dir($dir);

my $shutdown;

$SIG{TERM} = $SIG{INT} = sub { ++$shutdown };

#open(P, ">&STDOUT") || die "oops on open : $!";

open(P, '|', $nmsgtool) or die "problem piping to nmsgtool : $!";
select(P); $|++;

while (1) {
  if ($shutdown) {
    close(P);
    exit;
  }
  for my $file ($dir->children) {
    my $msg = Email::MIME->new(scalar $file->slurp);
    my %unmatched = %needed_headers;
    my(%needed, %cooked);
    my @headers = $msg->header_pairs;
    while (@headers) {
      my($k, $v) = splice(@headers, 0, 2);
      if ($needed_headers{$k}) {
        delete $unmatched{$k};
        if ($k eq 'Delivered-To') {
          push(@{$needed{$k} ||= []}, $v);
        }
        else {
          $needed{$k} = $v;
        }
      }
      else {
        $cooked{$k} = $v;
      }
    }
    if (%unmatched) {
      printf STDERR "file=%s lacks needed headers (only saw %s)\n",
                    $file, join(', ', map { "$_:" } sort keys %needed);
      #$file->remove;
      next;
    }
    my $headers = join("\n", map { "$_:" } sort keys %cooked);
    $headers =~ s/\n\.\n/\n\.\.\n/sg;
    chomp $headers;
    print P 'type: ', EMAIL_TYPE, "\n";
    print P 'srcip: ', $needed{'X-Peer-Address'}, "\n"
      if $needed{'X-Peer-Address'};
    print P 'srchost: ', $needed{'X-Peer-Host'}, "\n"
      if $needed{'X-Peer-Host'};
    print P 'helo: ', $needed{'X-Hello'}, "\n"
      if $needed{'X-Hello'};
    print P 'from: ', $needed{'Return-Path'}, "\n"
      if $needed{'Return-Path'};
    for my $r (@{$needed{'Delivered-To'} || []}) {
      print P "rcpt: $r\n";
    }
    for my $url (extract_urls($msg)) {
      print P "bodyurl: $url\n";
    }
    print P "headers:\n$headers\n" if $headers;
    print P "\n";
    print STDERR "file=$file\n";
    #$file->remove;
  }
  exit;
  sleep(rand(4) + 1);
}

sub extract_urls {
  my $msg = shift || return;
  my %urls;
  for my $p (pull_parts($msg)) {
    ++$urls{$_} for $p =~ /$url_re/sgi;
  }
  sort keys %urls;
}

sub pull_parts {
  my @m = @_;
  my @parts;
  my $drill = sub {
    while (@m) {
      my $m = pop @m;
      for my $p ($m->parts) {
        if ($p->content_type =~ m{^message/}i) {
          push(@m, Email::MIME->new($p->body_raw));
        }
        elsif ($p->content_type =~ m{text/plain}i) {
          push(@parts, $p->body_str);
        }
      }
    }
    @parts;
  };
  $drill->();
}
