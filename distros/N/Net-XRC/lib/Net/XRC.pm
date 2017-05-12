package Net::XRC;

use 5.005;
use strict;

use vars qw( $VERSION @ISA $AUTOLOAD $DEBUG $PROTO_VERSION $POST_URL
             @EXPORT_OK %EXPORT_TAGS ); # @EXPORT

use Exporter;

use LWP;

use Data::Dumper;

use Net::XRC::Response;

use Net::XRC::Data::list;

#use Net::XRC::Data::int;
use Net::XRC::Data::string;
use Net::XRC::Data::boolean;
#use Net::XRC::Data::null;
use Net::XRC::Data::bytes;
#use Net::XRC::Data::list;
use Net::XRC::Data::complex;

@ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Net::XRC ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
%EXPORT_TAGS = ( 'types' => [ qw(
  string boolean bytes complex
) ] );

@EXPORT_OK = ( @{ $EXPORT_TAGS{'types'} } );

#@EXPORT = qw(
#	
#);

$VERSION = '0.02';
$VERSION = eval $VERSION; # modperlstyle: convert the string into a number

$PROTO_VERSION = '1';
$POST_URL = 'https://xrc.everyone.net/ccc/xrc';

$DEBUG = 0;

my $ua = LWP::UserAgent->new;
$ua->agent("Net::XRC/$VERSION");
$ua->ssl_opts( verify_hostname => 0 );

=head1 NAME

Net::XRC - Perl extension for Everyone.net XRC Remote API

=head1 SYNOPSIS

  use Net::XRC qw(:types);  # pulls in type subroutines:
                            # string, boolean, bytes

  my $xrc = new Net::XRC (
    'clientID' => '1551978',
    'password' => 'password',
  );

  # noop

  my $response = $xrc->noop; #returns Net::XRC::Response object
  die $response->error unless $response->is_success;

  # isAccountName

  my $username = 'tofu_beast';
  my $response = $xrc->isAccountName( $clientID, $username );
  die $response->error unless $response->is_success;
  my $available = $res->content;
  if ( $available ) {
    print "$username is available\n";
  } else {
    print "$username is not available\n";
  }

  # isAccountName (numeric)
  # note the use of string() to force the datatype to string, which would
  # otherwise be (incorrectly) auto-typed as int

  my $numeric_username = '54321';
  my $response = $xrc->isAccountName( $clientID, string($numeric_username) );
  die $response->error unless $response->is_success;
  my $available = $res->content;
  if ( $available ) {
    print "$numeric_username is available\n";
  } else {
    print "$numeric_username is not available\n";
  }

  # createUser 

  my $username = 'tofu_beast';
  my $response = $xrc->createUser( $clientID, [], $username, 'password' );
  die $response->error unless $response->is_success;
  my $uid = $response->content;
  print "$username created: uid $uid\n";

  # createUser (numeric)
  # note the use of string() to force the datatype to string, which would
  # otherwise be (incorrectly) auto-typed as int

  my $numeric_username = '54321';
  my $response = $xrc->createUser( $clientID,
                                   [],
                                   string($numeric_username),
                                   'password'
                                 );
  die $response->error unless $response->is_success;
  my $uid = $response->content;
  print "$numeric_username created: uid $uid\n";

  # setUserPassword

  $response = $src->setUserPassword( $clientID, 'username', 'new_password' );
  if ( $response->is_success ) {
    print "password change sucessful";
  } else {
    print "error changing password: ". $response->error;
  }

  # suspendUser

  $response = $src->suspendUser( $clientID, 'username' );
  if ( $response->is_success ) {
    print "user suspended";
  } else {
    print "error suspending user: ". $response->error;
  }

  # unsuspendUser

  $response = $src->unsuspendUser( $clientID, 'username' );
  if ( $response->is_success ) {
    print "user unsuspended";
  } else {
    print "error unsuspending user: ". $response->error;
  }

  # deleteUser

  $response = $src->deleteUser( $clientID, 'username' );
  if ( $response->is_success ) {
    print "user deleted";
  } else {
    print "error deleting user: ". $response->error;
  }


=head1 DESCRIPTION

This module implements a client interface to Everyone.net's XRC Remote API,
enabling a perl application to talk to Everyone.net's XRC server.
This documentation assumes that you are familiar with the XRC documentation
available from Everyone.net (XRC-1.0.5.html or later).

A new Net::XRC object must be created with the I<new> method.  Once this has
been done, all XRC commands are accessed via method calls on the object.

=head1 METHODS

=over 4

=item new OPTION => VALUE ...

Creates a new Net::XRC object.  The I<clientID> and I<password> options are
required.

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self = { 'version' => $PROTO_VERSION,
               @_,
             };
  bless($self, $class);
}

=item AUTOLOADed methods

All XRC methods are available.  See the XRC documentation for methods,
arguments and return values.

Responses are returned as B<Net::XRC::Response> objects.  See
L<Net::XRC::Response>.

XRC I<int> arguments are auto-recognized as numeric perl scalars.

XRC I<string> arguments are auto-recognized as all other perl scalars, or
you can import and use the B<string()> subroutine to ensure your string is
not mistaken as an I<int>.

XRC I<null> are auto-recognized as undefined ("undef") perl scalars.

XRC I<boolean> arguements must be explicitly specified as B<boolean()>.

XRC I<bytes> arguments must be explicitly specified as B<bytes()>.

XRC I<list> arguments are passed and returned as perl array references.

XRC I<complex> arguments are passed and returned as perl hash references,
with an additional I<_type> key denotating the argument type 
(I<AliasInfo>, I<EmailClientSummary>, I<WebmailPresentation>, I<Letter>).
Optionally, you may use the B<complex()> subroutine to construct them, as in:
C<complex('typename', \%hash)>.

=cut

sub AUTOLOAD {

  my $self = shift;
  $AUTOLOAD =~ s/.*://;
  return if $AUTOLOAD eq 'DESTROY';

  my $req = HTTP::Request->new( 'POST' => $POST_URL );
  $req->content_type('application/x-eon-xrc-request');

  $req->content(
    join("\n", map { "$_:". $self->{$_} } keys %$self). #metadata
    "\n\n".
    $AUTOLOAD. # ' '.
    Net::XRC::Data::list->new(\@_)->encode
  );

  warn "\nPOST $POST_URL\n". $req->content. "\n"
    if $DEBUG;

  my $res = $ua->request($req);

  # Check the outcome of the response
  if ($res->is_success) {

    warn "\nRESPONSE:\n". $res->content
      if $DEBUG;

    my $response = new Net::XRC::Response $res->content;
    
    warn Dumper( $response )
      if $DEBUG;

    $response;
  }
  else {
    #print $res->status_line, "\n";
    die $res->status_line, "\n";
  }

}

sub string   { new Net::XRC::Data::string(  shift ); }
sub boolean  { new Net::XRC::Data::boolean( shift ); }
sub bytes    { new Net::XRC::Data::bytes(   shift ); }
sub complex  { 
  my $hr;
  if ( ref($_[0]) ) {
    $hr = shift;
  } else {
    $hr = { '_type' => shift,
            %{shift()},
          };
  }
  new Net::XRC::Data::complex( $hr );
}

=back

=head1 BUGS

Needs better documentation.

Data type auto-guessing can get things wrong for all-numeric strings.  I<bool>
and I<bytes> types must be specified explicitly.  Ideally each method should
have a type signature so manually specifying data types would never be
necessary.

The "complex" data types (I<AliasInfo>, I<EmailClientSummary>,
I<WebmailPresentation>, I<Letter>) are untested.

=head1 SEE ALSO

L<Net::XRC::Response>,
Everyone.net XRC Remote API documentation (XRC-1.0.5.html or later)

=head1 AUTHOR

Ivan Kohler E<lt>ivan-xrc@420.amE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 Ivan Kohler

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

