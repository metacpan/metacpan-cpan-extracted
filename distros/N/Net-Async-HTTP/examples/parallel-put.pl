#!/usr/bin/perl

use strict;
use warnings;

=pod

A slightly longer example demonstrating multiple L<Net::Async::HTTP> clients running in parallel. Given a base URL,
this will recursively (breadth-first) scan any paths given on the command line and PUT whatever files are found.

The resulting file structure will be flattened, there's no attempt to MKCOL the equivalent path structure on the
target server.

=cut

use URI;
use Async::MergePoint;
use IO::Async::Loop;
use IO::Async::Timer::Periodic;
use Net::Async::HTTP;
use POSIX qw(floor);
use Time::HiRes qw(time);
use Scalar::Util qw(weaken);
use File::Basename qw(basename);
use Format::Human::Bytes;
use Getopt::Std;

# Basic commandline parameter support:
# * -u user:password
# * -n number of workers to start
getopt('u:n:', \my %opts);

@ARGV || die <<"USAGE";
Net::Async::HTTP PUT client example.

Usage:

 $0 [-u user:pass] -n 8 http://dav.example.com file*.txt directory1 directory2

If -u options are given, these will be sent as Basic auth credentials. Different ports can be specified in the URL,
e.g. http://example.com:12314/file.txt.

The -n option specifies how many parallel connections to open (default is a single connection only).

USAGE

my $loop = IO::Async::Loop->new;

# Bytes transferred so far
my $total = 0;

# Define some workers
$opts{n} ||= 1;
my @ua = map { Net::Async::HTTP->new } 1..$opts{n};
$loop->add( $_ ) for @ua;

my $start = time;

# Used for pretty-printing, not essential if you don't have it installed
my $fhb = Format::Human::Bytes->new;

# The clients are added to this, and marked as done by the workers once the current file has finished and there is nothing
# else left in the queue. Bit of a hack to pass the raw Net::Async:HTTP objects but since they each stringify to a different
# value it does the job for now, should perhaps pass an ID or something instead.
my $mp = Async::MergePoint->new(
   needs        => \@ua,
   on_finished => sub {
      my $elapsed = time - $start;
      print "All done - " . $fhb->base2($total) . " in $elapsed seconds, " . $fhb->base2($total / $elapsed) . "/sec\n";
      $loop->loop_stop;
   }
);

# Expect a URL and a list of files as parameters
my ($base_url, @todo) = @ARGV;

# Start each worker off
queue_next_item($_) for @ua;

# Give a rough idea of progress
my $timer = IO::Async::Timer::Periodic->new(
   interval => 10,
   on_tick => sub {
      my $elapsed = time - $start;
      print ">> Transferred " . $fhb->base2($total) . " bytes in $elapsed seconds, " . $fhb->base2($total / $elapsed, 2) . "/sec\n";
   },
);
$loop->add($timer);
$timer->start;

# And begin looping
$loop->loop_forever;
exit;

# Get next item from the queue and make the request
sub queue_next_item {
   my $ua = shift;

   while(@todo) {
      my $path = shift(@todo);
      return send_file($ua, $path) if -f $path;
      push @todo, glob "$path/*";
      print "Add directory $path, queue now " . @todo . "\n";
   }
   $mp->done($ua);
}

# Generate the request for the given UA and send it 
sub send_file {
   my $ua = shift;
   my $path = shift;

   # We'll send the size as the Content-Length, and get the filehandle ready for reading
   my $size = (stat $path)[7];
   open my $fh, '<', $path or die "failed to open source file $path: $!";
   binmode $fh;

   # Prepare our request object
   my $uri = URI->new($base_url . '/' . basename($path)) or die "Invalid URL?";
   my $req = HTTP::Request->new(
      PUT => $uri->path, [
         'Host'      => $uri->host,
         # Send as binary to avoid any text-mangling process, should be overrideable from the commandline though
         'Content-Type' => 'application/octetstream'
      ]
   );
   # Default is no protocol, we insist on HTTP/1.1 here, PUT probably requires that as a minimum anyway
   $req->protocol('HTTP/1.1');
   $req->authorization_basic(split /:/, $opts{u}, 2) if defined $opts{u};
   $req->content_length($size);

   weaken $ua;
   $ua->do_request(
      request    => $req,
      # Probably duplicating a load of logic here :(
      host       => $uri->host,
      port       => $uri->port || $uri->scheme || 80,
      SSL        => $uri->scheme eq 'https' ? 1 : 0,

      # We override the default behaviour (pulling content from HTTP::Request) by passing a callback explicitly
      request_body => sub {
         my ($stream) = @_;

         # This part is the important one - read some data, and eventually return it
         my $read = sysread $fh, my $buffer, 32768;
         $total += $read // 0;
         return $buffer if $read;

         # Don't really need to close here, but might as well clean up as soon as we're ready
         close $fh or warn $!;
         undef $fh;
         return;
      },

      on_response => sub {
         my ($response) = @_;
         if($fh) {
            close $fh or die $!;
         }
         my $msg = $response->message;
         $msg =~ s/\s+/ /ig;
         $msg =~ s/(?:^\s+)|(?:\s+$)//g; # trim
         print $response->code . " for $path ($size bytes) - $msg\n";

         # haxx: if we get a server error, just repeat.
         push @todo, $path if $response->code == 500;

         queue_next_item($ua);
      },

      on_error => sub {
         my ( $message ) = @_;
         if($fh) {
            close $fh or die $!;
         }

         print STDERR "Failed - $message\n";
         # Could do a $loop->loop_stop here - some failures should be fatal!
         queue_next_item($ua);
      }
   );
}

