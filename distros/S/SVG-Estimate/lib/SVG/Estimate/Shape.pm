package SVG::Estimate::Shape;
$SVG::Estimate::Shape::VERSION = '1.0113';
use Moo;

=head1 NAME

SVG::Estimate::Shape - Base class for all other shape calculations.

=head1 VERSION

version 1.0113

=head1 DESCRIPTION

There are a lot of methods and parameters shared between the various shape classes in L<SVG::Estimate>. This base class encapsulates them all.

=head1 INHERITANCE

This class consumes L<SVG::Estimate::Role::Round> and L<SVG::Estimate::Role::Pythagorean>.

=head1 METHODS

=head2 new( properties ) 

Constructor.

=over

=item properties

=over

=item start_point

An array ref that describes the position of the cursor (or CNC head) prior to drawing this shape (where it left off from the last object).

=item transformer

A reference to a L<Image::SVG::Transform> object that contains all the transforms for this shape.

=back

=back

=cut

has start_point => (
    is          => 'ro', 
    required    => 1,
);

##Note, named transformer because Transformers are cool, and because it clashes with the transform attribute
has transformer => (
    is          => 'ro',
    required    => 1,
);

with 'SVG::Estimate::Role::Round';
with 'SVG::Estimate::Role::Pythagorean';

=head2 length ( )

Returns the sum of C<travel_length> and C<shape_length>.

=cut

sub length {
    my $self = shift;
    return $self->travel_length + $self->shape_length;
}

=head2 draw_start ( )

Returns an x and a y value as an array ref of where the drawing will start that can be used by the C<travel_length> method.

=cut

has draw_start => (
    is          => 'ro',
    required    => 1,
);

=head2 draw_end ( )

Returns the same as C<draw_start()>. Override this if you have an open ended shape like a line.

=cut

has draw_end => (
    is          => 'ro',
    lazy        => 1,
    default     => sub {
        my $self = shift;
        return $self->draw_start;
    },
);

=head2 travel_length ( )

Returns the distance between C<start_point> and where the drawing of the shape begins, which the developer must define as C<draw_start()>

=cut

sub travel_length { 
    my $self = shift;
    return $self->pythagorean($self->draw_start, $self->start_point);
}

=head2 shape_length ( )

Returns the total length of the vectors in the shape.

=cut

has shape_length => (
    is       => 'ro', 
    required => 1,
);

=head2 min_x ( )

Returns the minimum position of C<x> that this shape will ever reach. 

=cut

has min_x => (
    is          => 'ro',
    required    => 1,
);

=head2 max_x ( )

Returns the maximum position of C<x> that this shape will ever reach. 

=cut

has max_x => (
    is          => 'ro',
    required    => 1,
);

=head2 min_y ( )

Returns the minimum position of C<y> that this shape will ever reach. 

=cut

has min_y => (
    is          => 'ro',
    required    => 1,
);

=head2 max_y ( )

Returns the max position of C<y> that this shape will ever reach. 

=cut

has max_y => (
    is          => 'ro',
    required    => 1,
);

sub summarize_myself {
    my $self = shift;
    print ref $self;
    printf "\n\tstart point: [%s, %s]", $self->round($self->start_point->[0]), $self->round($self->start_point->[1]);
    printf "\n\tdraw start : [%s, %s]", $self->round($self->draw_start->[0]), $self->round($self->draw_start->[1]);
    printf "\n\tdraw end   : [%s, %s]", $self->round($self->draw_end->[0]), $self->round($self->draw_end->[1]);
    print "\n\ttotal  length: ". $self->round($self->length);
    print "\n\ttravel length: ". $self->round($self->travel_length);
    print "\n\tshape length:  ". $self->round($self->shape_length);
    print "\n";
}

1;
