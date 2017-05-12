use warnings;
use strict;
use 5.8.3;	#this is what RT requires http://wiki.bestpractical.com/view/ManualRequirements
package RT::Extension::MenuBarUserTickets;

our $VERSION = '1.1';

return 1;

=pod

=head1 NAME

RT::Extension::MenuBarUserTickets - List tickets belonging to a specific user

=head1 DESCRIPTION

Adds an additional button and dropdown list box showing every enabled user
to the top of the RT interface page.

After selecting the required user from the list and clicking the show tickets
button query results will be should in the normal manner.

=head1 AUTHOR

MacGyveR <dumb@cpan.org>

Development questions, bug reports, and patches are welcome to the above address

=head1 COPYRIGHT

Copyright (c) 2009 MacGyveR. All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
