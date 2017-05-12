package POE::Declare::Meta::Internal;

=pod

=head1 NAME

POE::Declare::Meta::Internal - Reserve a named slot for internal use

=head1 SYNOPSIS

  declare privatevar => 'Internal';

=head1 DESCRIPTION

B<POE::Declare::Meta::Internal> is a L<POE::Declare::Meta::Slot> sub-class
that is used to reserve a slot name purely for internal use.

In practice, all this declaration really does is to guarentee that the
HASH key for that name will never be used by any other part of the object
or by any child classes.

=cut

use 5.008007;
use strict;
use warnings;
use POE::Declare::Meta::Slot ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '0.59';
	@ISA     = 'POE::Declare::Meta::Slot';
}

1;

=pod

=head1 SUPPORT

Bugs should be always be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=POE-Declare>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<POE>, L<POE::Declare>

=head1 COPYRIGHT

Copyright 2006 - 2012 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
