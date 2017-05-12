package Net::Google::Authenticate;

# ABSTRACT: would go here

use warnings;
use strict;

our $VERSION = '0.03'; # VERSION


use Carp;

## no critic( Tics::ProhibitUseBase )
use base qw( Class::Accessor Class::ErrorHandler );

## no critic( Modules::RequireExplicitInclusion )
__PACKAGE__->mk_accessors( qw(

    Email Passwd source _auth

) );
## use critic


sub _valid_accountType { return qw( HOSTED GOOGLE HOSTED_OR_GOOGLE ) }

sub _default_accountType { return 'HOSTED_OR_GOOGLE' } ## no critic( Subroutines::ProhibitUnusedPrivateSubroutines )

sub accountType { ## no critic( Subroutines::RequireArgUnpacking )

  my $self = shift;

  return $self->SUPER::get( 'accountType' )
    unless @_;

  my $type = uc shift;

  my @valid = _valid_accountType;

  return $self->error( "Invalid accountType: $type" )
    unless grep { $type eq $_ } @valid;

  return $self->SUPER::set( 'accountType', $type );

}


sub _valid_service { return qw( cl blogger gbase wise apps lh2 xapi ) }

sub _default_service { return 'xapi' } ## no critic( Subroutines::ProhibitUnusedPrivateSubroutines )

sub service { ## no strict( Subroutines::RequireArgUnpacking )

  my $self = shift;

  return $self->SUPER::get( 'service' )
    unless @_;

  my $code = lc shift;

  my @known = _valid_service;

  $self->error( "Unknown service code: $code" )
    unless grep { $code eq $_ } @known;

  return $self->SUPER::set( 'service', $code );

}

#=head2 logintoken (optional)
#
#Not implemented at this time.
#
#=head2 logincaptcha (optional)
#
#Not implemented at this time.


sub login { ## no critic( Subroutines::RequireFinalReturn )

  my $self = shift;

  my @required = qw( accountType Email Passwd service source );

  ## no critic( TestingAndDebugging::ProhibitNoWarnings )
  no warnings 'uninitialized';

  my $missing = join ', ', grep { $self->$_ eq '' } @required;

  return $self->error( "Missing required fields: $missing" )
    if $missing;

  use warnings 'uninitialized';

  my %params = map { ( $_, $self->$_ ) } @required;

  no warnings 'uninitialized';

  my $r = $self->_ua->post( 'https://www.google.com/accounts/ClientLogin', \%params );

  if ( $r->code == 403 ) { ## no critic( ValuesAndExpressions::ProhibitMagicNumbers )

    my ( $error ) = $r->content =~ m!Error=(.+)(\s+|$)!i;

    return $self->error( "Invalid login: $error (" . _error_code( $error ) . ')' );

  } elsif ( $r->code == 200 ) { ## no critic( ValuesAndExpressions::ProhibitMagicNumbers )

    my ( $auth ) = $r->content =~ m!Auth=(.+)(\s+|$)!i;

    croak 'PANIC: Got a valid response from Google, but can\'t find Auth string'
      if $auth eq '';

    $self->_auth( $auth );

  } else {

    # If we get here then something's up with Google's website
    # http://code.google.com/apis/accounts/AuthForInstalledApps.html#Response
    # or else with our connection.

    croak 'PANIC: Got unexpected response (' . $r->code . ')';

  }
} ## end sub login


{
  my %codes = (

    'BadAuthentication' => 'The login request used a username or password that is not recognized.',

    'NotVerified' => 'The account email address has not been verified. The user will need to '
      . 'access their Google account directly to resolve the issue before logging '
      . 'in using a non-Google application.',

    'TermsNotAgreed' => 'The user has not agreed to terms. The user will need to access their '
      . 'Google account directly to resolve the issue before logging in using a '
      . 'non-Google application.',

    'CaptchaRequired' => 'A CAPTCHA is required. (A response with this error code will also contain '
      . 'an image URL and a CAPTCHA token.)',

    'Unknown' => 'The error is unknown or unspecified; the request contained invalid input ' . 'or was malformed.',

    'AccountDeleted' => 'The user account has been deleted.',

    'AccountDisabled' => 'The user account has been disabled.',

    'ServiceDisabled' => 'The user\'s access to the specified service has been disabled. (The user '
      . 'account may still be valid.)',

    'ServiceUnavailable' => 'The service is not available; try again later.',

  );

  sub _error_code {
    return exists $codes{ $_[1] } ? $codes{ $_[1] } : $codes{ 'Unknown' };
  } ## no critic( Subroutines::RequireArgUnpacking )

  sub _codes { return %codes } ## no critic( Subroutines::ProhibitUnusedPrivateSubroutines )

}

1;  # End of Net::Google::GData

__END__

=pod

=encoding utf-8

=for :stopwords Alan Young

=head1 NAME

Net::Google::Authenticate - would go here

=head1 VERSION

  This document describes v0.03 of Net::Google::Authenticate - released December 25, 2012 as part of Net-Google-GData.

=head1 SYNOPSIS

Net::Google::Authenticate handles the login procedures for Google services.

This module is a base class for Net::Google::GData.  Unless you want to write
your own GData module, or equivalent, you're not going to be using this module.

=head1 DESCRIPTION

A description would go here.

=head1 FUNCTIONS

=head2 accountType (required)

Valid values are B<HOSTED>, B<GOOGLE> or B<HOSTED_OR_GOOGLE>.

Defaults to B<HOSTED_OR_GOOGLE>.

=head2 Email (required)

Email address used as the login for the requested service.

=head2 Passwd (required)

Password used for the Email login for the requested service.

=head2 service (required)

Must be a valid service code, but only carps when it doesn't recognize a code
to allow for new services to be added.

Check the documentation for the service you're writing code for.  Also,
L<http://code.google.com/support/bin/answer.py?answer=62712&topic=10433>
has a list of service codes.

Currently known codes are as follows:

  Service                       Code
  ----------------------------  -------
  Calendar data API             cl
  Blogger data API              blogger
  Google Base data API          gbase
  Spreadsheets data API         wise
  Google Apps Provisioning API  apps
  Picasa Web Albums Data API    lh2
  Default Service               xapi

Defaults to B<xapi>.

=head2 login

Login to the google services page.

=head1 PRIVATE FUNCTIONS

=head2 _error_code

Takes an error code returned from Google and returns the explanatory text found at
L<http://code.google.com/apis/accounts/AuthForInstalledApps.html#Errors>.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Net::Google::GData|Net::Google::GData>

=back

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
