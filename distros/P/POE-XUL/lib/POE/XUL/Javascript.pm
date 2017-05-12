package POE::XUL::Javascript;
# $Id$
# Copyright Philip Gwyn 2007-2010.  All rights reserved.

use strict;


1;

__DATA__

=head1 NAME

POE::XUL::Javascript - POE::XUL Javascript client library documentation

=head1 SYNOPSIS

=head1 DESCRIPTION

This documentation needs to be written

=head1 OBJECTS

=head2 $application

=head3 getSID

    var SID = $application.getSID();

=head3 runRequest

    $application.runRequest( { event: 'Something', 
                               source_id: 'Some-ID'
                           } );
                               
=head3 crash

    $application.crash( "Something very bad happened" );

=head3 status

    $application.status( 'run' );

=head2 Firebug

POE::XUL includes wrappers for the most excelent
L<Firebug|https://addons.mozilla.org/en-US/firefox/addon/1843> debugging
extension.  You probably don't want to be writing XBL without Firebug.

These wrappers check to see that firebug is installed before logging to its
console.

=head3 fb_log

    fb_log( "Short message for firebox's console" );

Sends a message to the most excelent
L<Firebug|https://addons.mozilla.org/en-US/firefox/addon/1843> debugging
extension.  You probably don't want to be writing XBL without Firebug.

=head3 fb_dir

=head3 fb_time

=head3 fb_timeEnd

=head1 LIBRARIES

=head2 prototype.js

L<http://www.prototypejs.org/>.

=head2 util.js

=head1 AUTHOR

Philip Gwyn E<lt>gwyn-at-cpan.orgE<gt>

=head1 CREDITS

Based on XUL::Node by Ran Eilam.

=head1 COPYRIGHT AND LICENSE

Copyright 2007-2010 by Philip Gwyn.  All rights reserved;

Copyright 2003-2004 Ran Eilam. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=head1 SEE ALSO

perl(1), L<POE::XUL>, L<POE::XUL::Node>, , L<POE::XUL::TextNode>.

=cut

