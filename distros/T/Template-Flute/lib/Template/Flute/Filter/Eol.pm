package Template::Flute::Filter::Eol;

use strict;
use warnings;

use base 'Template::Flute::Filter';

=head1 NAME

Template::Flute::Filter::Eol - Preserving line breaks in HTML output

=head1 DESCRIPTION

The EOL (end-of-line) filter turns line breaks into HTML <br>
elements.

=head1 METHODS

=head2 twig

Replaces the content of given L<XML::Twig::Elt> element with
the text value, preserving line breaks.

=cut

sub twig {
    my ($self, $elt, $value) = @_;
    my (@lines, @elts);

    # cut text into lines (set split limit to -1 to catch trailing linebreaks)
    @lines = split(/\r?\n/, $value, -1);

    for (my $i = 0; $i < @lines; $i++) {
	# add text element
	if (length($lines[$i])) {
	    push (@elts, $lines[$i]);
	}

	# add HTML linebreak
	push (@elts, XML::Twig::Elt->new(br   => '#EMPTY'));
    }

    # pop last HTML linebreak
    pop (@elts);

    if (@elts) {
	$elt->set_content(@elts);
    }
    else {
	$elt->cut_children();
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
