#!/usr/bin/perl

use strict;
use warnings;

use URI;

use IO::Async::Loop;
use Net::Async::HTTP;

use POSIX qw( floor );
use Time::HiRes qw( time );
use Getopt::Long;

sub usage
{
   my ( $exitcode ) = @_;

   print STDERR <<"EOF";
Net::Async::HTTP PUT client example.

Usage:

 $0 [-u user:pass] https://example.com/file-to-put.bin /tmp/file-to-read.bin

If -u options are given, these will be sent as Basic auth credentials.
Different ports can be specified in the URL, e.g.

  http://example.com:12314/file.txt

EOF
}

# Basic commandline parameter support - -u user:password
my $userpass;
my $url;
my $src;
my $contenttype = "application/octet-stream";

GetOptions(
   'userpass|u=s' => \$userpass,
   'src=s'        => \$src,
   'type|t=s'     => \$contenttype,

   'help|h' => sub { usage(0) },
) or usage(1);

my $loop = IO::Async::Loop->new;

$url = shift @ARGV or usage(1);
$src = shift @ARGV or usage(1) if !defined $src;

my $ua = Net::Async::HTTP->new;
$loop->add( $ua );

# We'll send the size as the Content-Length, and get the filehandle ready for reading
my $size = (stat $src)[7];
open my $fh, '<', $src or die "Failed to open source file $src - $!\n";
binmode $fh;

# Prepare our request object
my $uri = URI->new($url) or die "Invalid URL?\n";
my $req = HTTP::Request->new(
   PUT => $uri->path, [
      'Host'         => $uri->host,
      'Content-Type' => $contenttype,
   ]
);

# Default is no protocol, we insist on HTTP/1.1 here, PUT probably requires that as a minimum anyway
$req->protocol( 'HTTP/1.1' );
$req->authorization_basic( split m/:/, $userpass, 2 ) if defined $userpass;
$req->content_length( $size );

# For stats
my $total = 0;
my $last = -1;
my $start;

$ua->do_request(
   request    => $req,
   host       => $uri->host,
   port       => $uri->port,
   SSL        => $uri->scheme eq 'https' ? 1 : 0,

   # We override the default behaviour (pulling content from HTTP::Request) by passing a callback explicitly
   # Originall had "content_callback", not really sure what the best thing to call this would be though.
   request_body => sub {
      my ($stream) = @_;
      unless (defined $start) {
         $start = time;
         $| = 1;
      }

      # This part is the important one - read some data, and eventually return it
      my $read = sysread $fh, my $buffer, 1048576;

      # Just for stats display, update every mbyte
      $total += $read;
      my $step = floor($total / 1048576);
      if($step > $last) {
         $last = $step;
         my $elapsed = (time - $start) || 1;
         printf("Total: %14d of %14d bytes, %5.2f%% complete, %9.3fkbyte/s   \r", $total, $size, (100 * $total) / $size, ($total) / ($elapsed * 1024));
      }

      return $buffer if $read;

      # Return undef when we're done
      print "\n\nComplete.\n";
      return;
   },
   on_response => sub {
      my ( $response ) = @_;

      close $fh or die $!;
      print $response->as_string;
   },

   on_error => sub {
      my ( $message ) = @_;

      print STDERR "Failed - $message\n";
   }
)->get;
