package Template::Flute::Filter::Strip;

use strict;
use warnings;

use base 'Template::Flute::Filter';

=head1 NAME

Template::Flute::Filter::Strip - Strip filter

=head1 DESCRIPTION

This filter strips whitespace from the beginning and
the end of a string.

=head1 METHODS

=head2 filter

Strips leading and trailing whitespace.

=cut

sub filter {
    my ($self, $value) = @_;

	$value =~ s/^\s+//;
	$value =~ s/\s+$//;

    return $value;
}

=head1 AUTHOR

Stefan Hornburg (Racke), <racke@linuxia.de>

=head1 LICENSE AND COPYRIGHT

Copyright 2013-2016 Stefan Hornburg (Racke) <racke@linuxia.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
