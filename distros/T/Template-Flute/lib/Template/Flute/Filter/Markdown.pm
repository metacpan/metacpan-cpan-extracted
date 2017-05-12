package Template::Flute::Filter::Markdown;

use strict;
use warnings;

use base 'Template::Flute::Filter';

use HTML::Scrubber;
use Text::Markdown;

=head1 NAME

Template::Flute::Filter::Markdown - markdown filter

=head1 DESCRIPTION

Turns text in Markdown format into HTML. The HTML
is subject to scrubbing with L<HTML::Scrubber>.

=head1 PREREQUISITES

L<HTML::Scrubber> module.
L<Text::Markdown> module.

=head1 METHODS

=head2 filter

Markdown filter.

=cut

sub filter {
    my ( $self, $value ) = @_;

    my $m = Text::Markdown->new;
    my $s = HTML::Scrubber->new(
        allow => [
            qw/
              a abbr b blockquote br caption cite colgroup dd del dl dt em
              h1 h2 h3 h4 h5 h6 hr i img ins li ol p pre q small strong sub
              sup table tbody td tfoot th thead tr u ul
              /
        ]
    );
    $s->rules(
        a => {
            href => 1,
            '*' => 0,
        },
        img => {
            src => 1,
            alt => 1,
            '*' => 0,
        },
    );
    return $s->scrub( $m->markdown($value) );
}

=head1 AUTHOR

Peter Mottram (SysPete), <peter@sysnix.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2011-2016 Stefan Hornburg (Racke) <racke@linuxia.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
