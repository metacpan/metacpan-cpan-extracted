package Nitesi::Core::Types;

use strict;
use warnings;

use MooX::Types::MooseLike 0.16;
use MooX::Types::MooseLike::Base qw/:all/;

use Exporter 'import';
our @EXPORT;
our @EXPORT_OK;

# Export everything by default.
@EXPORT = (@MooX::Types::MooseLike::Base::EXPORT_OK, @EXPORT_OK);

=head1 NAME

Nitesi::Core::Types - Type definitions for Nitesi Shop Machine

=head1 SEE ALSO

L<MooX::Types::MooseLike> for more available types

=head1 AUTHOR

Stefan Hornburg (Racke), <racke@linuxia.de>

=head1 LICENSE AND COPYRIGHT

Copyright 2012-2013 Stefan Hornburg (Racke) <racke@linuxia.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
