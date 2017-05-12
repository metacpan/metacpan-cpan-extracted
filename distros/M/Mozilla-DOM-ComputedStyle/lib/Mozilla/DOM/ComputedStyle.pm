package Mozilla::DOM::ComputedStyle;

use 5.008008;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Mozilla::DOM::ComputedStyle ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(Get_Computed_Style_Property Get_Full_Zoom Set_Full_Zoom
			Set_Poll_Timeout Unset_Poll_Timeout);

our $VERSION = '0.05';

require XSLoader;
XSLoader::load('Mozilla::DOM::ComputedStyle', $VERSION);

# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Mozilla::DOM::ComputedStyle - Interface to Mozilla getComputedStyle function.

=head1 SYNOPSIS

  use Mozilla::DOM::ComputedStyle;

  Get_Computed_Style_Property($mozilla_window, $element, $property_name);

=head1 DESCRIPTION

This module makes possible to get computed style properties from Mozilla DOM.
See documentation for C<window.getComputedStyle> JavaScript function.

It also includes functions to get and to set full page zoom.

=head1 EXPORT

=head2 Get_Computed_Style_Property($window, $element, $property_name)

This function returns property <$property_name> of DOM element C<$element> of
C<$window>.

=head2 Get_Full_Zoom($browser)

Returns current full zoom value.

=head2 Set_Full_Zoom($browser, $zoom)

Sets full zoom value.

=head1 SEE ALSO

L<Mozilla::DOM|Mozilla::DOM>.

=head1 AUTHOR

Boris Sukholitko, E<lt>boriss@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Boris Sukholitko

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
