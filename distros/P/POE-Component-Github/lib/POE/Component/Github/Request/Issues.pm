package POE::Component::Github::Request::Issues;

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
		list
		view
		open
		close
		reopen
		edit
		add_label
		remove_label
		comment
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

has state => (
  is	   => 'ro',
  isa	   => enum([qw(open closed)]),
);

has id => (
  is       => 'ro',
  default  => '',
);

has search => (
  is       => 'ro',
  default  => '',
);

has label => (
  is       => 'ro',
  default  => '',
);

sub request {
  my $self = shift;
  # Work out if authenticated is required or not
  AUTHENTICATED: {
    if ( $self->login and $self->token ) { # Okay authenticated required.
       if ( grep { $_ eq $self->cmd } qw(search list view) ) {
          last AUTHENTICATED;
       }
       # Simple stuff no values required.
       my $data = [ 'login' => $self->login, 'token' => $self->token ];
       my $url = 'https://' . join '/', $self->api_url, 'issues';
       if ( $self->cmd =~/^(close|reopen)$/ ) {
	  return POST( join('/', $url, $self->cmd, $self->user, $self->repo, $self->id ), $data );
       }
       if ( my ($action) = $self->cmd =~ /^(add|remove)\_label$/ ) {
	  return POST( join('/', 'label', $action, $self->user, $self->repo, $self->label, $self->id ), $data );
       }
       push @$data, %{ $self->values };
       $url = join '/', $url, $self->cmd, $self->user, $self->repo;
       $url = join '/', $url, $self->id unless $self->cmd eq 'open';
       return POST( $url, $data );
    }
  }
  my $url = $self->scheme . join '/', $self->api_url, 'issues';
  if ( $self->cmd =~ /^(search|list)$/ ) {
    $url = join '/', $url, $self->cmd, $self->user, $self->repo, $self->state;
    $url = join '/', $url, uri_escape( $self->search ) if $self->cmd eq 'search';
    return GET( $url );
  }
  return GET( join('/', $url, 'show', $self->user, $self->repo, $self->id ) );
}

no Moose;

__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

POE::Component::Github::Request::Issues - Build HTTP::Request objects for Issues API

=head1 DESCRIPTION

Builds HTTP::Request objects for the Issues API.

=head1 CONSTRUCTOR

=over

=item C<new>

Attributes:

  cmd
  user
  repo
  state
  search
  id
  label

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
