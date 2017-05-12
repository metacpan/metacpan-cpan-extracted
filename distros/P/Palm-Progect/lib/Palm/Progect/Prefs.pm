
package Palm::Progect::Prefs;
use strict;

=head1 NAME

Palm::Progect::Prefs - Preferences of the Progect Database

=head1 DESCRIPTION

The Preferences system is not currently implemented.

=cut

use base 'Palm::Progect::VersionDelegator';

1;

__END__


Ideas for importing/exporting prefs in various formats:

text format:

    pref: name: value

html format:

    <!-- prefs

    pref: name: value

    -->

csv format:

    pref_name, pref_value


=head1 AUTHOR

Michael Graham E<lt>mag-perl@occamstoothbrush.comE<gt>

Copyright (C) 2002-2005 Michael Graham.  All rights reserved.
This program is free software.  You can use, modify,
and distribute it under the same terms as Perl itself.

The latest version of this module can be found on http://www.occamstoothbrush.com/perl/

=head1 SEE ALSO

C<progconv>

L<Palm::PDB(3)>

http://progect.sourceforge.net/

=cut



