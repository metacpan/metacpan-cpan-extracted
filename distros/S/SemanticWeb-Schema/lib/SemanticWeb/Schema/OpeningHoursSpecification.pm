use utf8;

package SemanticWeb::Schema::OpeningHoursSpecification;

# ABSTRACT: A structured value providing information about the opening hours of a place or a certain service inside a place

use Moo;

extends qw/ SemanticWeb::Schema::StructuredValue /;


use MooX::JSON_LD 'OpeningHoursSpecification';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v9.0.0';


has closes => (
    is        => 'rw',
    predicate => '_has_closes',
    json_ld   => 'closes',
);



has day_of_week => (
    is        => 'rw',
    predicate => '_has_day_of_week',
    json_ld   => 'dayOfWeek',
);



has opens => (
    is        => 'rw',
    predicate => '_has_opens',
    json_ld   => 'opens',
);



has valid_from => (
    is        => 'rw',
    predicate => '_has_valid_from',
    json_ld   => 'validFrom',
);



has valid_through => (
    is        => 'rw',
    predicate => '_has_valid_through',
    json_ld   => 'validThrough',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::OpeningHoursSpecification - A structured value providing information about the opening hours of a place or a certain service inside a place

=head1 VERSION

version v9.0.0

=head1 DESCRIPTION

=for html <p>A structured value providing information about the opening hours of a
place or a certain service inside a place.<br/><br/> The place is
<strong>open</strong> if the <a class="localLink"
href="http://schema.org/opens">opens</a> property is specified, and
<strong>closed</strong> otherwise.<br/><br/> If the value for the <a
class="localLink" href="http://schema.org/closes">closes</a> property is
less than the value for the <a class="localLink"
href="http://schema.org/opens">opens</a> property then the hour range is
assumed to span over the next day.<p>

=head1 ATTRIBUTES

=head2 C<closes>

The closing hour of the place or service on the given day(s) of the week.

A closes should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_closes>

A predicate for the L</closes> attribute.

=head2 C<day_of_week>

C<dayOfWeek>

The day of the week for which these opening hours are valid.

A day_of_week should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::DayOfWeek']>

=back

=head2 C<_has_day_of_week>

A predicate for the L</day_of_week> attribute.

=head2 C<opens>

The opening hour of the place or service on the given day(s) of the week.

A opens should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_opens>

A predicate for the L</opens> attribute.

=head2 C<valid_from>

C<validFrom>

The date when the item becomes valid.

A valid_from should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_valid_from>

A predicate for the L</valid_from> attribute.

=head2 C<valid_through>

C<validThrough>

The date after when the item is not valid. For example the end of an offer,
salary period, or a period of opening hours.

A valid_through should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_valid_through>

A predicate for the L</valid_through> attribute.

=head1 SEE ALSO

L<SemanticWeb::Schema::StructuredValue>

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
