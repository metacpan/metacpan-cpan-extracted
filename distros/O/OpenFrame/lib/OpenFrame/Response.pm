package OpenFrame::Response;

use strict;
use warnings::register;

use Exporter;
use OpenFrame::Object;
use Pipeline::Production;
use base qw ( OpenFrame::Object Pipeline::Production Exporter );

our $VERSION=3.05;

use constant ofOK       => 1;
use constant ofREDIRECT => 2;
use constant ofDECLINE  => 4;
use constant ofERROR    => 8;

##
## we export this because its good
##
our @EXPORT = qw ( ofOK ofREDIRECT ofDECLINE ofERROR );

sub last_modified { }

sub cookies {
  my $self = shift;
  my $cookies = shift;
  if (defined( $cookies )) {
    $self->{cookies} = $cookies;
    return $self;
  } else {
    return $self->{cookies};
  }
}

sub mimetype {
  my $self = shift;
  my $mime = shift;
  if (defined( $mime )) {
    $self->{mimetype} = lc $mime;
    return $self;
  } else {
    return $self->{mimetype};
  }
}

sub contents {
  my $self = shift;
  return $self;
}

sub message {
  my $self = shift;
  my $mesg = shift;
  if (defined( $mesg )) {
    $self->{ mesg } = $mesg ;
    return $self;
  } else {
    my $msg = $self->{ mesg };
    return ref($msg) ? $$msg
                      : $msg;
  }
}

sub code {
  my $self = shift;
  my $code = shift;
  if (defined( $code )) {
    $self->{ code } = $code;
    return $self;
  } else {
    return $self->{ code }
  }
}


##
## for backwards compatibility we have a package called
##  OpenFrame::Constants
##
package OpenFrame::Constants;


1;

__END__

=head1 NAME

OpenFrame::Response - An abstract response class

=head1 SYNOPSIS

  use OpenFrame;
  use OpenFrame::Constants;
  my $r = OpenFrame::Response->new();
  $r->message("<html><body>Hello world!</body></html>");
  $r->mimetype('text/html');
  $r->code(ofOK);
  $r->cookies(OpenFrame::Cookies->new());

=head1 DESCRIPTION

C<OpenFrame::Response> represents responses inside
OpenFrame. Responses represent some kind of response following a
request for information.

This module abstracts the way clients can respond with data from
OpenFrame.

=head1 METHODS

=head2 new()

This method creates a new C<OpenFrame::Response> object. It
takes no parameters.

=head2 cookies()

This method gets and sets the C<OpenFrame::Cookietin> that is
associated with this response.

  my $cookietin = $r->cookies();
  $r->cookies(OpenFrame::Cookies->new());

=head2 message()

This method gets and sets the message string associated with this response.
A scalar reference can be stored. It will always be returned as a scalar.

  my $message = $r->message();
  $r->message("<html><body>Hello world!</body></html>");

=head2 code()

This method gets and sets the message code associated with this
response. The following message codes are exported when you use
C<OpenFrame::Constants>: ofOK, ofERROR, ofREDIRECT, ofDECLINE.

  my $code = $r->code();
  $r->code(ofOK);

=head2 mimetype()

This method gets and sets the MIME type associated with this response.

  my $type = $r->mimetype();
  $r->mimetype('text/html');

=head1 AUTHOR

James Duncan <jduncan@fotango.com>

=cut
