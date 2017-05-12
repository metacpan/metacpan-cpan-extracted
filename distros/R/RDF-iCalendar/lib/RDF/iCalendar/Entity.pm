package RDF::iCalendar::Entity;

use 5.008;
use base qw[RDF::vCard::Entity];
use strict;
use warnings;
no warnings qw(uninitialized);

our $VERSION = '0.005';

1;


__END__

=head1 NAME

RDF::iCalendar::Entity - represents an iCalendar calendar, event, todo, etc.

=head1 DESCRIPTION

This is a trivial subclass of L<RDF::vCard::Entity>.

=head1 SEE ALSO

L<RDF::iCalendar>, L<RDF::vCard::Entity>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT

Copyright 2011, 2013 Toby Inkster

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
