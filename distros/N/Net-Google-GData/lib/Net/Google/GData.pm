package Net::Google::GData;

# ABSTRACT: Handle basic communication with Google services

use warnings;
use strict;

our $VERSION = '0.03'; # VERSION


use Carp;
use LWP::UserAgent;

use base qw( Class::Accessor  Class::ErrorHandler Net::Google::Authenticate );

__PACKAGE__->mk_accessors( qw(

) );


sub new {

  my ( $class, @data ) = @_;

  my $self = bless {}, ref $class || $class;

  # Set some defaults
  $self->accountType( $self->_default_accountType )
    or croak $self->errstr;

  $self->service( $self->_default_service )
    or carp $self->errstr;

  $self->source( 'Base GData Perl Package/' . $VERSION );

  for ( my $i = 0 ; $i < @data ; $i += 2 ) {

    if ( my $method = $self->can( $data[$i] ) ) {

      $self->$method( $data[ $i + 1 ] );

    }
  }

  return $self;

} ## end sub new


sub GET    { }
sub POST   { }
sub PUT    { }
sub DELETE { }


sub _ua {

  my $self = shift;

  my $ua;

  unless ( $ua = $self->SUPER::get( '_ua' ) ) {

    $ua = LWP::UserAgent->new;

    $self->SUPER::set( '_ua', $ua );

  }

  $ua->agent( $self->source );

  $self->_auth
    ? $ua->default_header( 'Authorization' => 'GoogleLogin auth=' . $self->_auth )
    : $ua->default_headers->remove_header( 'Authorization' );

  return $ua;

} ## end sub _ua

1;  # End of Net::Google::GData

__END__

=pod

=encoding utf-8

=for :stopwords Alan Young

=head1 NAME

Net::Google::GData - Handle basic communication with Google services

=head1 VERSION

  This document describes v0.03 of Net::Google::GData - released December 25, 2012 as part of Net-Google-GData.

=head1 SYNOPSIS

THIS MODULE IS NOT MAINTAINED ANYMORE

I fixed what was causing cpantesters to barf. I don't think the API this was written for is even valid anymore.

Net::Google::GData handles the basic communication details with Google services.

This module should normally only be used by modules subclassing GData.

=head1 DESCRIPTION

would go here

=head1 FUNCTIONS

=head2 new

Typical constructor.  You can optionally pass in a hash of data to set values.  Unknown
data/value pairs will be silently ignored.

=head2 GET

=head2 POST

=head2 PUT

=head2 DELETE

=head1 PRIVATE FUNCTIONS

=head2 _ua

Private method that creates and holds a LWP user agent.

Does not accept any parameters.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 AUTHOR

Alan Young <harleypig@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Alan Young.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT
WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER
PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND,
EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE
SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME
THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE
TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.

=cut
