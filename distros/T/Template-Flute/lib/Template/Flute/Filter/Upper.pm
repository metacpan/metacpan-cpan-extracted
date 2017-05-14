package Template::Flute::Filter::Upper;

use strict;
use warnings;

use base 'Template::Flute::Filter';

=head1 NAME

Template::Flute::Filter::Upper - Uppercase filter

=head1 DESCRIPTION

Uppercase filter.

=head1 METHODS

=head2 filter

Uppercase filter.

=cut

sub filter {
    my ($self, $value) = @_;

    return uc($value);
}

=head1 AUTHOR

Stefan Hornburg (Racke), <racke@linuxia.de>

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Stefan Hornburg (Racke) <racke@linuxia.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
