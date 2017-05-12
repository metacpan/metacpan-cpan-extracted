#!/usr/bin/env perl
use strict;

=head1 NAME

section - select document sections

=head1 SYNOPSIS

  section --select-id foo --select-class bar --select-name "the title"
  section --select '#foo' --select .bar --select '"the title"'

=cut

use Pandoc::Filter;

=head1 DESCRIPTION

    ---
    multifilter:
      - filter: section
      - options:
        - select: .keep
    ...

=cut

# TODO: get options

my @select = ('.keep'); # TODO: use Pandoc::Element::Selector;
my $level = 0;

# process all elements
pandoc_filter sub {
    my $e = shift;

    if ($level > 0) {
        if ($_->name eq 'Header' and $e->level <= $level) {
            $level = 0;     # end of currently selected section
        } else {
            return;         # keep element in selected section
        }
    }

    if ($e->name eq 'Header' and grep { $e->match($_) } @select ) {
        $level = $e->level; # new selected section
        return;             # keep Header
    } else {
        return [];          # skip
    }
};
