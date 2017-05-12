package SVG::Rasterize::Engine;
use base Class::Accessor;

use warnings;
use strict;

use 5.008009;

use Params::Validate qw(:all);

use SVG::Rasterize::Regexes qw(%RE_NUMBER);

# $Id: Engine.pm 6712 2011-05-21 07:57:09Z powergnom $

=head1 NAME

C<SVG::Rasterize::Engine> - rasterization engine base class

=head1 VERSION

Version 0.003008

=cut

our $VERSION = '0.003008';


__PACKAGE__->mk_accessors(qw());

__PACKAGE__->mk_ro_accessors(qw(width
                                height));

###########################################################################
#                                                                         #
#                      Class Variables and Methods                        # 
#                                                                         #
###########################################################################

sub make_ro_accessor {
    my($class, $field) = @_;

    return sub {
        my $self = shift;

        if (@_) {
            my $caller = caller;
            SVG::Rasterize->ex_at_ro("${class}->${field}");
        }
        else {
            return $self->get($field);
        }
    };
}

###########################################################################
#                                                                         #
#                             Init Process                                #
#                                                                         #
###########################################################################

sub new {
    my ($class, @args) = @_;

    my $self = bless {}, $class;
    $self->init(@args);
    return $self;
}

sub init {
    my ($self, @args) = @_;
    my %args          = validate_with
	(params  => \@args,
	 spec    => {width  => {regex => $RE_NUMBER{p_NNINTEGER}},
		     height => {regex => $RE_NUMBER{p_NNINTEGER}}},
	 on_fail => sub { SVG::Rasterize->ex_pv($_[0]) });

    $self->{width}  = $args{width};
    $self->{height} = $args{height};

    return $self;
}

###########################################################################
#                                                                         #
#                               Accessors                                 # 
#                                                                         #
###########################################################################

###########################################################################
#                                                                         #
#                                Drawing                                  #
#                                                                         #
###########################################################################

sub draw_path {
    my ($self, $state) = @_;

    $state->ex_en_ov('draw_path', ref($self));
}

sub text_width {
    my ($self, $state) = @_;

    $state->ex_en_ov('text_width', ref($self));
}

sub draw_text {
    my ($self, $state) = @_;

    $state->ex_en_ov('draw_text', ref($self));
}

sub write {
    my ($self) = @_;

    SVG::Rasterize->ex_en_ov('write', ref($self));
}

1;

__END__

=head1 SYNOPSIS

  # explicit construction (unusual)
  use SVG::Rasterize::Engine;
  my $engine = SVG::Rasterize::Engine->new(width  => 640,
                                           height => 480);

=head1 DESCRIPTION

This class defines the interface for rasterization backends. It does
not do any rasterization itself. Implementations of rasterization
backends should subclass this class.

Warning: Please be aware of that this interface has to be considered
rather unstable at this state of the development.

This class is only instantiated by the L<rasterize
method|SVG::Rasterize/rasterize> of C<SVG::Rasterize> via one of its
subclasses.

=head1 INTERFACE

=head2 Constructors

=head3 new

  SVG::Rasterize::Engine->new(%args)

Creates a new C<SVG::Rasterize::Engine> object and calls
C<init(%args)>.  If you subclass C<SVG::Rasterize::Engine> overload
C<init>, not C<new>.

=head3 init

  $cairo->init(%args)

If you overload C<init>, your method should also call this one.
It initializes the attributes L<width|/width> and L<height|/height>
which are mandatory parameters and have to be non-negative integers.

Backends are also required to validate their init parameters
because the L<engine_args|SVG::Rasterize/engine_args> hash given by
the user to C<SVG::Rasterize> is handed over to the C<new>
constructor of the engine class without validation.

=head2 Public Attributes

These following attributes are provided by this class.

=over 4

=item * width

Can only be set at construction time. Saves the width of the output
image.

=item * height

Can only be set at construction time. Saves the height of the
output image.

=back

These are the attributes which alternative rasterization engines
have to implement.

=over 4

=item * currently none

=back

=head2 Mandatory Methods

The following methods have to be overloaded by subclasses.

=head3 draw_path

Expects a L<SVG::Rasterize::State|SVG::Rasterize::State> object and
a list of instructions. None of the parameters must be validated, it
is expected that this has happened before. Each instruction must be
an ARRAY reference with one of the following sets of entries (the
first entry is always a letter, the rest are numbers):

=over 4

=item * C<M> or C<m>, followed by two numbers

=item * C<Z>

=item * C<L> or C<l>, followed by two numbers

=item * C<H> or C<h>, followed by one number

=item * C<V> or C<v>, followed by one number

=item * C<C> or C<c>, followed by six numbers

=item * C<S> or C<s>, followed by four numbers

=item * C<Q> or C<q>, followed by four numbers

=item * C<T> or C<t>, followed by two numbers

=item * C<A> or C<a>, followed by seven numbers

=back


=head3 draw_text

Expects the following parameters:

=over 4

=item * an L<SVG::Rasterize::State|SVG::Rasterize::State> object

=item * the C<x> coordinate of the start of the text

For left-to-right text this is always the left end of the
text. Alignment issues have been taken into account before (at least
if L<text_width|/text_width> is implemented. Right-to-left and
top-to-bottom text and alignment issues in the absence of a
L<text_width|/text_width> have not been worked out, yet.

If L<text_width|/text_width> is implemented then the value is always
defined. In the absence of a L<text_width|/text_width> method it
will only be defined if an C<x> coordinate has been set explicitly
(or at the beginning of a C<text> element where C<x> defaults to
C<0>.

=item * the C<y> coordinated of the text

=item * the C<rotate> value of the text, possibly C<undef>

=item * the text itself

Can be C<undef> which should result in an immediate C<return>.

=back

None of these parameters must be validated. It is assumed that this
has been done before.


=head3 write

  $engine->write(%args)

Writes the rendered image to a file.

B<Example:>

  $engine->write(type => 'png', file_name => 'foo.png');

C<type> and C<file_name> must be accepted (but can be ignored, of
course). If C<file_name> has a false value, no output is written and
a warning may be issued. Besides that, C<file_name> must not
validated at all. The user must provide a sane value (whatever
that means to him or her).


=head2 Optional Methods

The following methods are part of the interface, but do not have to
be provided.

=head3 text_width

Called with an L<SVG::Rasterize::State|SVG::Rasterize::State> object
and the text to render. Returns the width that the rendered text
would occupy. The second argument may be C<undef> in which case C<0>
should be returned.

NB: The base class method throws an exception. The exception is
caught by L<SVG::Rasterize|SVG::Rasterize>. This behaviour is used
to determine if this method is implemented by the engine or not.

=head3 draw_rect

If this method is not implemented then an equivalent call to
L<draw_path|/draw_path> is used. If closed paths are implemented by
the engine there is no real reason to provide this method. Called
with the following parameters (for the exact meanings see the C<SVG>
specification):

=over 4

=item * an L<SVG::Rasterize::State|SVG::Rasterize::State> object

=item * the x coordinate in pixel

=item * the y coordinate in pixel

=item * the width in pixel

=item * the height in pixel

=item * the corner x radius in pixel

=item * the corner y radius in pixel

=back

None of these parameters must be validated. It is assumed that this
has been done before.


=head3 draw_circle

If this method is not implemented then an equivalent call to
L<draw_path|/draw_path> is used. If closed paths are implemented by
the engine there is no real reason to provide this method. Called
with the following parameters (for the exact meanings see the C<SVG>
specification):

=over 4

=item * an L<SVG::Rasterize::State|SVG::Rasterize::State> object

=item * the center x coordinate in pixel

=item * the center y coordinate in pixel

=item * the radius in pixel

=back

None of these parameters must be validated. It is assumed that this
has been done before.


=head3 draw_ellipse

If this method is not implemented then an equivalent call to
L<draw_path|/draw_path> is used. If closed paths are implemented by
the engine there is no real reason to provide this method. Called
with the following parameters (for the exact meanings see the C<SVG>
specification):

=over 4

=item * an L<SVG::Rasterize::State|SVG::Rasterize::State> object

=item * the center x coordinate in pixel

=item * the center y coordinate in pixel

=item * the x radius in pixel

=item * the y radius in pixel

=back

None of these parameters must be validated. It is assumed that this
has been done before.


=head3 draw_line

If this method is not implemented then an equivalent call to
L<draw_path|/draw_path> is used. If closed paths are implemented by
the engine there is no real reason to provide this method. Called
with the following parameters (for the exact meanings see the C<SVG>
specification):

=over 4

=item * an L<SVG::Rasterize::State|SVG::Rasterize::State> object

=item * the x coordinate of the start point in pixel

=item * the y coordinate of the start point in pixel

=item * the x coordinate of the end point in pixel

=item * the y coordinate of the end point in pixel

=back

None of these parameters must be validated. It is assumed that this
has been done before.


=head3 draw_polyline

If this method is not implemented then an equivalent call to
L<draw_path|/draw_path> is used. If closed paths are implemented by
the engine there is no real reason to provide this method. Called
with the following parameters (for the exact meanings see the C<SVG>
specification):

=over 4

=item * an L<SVG::Rasterize::State|SVG::Rasterize::State> object

=item * reference to an array of points (each is ARRAY reference
with two numbers)

=back

None of these parameters must be validated. It is assumed that this
has been done before.


=head3 draw_polygon

If this method is not implemented then an equivalent call to
L<draw_path|/draw_path> is used. If closed paths are implemented by
the engine there is no real reason to provide this method. Called
with the following parameters (for the exact meanings see the C<SVG>
specification):

=over 4

=item * an L<SVG::Rasterize::State|SVG::Rasterize::State> object

=item * reference to an array of points (each is ARRAY reference
with two numbers)

=back

None of these parameters must be validated. It is assumed that this
has been done before.


=head1 DIAGNOSTICS

=head2 Exceptions

=head2 Warnings


=head1 INTERNALS

=head2 Internal Methods

These methods are just documented for myself. You can read on to
satisfy your voyeuristic desires, but be aware of that they might
change or vanish without notice in a future version.

=over 4

=item * make_ro_accessor

This piece of documentation is mainly here to make the C<POD>
coverage test happy. C<SVG::Rasterize::State> overloads
C<make_ro_accessor> to make the readonly accessors throw an
exception object (of class C<SVG::Rasterize::Exception::Attribute>)
instead of just croaking.

=back

=head1 AUTHOR

Lutz Gehlen, C<< <perl at lutzgehlen.de> >>


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Lutz Gehlen.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
