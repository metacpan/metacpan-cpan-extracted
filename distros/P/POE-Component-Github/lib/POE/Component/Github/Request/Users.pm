package POE::Component::Github::Request::Users;

use strict;
use warnings;
use HTTP::Request::Common;
use vars qw($VERSION);

$VERSION = '0.08';

use Moose;
use Moose::Util::TypeConstraints;

use URI::Escape;

with 'POE::Component::Github::Request::Role';

has cmd => (
  is       => 'ro',
  isa      => enum([qw(
		search 
		show 
		followers 
		following 
		update 
		follow 
		unfollow 
		pub_keys 
		add_key 
		remove_key 
		emails 
		add_email 
		remove_email
              )]),
  required => 1,
);

has user => (
  is       => 'ro',
  default  => '',
);

sub request {
  my $self = shift;
  # Work out if authenticated is required or not
  AUTHENTICATED: {
    if ( $self->login and $self->token ) { # Okay authenticated required.
       if ( grep { $_ eq $self->cmd } qw(search followers following) ) {
          last AUTHENTICATED;
       }
       # Simple stuff no values required.
       my $data = [ 'login' => $self->login, 'token' => $self->token ];
       if ( $self->cmd =~ /^(show|follow|unfollow|pub_keys|emails)$/ ) {
	  my $url = $self->auth_scheme . join '/', $self->api_url, 'user';
	  return POST( join('/', $url, 'keys'), $data ) if $self->cmd eq 'pub_keys';
	  return POST( join('/', $url, 'emails' ), $data ) if $self->cmd eq 'emails';
	  return POST( join('/', $url, $self->cmd, $self->user ), $data );
       }
       # These have values to pass
       if ( $self->cmd eq 'update' ) {
	  my $url = $self->auth_scheme . join '/', $self->api_url, 'user';
	  my $values = $self->values;
	  push @{ $data }, ( "values[$_]", $values->{$_} ) for keys %{ $values };
	  return POST( join('/', $url, 'show', $self->user), $data );
       }
       if ( $self->cmd =~ /^(add_key|remove_key|add_email|remove_email)$/ ) {
	  my $url = $self->auth_scheme . join '/', $self->api_url, 'user';
	  push @{ $data }, %{ $self->values };
	  my ($action,$cmd) = split /\_/, $self->cmd;
	  return POST( join('/', $url, $cmd, $action ), $data );
       }
    }
  }
  if ( $self->cmd =~ /^follow(ers|ing)$/ ) {
     return GET( $self->scheme . join '/', $self->api_url, 'user', 'show', $self->user, $self->cmd );
  }
  if ( $self->cmd =~ /^(show|search)$/ ) {
     return GET( $self->scheme . join '/', $self->api_url, 'user', $self->cmd, $self->user );
  }
  return;
}

no Moose;

__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

POE::Component::Github::Request::Users - Build HTTP::Request objects for Users API

=head1 DESCRIPTION

Builds HTTP::Request objects for the Users API.

=head1 CONSTRUCTOR

=over

=item C<new>

Attributes:

  cmd
  user

=back

=head1 C<METHOD>

=over

=item C<request>

Returns a L<HTTP::Request> object based on the data passed to C<new>.

=back

=head1 AUTHOR

Chris C<BinGOs> Williams <chris@bingosnet.co.uk>

=head1 LICENSE

Copyright E<copy> Chris Williams

This module may be used, modified, and distributed under the same terms as Perl itself. Please see the license that came with your Perl distribution for details.

=cut
