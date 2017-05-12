#!/usr/bin/env perl
use strict;

=head1 DESCRIPTION

Pandoc filter to convert all regular text to uppercase.
Code, link URLs, etc. are not affected.

=cut

use Pandoc::Filter;
use Pandoc::Elements qw(Str);

pandoc_filter Str => sub {
    return Str(uc $_->content);
    # alternatively to modify in-place (comment out previous line to enable)
    $_->content(uc($_->content));
    return
};

=head1 SYNOPSIS

  pandoc --filter caps.pl -o output.html < input.md

=head1 SEE ALSO

This is a port of
L<caps.py|https://github.com/jgm/pandocfilters/blob/master/examples/caps.py>
from Python to Perl with L<Pandoc::Elements> and L<Pandoc::Filter>.

=cut
