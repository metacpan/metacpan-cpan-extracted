#!/usr/bin/env perl
use strict;

=head1 NAME

unnumbered-sections - remove all unnumbered sections

=head1 DESCRIPTION

This Pandoc filter removes all unnumbered sections, that is everything from a
header with class C<unnumbered> until the next normal header of the same level.
For instance this document:

   # Section

   # Unnumbered Section {.unnumbered}
   ...

   ## Subsection
   ...

   # Another Section
   ... 
     
Would be reduced to

   # Section
    
   # Another Section
   ... 

=cut

use Pandoc::Filter;

my $skiplevel = 0;

# process all elements
pandoc_filter sub {

    if ($skiplevel > 0) {
        # end of currently skipped section
        if ($_->name eq 'Header' and $_->level <= $skiplevel) {
            $skiplevel = 0;
        # remove element
        } else {
            return []; 
        }
    }

    # new unnumbered section to skip
    if ($_->match('Header.unnumbered')) {
        $skiplevel = $_->level;
        return [];
    }
    
    # keep element
    return
};

