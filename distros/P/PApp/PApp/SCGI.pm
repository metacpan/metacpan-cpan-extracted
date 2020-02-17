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

sub _error($$) {
   my ($fh, $msg) = @_;

   print $fh <<EOF;
Status: 500
Content-Type: text/plain

$msg
EOF

   0
}

sub handle($) {
   my ($fh) = @_;

   my $rbuf;

   # the header must be at minimum length 28, which is enough to read the
   # netstring length, so we are in no danger of over-reading. we limit
   # ourselves to 6, to limit actual header size to 100k
   1 while sysread $fh, $rbuf, 6 - length $rbuf, length $rbuf;

   $rbuf =~ s/^(\d+)://
      or return _error $fh, "malformed netstring length";

   # now we know the length of the remaining header data
   my $len = $1 + 1;
   1 while sysread $fh, $rbuf, $len - length $rbuf, length $rbuf;

   "\x00," eq substr $rbuf, -2, 2, "" # remove and check for trailing NUL ","
      or return _error $fh, "missing trailing comma";

   my %hdr = split /\x00/, $rbuf;

   $hdr{DOCUMENT_URI} =~ $PREFIXMATCH;
   $hdr{SCRIPT_NAME} = $1;
   $hdr{PATH_INFO} = $2;

   my $app = $PREFIX{$1}
      or return _error $fh, "no app mounted on $hdr{DOCUMENT_URI} ($PREFIXMATCH)";

   {
      package PApp;
      our $request  = new_from PApp::CGI::Request \%hdr, stdin => $fh, stdout => $fh;
      our $location = $request->{name};
      our $pathinfo = $request->{path_info};
      our $papp     = $app;
      _handler;
      undef $request; # to free $fh
   }

   1
}

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

=cut

1

