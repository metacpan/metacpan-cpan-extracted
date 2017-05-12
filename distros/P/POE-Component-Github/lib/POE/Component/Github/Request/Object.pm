package POE::Component::Github::Request::Object;

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
		tree
		blob
		raw
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

has tree_sha => (
  is       => 'ro',
  default  => '',
);

has path => (
  is       => 'ro',
  default  => '',
);

has sha => (
  is       => 'ro',
  default  => '',
);

# Commits

sub request {
  my $self = shift;
  # No authenticated requests
  my $url = $self->scheme . $self->api_url;
  if ( $self->cmd =~ /^(tree|blob)$/ ) {
     $url = join '/', $url, $self->cmd, 'show', $self->user, $self->repo, $self->tree_sha;
     return GET( $self->cmd eq 'blob' ? join('/', $url, $self->path) : $url );
  }
  if ( $self->cmd eq 'raw' ) {
     return GET( join('/', $url, 'blob', 'show', $self->user, $self->repo, ( $self->sha || $self->tree_sha ) ) );
  }
}

no Moose;

__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

POE::Component::Github::Request::Object - Build HTTP::Request objects for Object API

=head1 DESCRIPTION

Builds HTTP::Request objects for the Object API.

=head1 CONSTRUCTOR

=over

=item C<new>

Attributes:

  cmd
  user
  repo
  tree_sha
  sha
  path

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
