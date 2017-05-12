package SysTray;

use 5.006;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use SysTray ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.13';

# Event constants                       Which OS?
use constant MB_LEFT_CLICK   => 1;    # all
use constant MB_RIGHT_CLICK  => 2;    # all
use constant MB_MIDDLE_CLICK => 4;    # all
use constant MB_DOUBLE_CLICK => 8;    # all

use constant KEY_CTRL        => 16;   # all
use constant KEY_ALT         => 32;   # Windows/Linux
use constant KEY_COMMAND     => 32;   # Mac
use constant KEY_SHIFT       => 64;   # all
use constant KEY_WIN         => 128;  # Windows
use constant KEY_FUNCTION    => 128;  # Mac

use constant MSG_LOGOFF      => 256;  # all
use constant MSG_SHUTDOWN    => 512;  # all

require XSLoader;
XSLoader::load('SysTray', $VERSION);

# Preloaded methods go here.

1;
__END__

=head1 NAME

SysTray - Perl extension for cross-platform systray support

=head1 SYNOPSIS

    use SysTray;
    
    SysTray::create("my_callback", "/path/to/icon", "tooltip");
    
    while (1) {
      SysTray::do_events();  # non-blocking
      
      # do somthing else or sleep for a little while
    }
    
    # callback sub for receiving systray events
    sub my_callback {
      my $events = shift;
  
      if ($events & SysTray::MB_LEFT_CLICK) {
        # do something on left click
      }
    }

=head1 DESCRIPTION

This package provides cross-platform systray functionality. It works with Windows (98 or later),
Linux (you must have KDE 3.2/Qt 3.3 or later installed) and Mac (OSX 10.3.9 or later)

=head1 EXPORT

None. At this moment you'll have to use fully qualified names.

=head1 FUNCTIONS

=head2 create ($callback, $icon_path, $tooltip)

Creates a new systray icon.

Parameters:
  * $callback - sub name that will receive the systray icon events
  * $icon_path - path to the icon to be dysplayed (must be absolute on Linux, can be relative on Windows/Mac)
  * $tooltip - text to be displayed when mouse hovers over the icon

Return value:
  1 if the icon was successfully created, 0 otherwise

=head2 destroy ()

Deletes the systray icon and frees the allocated resources.

=head2 do_events ()

Non-blocking processing and dispatching of the system messages for the systray icon. If events occurred the
callback provided in the C<create> call will be executed.

=head2 change_icon ($icon_path)

Changes the systray icon with the one specified in C<$icon_path>. The same rules apply here as for the
C<create> call.

=head2 set_tooltip ($tooltip)

Changes the tooltip associated with the systray icon.

=head2 clear_tooltip ()

Clear the tooltip associated with the systray icon (if any).

=head2 release ()

Releases all GUI allocated resources.

=head2 events_callback ($events) [you'll have to provide this]

Sub that must be implemented for receiving events from the Systray icon. The C<$events> parameter is a bit combination of the constants defined in the next section.

=head1 CONSTANTS

=head2 Mouse Events:

=over

=item *

B<MB_LEFT_CLICK> - left mouse button was clicked on the systray icon

=item *

B<MB_RIGHT_CLICK> - right mouse button was clicked on the systray icon

=item *

B<MB_MIDDLE_CLICK> - middle mouse button was clicked on the systray icon

=item *

B<MB_DOUBLE_CLICK> - a mouse button was double-clicked. In order to find out which button was double-clicked
you'll have to test the C<$events> parameter received by the callback against the above three constants. Before receiving a double-click
event you'll always receive a single-click event, so you'll have to decide which one your application will use. Providing functionality for
left mouse click and left mouse double-click can be confusing

=back

=head2 Key events:

=over

=item *

B<KEY_CONTROL> - The CONTROL key was pressed along with a mouse button

=item *

B<KEY_ALT/KEY_COMMAND> - The ALT key (Windows/Linux) or the COMMAND key (Mac) was pressed along with a mouse button

=item *

B<KEY_SHIFT> - The SHIFT key was pressed along with a mouse button

=item *

B<KEY_WIN/KEY_FUNCTION> - The WINDOWS key (Windows) or the FUNCTION key (Mac) was pressed along with a mouse button

=back

=head2 System events:

=over

=item *

B<MSG_LOGOFF/MSG_SHUTDOWN> - Log-off or shut-down operation in progress. When this event is received you'll have to prepare your application to exit

=back

=head1 BUILD PREREQUESITES

=over

=item *

B<Linux> - C++ compiler and KDE 3.2/Qt 3.3 development packages installed

=item *

B<Windows> - Visual Studio 6.0 or later

=item *

B<Mac> - C/C++ compiler and the Cocoa framework

=back

=head1 SEE ALSO

The C<test_tray.pl> script shipped with this distribution.

=head1 AUTHOR

Copyright (C) 2009 by Chris Drake.  Contact details on www.vradd.com

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
