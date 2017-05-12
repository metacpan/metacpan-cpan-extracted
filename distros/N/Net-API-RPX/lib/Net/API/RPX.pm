use 5.006;
use strict;
use warnings;

package Net::API::RPX;

# ABSTRACT: Perl interface to Janrain's RPX service

our $VERSION = '1.000001';

our $AUTHORITY = 'cpan:KONOBI'; # AUTHORITY

use Moose qw( has );
use LWP::UserAgent;
use URI;
use JSON::MaybeXS qw( decode_json );
use Net::API::RPX::Exception::Usage;
use Net::API::RPX::Exception::Network;
use Net::API::RPX::Exception::Service;








has api_key => (
  is       => 'rw',
  isa      => 'Str',
  required => 1,
);







has base_url => (
  is       => 'rw',
  isa      => 'Str',
  required => 1,
  lazy     => 1,
  default  => 'https://rpxnow.com/api/v2/',
);








has ua => (
  is       => 'rw',
  isa      => 'Object',
  required => 1,
  lazy     => 1,
  builder  => '_build_ua',
);

sub _build_ua {
  my ($self) = @_;
  return LWP::UserAgent->new( agent => $self->_agent_string );
}

has _agent_string => (
  is       => 'rw',
  isa      => 'Str',
  required => 1,
  lazy     => 1,
  default  => sub { 'net-api-rpx-perl/' . $Net::API::RPX::VERSION },
);

__PACKAGE__->meta->make_immutable;
no Moose;












sub auth_info {
  my ( $self, $opts ) = @_;
  Net::API::RPX::Exception::Usage->throw(
    ident              => 'auth_info_usage_needs_token',
    message            => 'Token is required',
    required_parameter => 'token',
    method_name        => '->auth_info',
    package            => __PACKAGE__,
    signature          => '{ token => \'authtoken\' }',
  ) if !exists $opts->{token};
  return $self->_fetch( 'auth_info', $opts );
}











sub map {    ## no critic (Subroutines::ProhibitBuiltinHomonyms)
  my ( $self, $opts ) = @_;
  Net::API::RPX::Exception::Usage->throw(
    ident              => 'map_usage_needs_identifier',
    message            => 'Identifier is required',
    required_parameter => 'identifier',
    method_name        => '->map',
    package            => __PACKAGE__,
    signature          => '{ identifier => \'some.open.id\', primary_key => 12 }',
  ) if !exists $opts->{identifier};

  Net::API::RPX::Exception::Usage->throw(
    ident              => 'map_usage_needs_primary_key',
    message            => 'Primary Key is required',
    required_parameter => 'primary_key',
    method_name        => '->map',
    package            => __PACKAGE__,
    signature          => '{ identifier => \'some.open.id\', primary_key => 12 }',
  ) if !exists $opts->{primary_key};
  $opts->{primaryKey} = delete $opts->{primary_key};

  return $self->_fetch( 'map', $opts );
}











sub unmap {
  my ( $self, $opts ) = @_;
  Net::API::RPX::Exception::Usage->throw(
    ident              => 'unmap_usage_needs_identifier',
    message            => 'Identifier is required',
    required_parameter => 'identifier',
    method_name        => '->unmap',
    package            => __PACKAGE__,
    signature          => '{ identifier => \'some.open.id\', primary_key => 12 }',
  ) if !exists $opts->{identifier};

  Net::API::RPX::Exception::Usage->throw(
    ident              => 'unmap_usage_needs_primay_key',
    message            => 'Primary Key is required',
    required_parameter => 'primary_key',
    method_name        => '->unmap',
    package            => __PACKAGE__,
    signature          => '{ identifier => \'some.open.id\', primary_key => 12 }',
  ) if !exists $opts->{primary_key};

  $opts->{primaryKey} = delete $opts->{primary_key};

  return $self->_fetch( 'unmap', $opts );
}











sub mappings {
  my ( $self, $opts ) = @_;
  Net::API::RPX::Exception::Usage->throw(
    ident              => 'mappings_usage_needs_primary_key',
    message            => 'Primary Key is required',
    required_parameter => 'primary_key',
    method_name        => '->mappings',
    package            => __PACKAGE__,
    signature          => '{ primary_key => 12 }',
  ) if !exists $opts->{primary_key};

  $opts->{primaryKey} = delete $opts->{primary_key};

  return $self->_fetch( 'mappings', $opts );
}

my $rpx_errors = {
  -1 => 'Service Temporarily Unavailable',
  0  => 'Missing parameter',
  1  => 'Invalid parameter',
  2  => 'Data not found',
  3  => 'Authentication error',
  4  => 'Facebook Error',
  5  => 'Mapping exists',
};

sub _fetch {
  my ( $self, $uri_part, $opts ) = @_;

  my $uri = URI->new( $self->base_url . $uri_part );
  my $res = $self->ua->post(
    $uri => {
      %{$opts},
      apiKey => $self->api_key,
      format => 'json',
    },
  );

  if ( !$res->is_success ) {
    Net::API::RPX::Exception::Network->throw(
      ident       => '_fetch_network_failure',
      message     => 'Could not contact RPX: ' . $res->status_line(),
      ua_result   => $res,
      status_line => $res->status_line,
    );
  }

  my $result = decode_json( $res->content );
  if ( $result->{'stat'} ne 'ok' ) {
    my $err = $result->{'err'};
    Net::API::RPX::Exception::Service->throw(
      ident             => '_fetch_service_error',
      data              => $result,
      status            => $result->{'stat'},
      rpx_error         => $result->{'err'},
      rpx_error_code    => $result->{err}->{code},
      rpx_error_message => $result->{err}->{msg},
      message           => 'RPX returned error of type \'' . $rpx_errors->{ $err->{code} } . '\' with message: ' . $err->{msg},
    );
  }
  delete $result->{'stat'};
  return $result;
}

1;    # End of Net::API::RPX

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::API::RPX - Perl interface to Janrain's RPX service

=head1 VERSION

version 1.000001

=head1 SYNOPSIS

    use Net::API::RPX;

    my $rpx = Net::API::RPX->new({ api_key => '<your_api_key_here>' });

    $rpx->auth_info({ token => $token });

=head1 DESCRIPTION

This module is a simple wrapper around Janrain's RPX service. RPX provides a single method for
dealing with third-party authentication.

See L<http://www.rpxnow.com> for more details.

For specific information regarding the RPX API and method arguments, please refer to
L<https://rpxnow.com/docs>.

=head1 METHODS

=head2 C<auth_info>

    my $user_data = $rpx->auth_info({ token => $params{token} });

Upon redirection back from RPX, you will be supplied a token to use for verification. Call
auth_info to verify the authenticity of the token and gain user details.

'token' argument is required, 'extended' argument is optional.

=head2 C<map>

    $rpx->map({ identifier => 'yet.another.open.id', primary_key => 12 });

This method allows you to map more than one 'identifier' to a user.

'identifier' argument is required, 'primary_key' argument is required, 'overwrite' is optional.

=head2 C<unmap>

    $rpx->unmap({ identifier => 'yet.another.open.id', primary_key => 12 });

This is the inverse of 'map'.

'identifier' argument is required, 'primary_key' argument is required.

=head2 C<mappings>

    my $data = $rpx->mappings({ primary_key => 12 });

This method returns information about the identifiers associated with a user.

'primary_key' argument is required.

=head1 ATTRIBUTES

=head2 C<api_key>

This is the api_key provided by Janrain to interface with RPX. You will need to sign up to RPX
to get one of these.

=head2 C<base_url>

This is the base URL that is used to make API calls against. It defaults to the RPX v2 API.

=head2 C<ua>

This is a LWP::UserAgent object. You may override it if you require more fine grain control
over remote queries.

=head1 TEST COVERAGE

This distribution is heavily unit and system tested for compatibility with
L<< <Test::Builder>|Test::Builder >>. If you come across any bugs, please send me or
submit failing tests to Net-API-RPX RT queue. Please see the 'SUPPORT' section below on
how to supply these.

 ---------------------------- ------ ------ ------ ------ ------ ------ ------
 File                           stmt   bran   cond    sub    pod   time  total
 ---------------------------- ------ ------ ------ ------ ------ ------ ------
 blib/lib/Net/API/RPX.pm       100.0  100.0    n/a  100.0  100.0  100.0  100.0
 Total                         100.0  100.0    n/a  100.0  100.0  100.0  100.0
 ---------------------------- ------ ------ ------ ------ ------ ------ ------

=head1 SEE ALSO

L<http://www.janrain.com/>, L<http://www.rpxnow.com/>

=head1 AUTHORS

=over 4

=item *

Scott McWhirter <konobi@cpan.org>

=item *

Kent Fredric <kentnl@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Cloudtone Studios.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
