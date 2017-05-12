package POE::Component::Github::Request::Commits;

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
		branch
		file
		commit
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

has branch => (
  is       => 'ro',
  default  => 'master',
);

has file => (
  is       => 'ro',
  default  => '',
);

has commit => (
  is       => 'ro',
  default  => '',
);

# Commits

sub request {
  my $self = shift;
  # No authenticated requests
  my $url = $self->scheme . join '/', $self->api_url, 'commits';
  if ( $self->cmd =~ /^(branch|file)$/ ) {
     return GET( join('/', $url, 'list', $self->user, $self->repo, $self->branch, ( $self->cmd eq 'file' ? $self->file : () )) );
  }
  if ( $self->cmd eq 'commit' ) {
     return GET( join('/', $url, 'show', $self->user, $self->repo, $self->commit) );
  }
}

no Moose;

__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

POE::Component::Github::Request::Commits - Build HTTP::Request objects for Commits API

=head1 DESCRIPTION

Builds HTTP::Request objects for the Commits API.

=head1 CONSTRUCTOR

=over

=item C<new>

Attributes:

  cmd
  user
  repo
  branch
  file
  commit

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
