package Template::Flute::Filter::NobreakSingle;

use strict;
use warnings;

use base 'Template::Flute::Filter';

=head1 NAME

Template::Flute::Filter::NobreakSingle - Replaces missing text with no-break space.

=head1 DESCRIPTION

The nobreak_single filter replaces missing text with no-break space UTF8 character
(U+00A0).

=head1 METHODS

=head2 twig

Replaces the content of given L<XML::Twig::Elt> element with
no-break space UTF8 character if found to be empty or consisting
of white space only.

=cut

sub twig {
    my ($self, $elt, $value) = @_;

    if ($value =~ /\S/) {
	$elt->set_text($value);
    }
    else {
	$elt->set_content("\x{a0}");
    }

    return $elt;
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
