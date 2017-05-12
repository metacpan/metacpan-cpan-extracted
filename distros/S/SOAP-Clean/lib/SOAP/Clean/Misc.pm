# Copyright (c) 2003, Cornell University
# See the file COPYING for the status of this software

package SOAP::Clean::Misc;

use strict;
use warnings;

BEGIN {
  use Exporter   ();
  our (@ISA, @EXPORT);

  @ISA         = qw(Exporter);
  @EXPORT      = qw(
		    &assert
		    &backtrace
		    &my_cgifile_handler
		    &escape_HTML
		   );
}

sub backtrace {
  my $result = "";
  for (my $i=0; ; $i++) {
    my ($package, $filename, $line) = caller $i;
    if ( !defined($package) ) {
      return $result;
    }
    $result .= $package." ".$filename." ".$line."\n";
  }
}

sub assert {
  my ($x,$msg) = @_;
  if (defined($x) && $x) { return $x; }
  die ((defined($msg) ? $msg : "Assertion failed.")
       ." Backtrace follows.\n".backtrace());
}

sub escape_HTML {
  my ($str) = @_;
  $str =~ s/</&lt;/g;
  $str =~ s/>/&gt;/g;
  return $str;
}
########################################################################

#########################################################################
# A better file transport method for LWP.
#
# This one causes
#########################################################################

package my_cgifile_handler;

use strict;
use warnings;

use File::Temp qw/ :POSIX /;
use File::Basename;

use vars qw(@ISA);

require LWP::Protocol::file;
@ISA=qw(LWP::Protocol::file);

sub request {
    my($self, $request, $proxy, $arg, $size) = @_;

    LWP::Debug::trace('()');

    my $url = $request->url;

    # input and output temporary files
    my $in_name = tmpnam();
    my $out_name = tmpnam();
    my $err_name = tmpnam();
    # Generate the command to call the cgi script. CGI scripts read the
    # headers of the request from environment variables. So, we need to
    # set those.
    my $env = "";
    # Set the SERVER_ variables
    $env .= sprintf "SERVER_PROTOCOL=CGIFILE ";
    # REQUEST_METHOD={PUT,GET,...}
    $env .= sprintf "REQUEST_METHOD=%s ",$request->method;
    $env .= sprintf "REQUEST_URI=%s ",$url->path;
    # if URL was ...?xxx, the QUERY_STRING=xxx
    if ($url->query) {
      $env .= sprintf "QUERY_STRING=%s ",quotemeta($url->query);
    }
    # Add the rest of the headers as environment variables, after
    # converting "Some-Header:" to "HTTP_SOME_HEADER".
    $request->headers->scan(sub {
			     my ($k,$v) = @_;
			     $k =~ tr/a-z/A-Z/;
			     $k =~ tr/-/_/;
			     $env .= sprintf "HTTP_%s=%s ",
			       $k,quotemeta($v);
			   });
    # Now, the command.
    my $cmd .= sprintf "cd %s ; %s ./%s < %s > %s 2> %s", 
      dirname($url->path), $env, basename($url->path), 
	$in_name, $out_name, $err_name;

    # The input file must contains the content of the request.
    open F, ">$in_name" || assert(0);
    print F $request->content;
    print F "\n";
    close F || assert(0);

    # Run the command.
    my $status = system($cmd);

    my $response;
    if ($status == 0) {

      $response = new HTTP::Response(&HTTP::Status::RC_OK);

      # The CGI script prints the response to stdout. Headers are
      # followed by a blank line, then the content of the response
      # appears.
      open F, "<$out_name" || assert(0);
      my $seen_break = 0;
      while (<F>) {
	$_ =~ s/\r//g;
	if ( $seen_break ) {
	  $response->add_content($_);
	} elsif ( $_ =~ /^$/ ) {
	  $seen_break = 1;
	} else {
	  ($_ =~ /^(\S+)\s*:\s*(.*)/) || assert(0);
	  $response->header($1,$2);
	  if ( $1 eq "Status" ) {
	    my $status_text = $2;
	    ($status_text =~ /^([0-9]+)\s*(.*)/) || assert(0);
	    $response->code($1);
	    $response->message($2);
	  }
	}
      }
      close F || assert(0);

    } else {

      # The CGI script failed. Return code 500 and stderr.
      $response = new HTTP::Response(&HTTP::Status::RC_INTERNAL_SERVER_ERROR);
      $response->header("Content-Type","text/plain");
      open F, "<$err_name" || assert(0);
      while (<F>) {
	$response->add_content($_);
      }
      close F || assert(0);
    }

    unlink($in_name, $out_name, $err_name);
    return $response;
}

########################################################################

package SOAP::Clean::Misc::Object;

# fixmebad

# Inheritance
our @ISA = qw();

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self = {};
  bless $self, $class;
  $self->initialize(@_);
  return $self;
}

# "Virtual" methods
# $self->_print("message");

########################################################################

1;
