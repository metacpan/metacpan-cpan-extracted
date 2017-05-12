package POE::Component::Github::Request::Network;

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
		network_meta
		network_data_chunk
              )]),
  required => 1,
);

has user => (
  is       => 'ro',
  default  => '',
);

has repo => (
  is       => 'ro',
  default  => '',
);

has nethash => (
  is       => 'ro',
  default  => '',
);

has start => (
  is       => 'ro',
  default  => '',
);

has end => (
  is       => 'ro',
  default  => '',
);

# Commits

sub request {
  my $self = shift;
  # No authenticated requests
  my $base_url = ( split /\//, $self->api_url )[0] ;
  my $url = $self->scheme . join '/', $base_url, $self->user, $self->repo, $self->cmd;
  if ( $self->cmd eq 'network_data_chunk' ) {
     $url .= '?' . 'nethash=' . $self->nethash;
     $url .= '&start=' . $self->start if $self->start;
     $url .= '&end='   . $self->end   if $self->end;
  }
  return GET( $url );
}

no Moose;

__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

POE::Component::Github::Request::Network - Build HTTP::Request objects for Network API

=head1 DESCRIPTION

Builds HTTP::Request objects for the Network API.

=head1 CONSTRUCTOR

=over

=item C<new>

Attributes:

  cmd
  user
  repo
  nethash
  start
  end

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
