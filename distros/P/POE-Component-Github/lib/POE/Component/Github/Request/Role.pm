package POE::Component::Github::Request::Role;

use strict;
use warnings;
use vars qw($VERSION);

$VERSION = '0.08';

use Moose::Role;

# login
has 'login'  => ( is => 'ro', isa => 'Str', default => '' );
has 'token' => ( is => 'ro', isa => 'Str', default => '' );

# api
has 'api_url' => ( is => 'ro', default => 'github.com/api/v2/json/');
has 'scheme'  => ( is => 'ro', default => 'http://');
has 'auth_scheme'    => ( is => 'ro', default => 'https://');
has 'values'  => ( is => 'ro', default => sub { { } } );

no Moose::Role;

1;
__END__

=head1 NAME

POE::Component::Github::Request::Role - A role for Github requests

=head1 SYNOPSIS

  package POE::Component::Github::Request::*;

  use Moose;
  with 'POE::Component::Github::Request::Role';

=head1 DESCRIPTION

POE::Component::Github::Request::Role is a role for POE::Component::Github::Request objects.

=head1 ATTRIBUTES

=over

=item C<login>

Github login

=item C<token>

Github API token

=item C<api_url>

The url to the Github API, without the preceeding scheme.

=item C<scheme>

The scheme to use with the API for unauthenticated requests.

=item C<auth_scheme>

The scheme to use with the API for authenticated requests.

=item C<values>

A hashref of C<POST> values to send with authenticated requests.

=back

=head1 AUTHOR

Chris C<BinGOs> Williams <chris@bingosnet.co.uk>

=head1 LICENSE

Copyright E<copy> Chris Williams

This module may be used, modified, and distributed under the same terms as Perl itself. Please see the license that came with your Perl distribution for details.

=cut
