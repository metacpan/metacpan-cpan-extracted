#
# This file is part of SDLx-GUI
#
# This software is copyright (c) 2013 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.016;
use warnings;

package SDLx::GUI::Widget;
# ABSTRACT: Base class for all GUI widgets
$SDLx::GUI::Widget::VERSION = '0.002';
use Moose;
use MooseX::Has::Sugar;
use MooseX::SemiAffordanceAccessor;
use SDL::Color;
use SDLx::Sprite;

use SDLx::GUI::Debug qw{ debug };


# -- attributes

has bg_color => ( rw, lazy_build, isa=>"SDL::Color" );



has parent     => ( rw, weak_ref, isa=>"SDLx::GUI::Widget" );


# the pack information describing how the widget is being packed onto
# its parent. A SDLx::GUI::Pack object, refer to this module for more
# information.
has _pack_info => ( rw, isa=>"SDLx::GUI::Pack", predicate=>"is_packed" );


# -- initialization

sub BUILD    { debug( "widget created: $_[0]\n" ); }
sub DEMOLISH { debug( "widget destroyed: $_[0]\n" ); }
sub _build_bg_color { SDL::Color->new(192,192,192); }

# -- public methods


sub pack {
    my ($self, %opts) = @_;
    my $pack = SDLx::GUI::Pack->new(%opts);
    $self->_set_pack_info( $pack );
    $self->parent->_recompute;
}



sub is_visible {
    my $self = shift;
    return $self->_pack_info && $self->_pack_info->_slave_dims;
}

# -- private methods

#
#   $widget->_draw( $surface );
#
# Request C<$widget> to be drawn on C<$surface>.
# PLACEHOLDER: method needs to be implemented in subclasses.
#

#
#   my ($width, $height) = $widget->_wanted_size;
#

# Return the minimum C<$width> and C<$height> needed to draw C<$widget>.
# Those dimensions are guaranted to be respected by its parent container
# - even if that means that the result will be clipped! :-)
# PLACEHOLDER: method needs to be implemented in subclasses.


no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SDLx::GUI::Widget - Base class for all GUI widgets

=head1 VERSION

version 0.002

=head1 DESCRIPTION

L<SDLx::GUI> provides some widgets to build the interface. Those widgets
all inherit from this base class.

=head1 ATTRIBUTES

=head2 parent

The parent widget (a L<SDLx::GUI::Widget> object).

=head1 METHODS

=head2 pack

    $widget->pack( %opts );

Request C<$widget> to be packed on its parent. C<%opts> is used to
create a new L<SDLx::GUI::Pack> object - refer to this module for more
information on supported attributes.

=head2 is_visible

    my $bool = $widget->is_visible;

Return true if C<$widget> is currently visible, ie if it is packed and
there's enough place on the screen for it to be shown.

=for Pod::Coverage BUILD DEMOLISH

=head1 AUTHOR

Jerome Quelin <jquelin@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
