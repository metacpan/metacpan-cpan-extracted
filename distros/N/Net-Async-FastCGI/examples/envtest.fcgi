#!/usr/bin/perl -w

use strict;

use IO::Async::Loop;

my $loop = IO::Async::Loop->new();

$loop->add( Example::EnvTestResponder->new( handle => \*STDIN ) );

$loop->run;

package Example::EnvTestResponder;
use base qw( Net::Async::FastCGI );

sub on_request
{
   my $self = shift;
   my ( $req ) = @_;

   my $env = $req->params();

   my $page = "";

   my $path = $env->{PATH_INFO} || "/";
   my $qs   = $env->{QUERY_STRING} || "";

   my %queryparams = map { m/^(.*?)=(.*)$/ && ( $1, $2 ) } split( m/&/, $qs );

   $page = "<h1>Request Variables</h1>\n";
   
   $page .= "<h2>Basics</h2>\n" .
           "<p>Path: <tt>$path</tt></p>\n";

   if ( keys %queryparams ) {
      $page .= "<h2>Query parameters</h2>\n" .
              "<table border=\"1\">\n";

      foreach my $key ( sort keys %queryparams ) {
         $page .= "<tr><td>$key</td><td><tt>$queryparams{$key}</tt></td></tr>\n";
      }

      $page .= "</table>\n";
   }

   $page .= "<h2>Environment variables</h2>\n";

   $page .= "<table>\n";

   foreach my $key ( sort keys %$env ) {
      $page .= "<tr><td>$key</td><td><tt>$env->{$key}</tt></td></tr>\n";
   }

   $page .= "</table>\n";

   $req->print_stdout(
      "Content-type: text/html\r\n" .
      "Content-length: " . length( $page ) . "\r\n" .
      "\r\n" .
      $page . "\r\n"
   );

   $req->finish();
}
