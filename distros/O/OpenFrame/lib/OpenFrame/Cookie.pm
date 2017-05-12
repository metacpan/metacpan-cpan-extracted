package OpenFrame::Cookie;

use strict;
use warnings::register;

use CGI::Cookie;
use base qw ( CGI::Cookie );

our $VERSION=3.05;

sub value {
  my $self = shift;
  my $val  = shift;

  if (defined($val) && !ref($val)) {
    return $self->SUPER::value( [ $val ] );
  } elsif(defined($val) && ref($val)) {
    return $self->SUPER::value( $val, @_ );
  } else {
    return $self->SUPER::value( $val, @_ );
  }
}

1;

__END__

=head1 NAME

OpenFrame::Cookie - An abstract cookie

=head1 SYNOPSIS

  my $colour = $cookies->get("colour")->value;

=head1 DESCRIPTION

This class is used internally in OpenFrame to hold a cookie. An
C<OpenFrame::Cookie> object is returned when you fetch a cookie from a
C<OpenFrame::Cookies> object.

This class is a subclass of C<CGI::Cookie>. You should call its
value() method to get the value.

=head1 AUTHOR

James Duncan <jduncan@fotango.com>

=cut
