package Reaction::UI::ViewPort::URI;

use Reaction::Class;
use namespace::clean -except => [ qw(meta) ];
use MooseX::Types::URI qw/Uri/;
extends 'Reaction::UI::ViewPort';

has uri => ( is => 'rw', isa => Uri, required => 1);
has display => ( is => 'rw' );

__PACKAGE__->meta->make_immutable;

1;

__END__;


=head1 NAME

Reaction::UI::ViewPort::URI

=head1 DESCRIPTION

Viewport for a URI object

=head1 ATTRIBUTES

=head2 uri

Required URI object representing the URI you wish to point to.

=head2 display

Optional. How this item will be displayed. Current implementations support
a plain string or a ViewPort object for this value

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut
