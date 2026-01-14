##########################################################################
## All portions of this code are copyright (c) 2015,2016 nethype GmbH   ##
##########################################################################
## Using, reading, modifying or copying this code requires a LICENSE    ##
## from nethype GmbH, Franz-Werfel-Str. 11, 74078 Heilbronn,            ##
## Germany. If you happen to have questions, feel free to contact us at ##
## license@nethype.de.                                                  ##
##########################################################################

=head1 NAME

PApp::SCGI - use PApp in a SCGI environment

=head1 SYNOPSIS

  use PApp::SCGI;

  # initialize request and do initialization
  PApp::config_eval {
     configure PApp ...;
     #d#
     configured PApp;
  };

  # for every scgi request
  PApp::SCGI::handle $fh;

=head1 DESCRIPTION

=cut

package PApp::SCGI;

our $PREFIXMATCH; # regex to find prefix
our %PREFIX;
our $DOCROOT;

package PApp::SCGI::PApp;

use common::sense;
use PApp ();
use PApp::CGI (); # also modifies PApp::ISA

BEGIN {
   our @ISA = PApp::Base::;
   unshift @PApp::ISA, __PACKAGE__;
}

#d#
sub mount_agni_app {
   my ($self, $pathgid, $location) = @_;

   $self->mount (new PApp::Application::Agni path => $pathgid, name => $location);
}

sub mount {
   my ($self, $papp) = @_;

   $PREFIX{$papp->{name}} = $papp;

   $self->SUPER::mount ($papp);

}

sub configured {
   my ($self) = @_,

   $PREFIXMATCH = join "|", map quotemeta, keys %PREFIX;
   $PREFIXMATCH = qr{^($PREFIXMATCH)(/.*)$}s;

   $self->SUPER::configured;
}

package PApp::SCGI;

use common::sense;

use EV;
use AnyEvent;
use AnyEvent::Socket;

use PApp ();
use PApp::CGI ();

sub _error($$$$) {
   my ($fh, $hdr, $status, $msg) = @_;

   if ($hdr->{SCGI} eq "0") {
      printf $fh "HTTP/1.0 %s error\015\012Content-Type: text/plain\015\012\015\012%s", $status, $msg;
   } else {
      printf $fh "Status: %s\015\012Content-Type: text/plain\015\012\015\012%s", $status, $msg;
   }

   0
}

sub handle($) {
   my ($fh) = @_;

   my $rbuf;

   # the header must be at minimum length 28, which is enough to read the
   # netstring length, so we are in no danger of over-reading. we limit
   # ourselves to 6, to limit actual header size to 100k
   # note: we now also support http on the same socket
   sysread $fh, $rbuf, 6 - length $rbuf, length $rbuf
         or return _error $fh, { SCGI => "1" }, 500, "socket eof"
      while 6 > length $rbuf;

   my %hdr;

   if ($rbuf =~ s/^([0-9]+)://) {

      # now we know the length of the remaining header data
      my $len = $1 + 1;
      sysread $fh, $rbuf, $len - length $rbuf, length $rbuf
            or return _error $fh, { SCGI => "1" }, 500, "socket eof"
         while $len > length $rbuf;

      "\x00," eq substr $rbuf, -2, 2, "" # remove and check for trailing NUL ","
         or return _error $fh, { SCGI => "1" }, 500, "missing trailing comma";

      %hdr = split /\x00/, $rbuf;

      $hdr{SCGI} eq "1"
         or return _error $fh, { SCGI => "1" }, 500, "SCGI version mismatch";

   } else {
      # try http
      local $/ = "\015\012";
      while ("\015\012\015\012" ne substr $rbuf, -4) {
         # partial line reads are o.k.
         my $line = readline $fh;
         defined $line
            or return _error $fh, { SCGI => "0" }, 500, "http header read error";
         $rbuf .= $line;
      }

      # now $rbuf should be the https request ONLY
      $rbuf =~ /^(?:\015\012)?
                (GET|HEAD|POST) \040+
                ([^\040]+) \040+
                HTTP\/([0-9]+\.[0-9]+)
                \015\012/gx
         or return _error $fh, { SCGI => "0" }, 500, "http header parse error";

      $3 < 2
         or return _error $fh, { SCGI => "0" }, 500, "http protocol version $3 not supported";

      $hdr{REQUEST_METHOD} = $1;
      $hdr{REQUEST_URI}    =
      $hdr{DOCUMENT_URI}   = $2;
      $hdr{HTTP_VERSION}   = $3;

      {
         my %h;

         $h{$1 =~ y/a-z-/A-Z_/r} .= ",$2"
            while $rbuf =~ /\G
                  ([^:\000-\040]+):
                  [\011\040]*
                  ((?: [^\015\012]+ | \015\012[\011\040] )*)
                  \015\012
               /gxc;

         $rbuf =~ /\G\015\012\z/
            or return _error $fh, { SCGI => "0" }, 500, "bad request";

         my ($h, $v);
         $hdr{"HTTP_$h"} = substr $v, 1
            while ($h, $v) = each %h;
      }

      $hdr{SCGI} = "0"; # indicate http

      $hdr{QUERY_STRING} = $hdr{DOCUMENT_URI} =~ s/\?(.*)\z//s ? $1 : "";

      # CGI :(
      $hdr{CONTENT_LENGTH} = delete $hdr{HTTP_CONTENT_LENGTH};
      $hdr{CONTENT_TYPE  } = delete $hdr{HTTP_CONTENT_TYPE  };
   }

   if ($hdr{DOCUMENT_URI} =~ $PREFIXMATCH) {
      $hdr{SCRIPT_NAME} = $1;
      $hdr{PATH_INFO}   = $2;
      my $app = $PREFIX{$1};

      package PApp;
      our $request  = new_from PApp::CGI::Request \%hdr, stdin => $fh, stdout => $fh, nph => $hdr{SCGI} eq "0";
      our $location = $request->{name};
      our $pathinfo = $request->{path_info};
      our $papp     = $app;
      _handler;
      undef $request; # to free $fh
   } elsif (length $DOCROOT and $hdr{SCGI} eq "0") {
      # try to serve a static file

      my $uri = $hdr{DOCUMENT_URI};

      # resolve .. paths
      1 while $uri =~ s%/[^/]+/+\.\.(?:\z|/)%/%;
      $uri !~ m%(?:^|/)\.\.(?:\z|/)%
         or return  _error $fh, \%hdr, 500, "malformed uri";

      if (open my $file, "$DOCROOT/$uri") {
         require PApp::MimeType;

         my $len = -s $file;

         printf $fh "HTTP/1.1 200 OK\015\012Content-Length: %s\015\012Content-Type: %s\015\012Connection: close\015\012\015\012",
            $len, eval { PApp::MimeType::by_filename ($uri)->mimetype } || "application/octet-stream";

         if ($hdr{REQUEST_METHOD} ne "HEAD") {
            while (sysread $file, my $buf, $len > 16384 ? 16384 : $len) {
               print $fh $buf;
               $len -= length $buf;
            }
         }

      } else {
         return _error $fh, \%hdr, 404, "not found";
      }
   } else {
      return _error $fh, \%hdr, 404, "no app mounted on $hdr{DOCUMENT_URI} ($PREFIXMATCH)";
   }

   1
}

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

=cut

1

