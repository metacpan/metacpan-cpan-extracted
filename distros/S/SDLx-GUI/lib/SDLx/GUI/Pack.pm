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

package SDLx::GUI::Pack;
# ABSTRACT: Objects to keep track of pack options
$SDLx::GUI::Pack::VERSION = '0.002';
use Moose;
use MooseX::Has::Sugar;
use MooseX::SemiAffordanceAccessor;

use SDLx::GUI::Debug qw{ debug };
use SDLx::GUI::Types;


# -- attributes


has side  => ( ro, isa=>"PackSide", default=>"top" );


#
#   _parcel
#
# The parcel devoted to the pack (a L<SDLx::Rect> object). See the
# packer algorithm for more information on the parcel.
#
#   _slave_dims
#
# The dimensions that the child should fill (a L<SDLx::Rect> object).
# See the packer algorithm for more information on the slave dimensions.
#
#   _clip
#
# A L<SDLx::Rect> used to clip a packed child if there isn't enough place.
#
has _parcel     => (rw, isa=>"SDLx::Rect", clearer=>"_clear_parcel" );
has _slave_dims => (rw, isa=>"SDLx::Rect", clearer=>"_clear_slave_dims" );
has _clip       => (rw, isa=>"SDLx::Rect", clearer=>"_clear_clip" );


# -- initialization

sub BUILD    { debug( "pack object created: $_[0]\n" ); }
sub DEMOLISH { debug( "pack object destroyed: $_[0]\n" ); }



no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SDLx::GUI::Pack - Objects to keep track of pack options

=head1 VERSION

version 0.002

=head1 DESCRIPTION

This class defines objects keeping track of packing options for widgets.

=head1 ATTRIBUTES

=head2 side

On which side to pack the widget - see C<PackSide> in
L<SDLx::GUI::Types>. Defaults to C<top>.

=for Pod::Coverage BUILD DEMOLISH

=head1 AUTHOR

Jerome Quelin <jquelin@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
