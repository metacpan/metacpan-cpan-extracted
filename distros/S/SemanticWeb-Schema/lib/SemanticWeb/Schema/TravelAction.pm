use utf8;

package SemanticWeb::Schema::TravelAction;

# ABSTRACT: The act of traveling from an fromLocation to a destination by a specified mode of transport

use Moo;

extends qw/ SemanticWeb::Schema::MoveAction /;


use MooX::JSON_LD 'TravelAction';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.4';


has distance => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'distance',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::TravelAction - The act of traveling from an fromLocation to a destination by a specified mode of transport

=head1 VERSION

version v0.0.4

=head1 DESCRIPTION

The act of traveling from an fromLocation to a destination by a specified
mode of transport, optionally with participants.

=head1 ATTRIBUTES

=head2 C<distance>

The distance travelled, e.g. exercising or travelling.

A distance should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Distance']>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::MoveAction>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
