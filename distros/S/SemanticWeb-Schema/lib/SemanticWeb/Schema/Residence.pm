use utf8;

package SemanticWeb::Schema::Residence;

# ABSTRACT: The place where a person lives.

use Moo;

extends qw/ SemanticWeb::Schema::Place /;


use MooX::JSON_LD 'Residence';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v9.0.0';


has accommodation_floor_plan => (
    is        => 'rw',
    predicate => '_has_accommodation_floor_plan',
    json_ld   => 'accommodationFloorPlan',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::Residence - The place where a person lives.

=head1 VERSION

version v9.0.0

=head1 DESCRIPTION

The place where a person lives.

=head1 ATTRIBUTES

=head2 C<accommodation_floor_plan>

C<accommodationFloorPlan>

=for html <p>A floorplan of some <a class="localLink"
href="http://schema.org/Accommodation">Accommodation</a>.<p>

A accommodation_floor_plan should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::FloorPlan']>

=back

=head2 C<_has_accommodation_floor_plan>

A predicate for the L</accommodation_floor_plan> attribute.

=head1 SEE ALSO

L<SemanticWeb::Schema::Place>

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/SemanticWeb-Schema>
and may be cloned from L<git://github.com/robrwo/SemanticWeb-Schema.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/SemanticWeb-Schema/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2020 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
