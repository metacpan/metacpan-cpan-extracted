#
# This file is part of Perl-Types
#
# This software is copyright (c) 2025 by Auto-Parallel Technologies, Inc.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
# [[[ HEADER ]]]
# ABSTRACT: enable Perl data types
package Perl::Types;
use strict;
use warnings;
our $VERSION = 0.005_000;

# [[[ INCLUDES ]]]
# DEV NOTE: these essential modules should be included automatically by all Perl code; do so with EXPORTS below
use English;  # prefer more expressive $ARG over $_, etc; LMPC #23: Thou Shalt Not Use ... Punctuation Variables ...
use Carp;  # prefer more expressive carp()/croak() over warn()/die();  LMPC #8: Thou Shalt ... Create Maintainable, Re-Grokkable Code ...
use Data::Dumper;  # prefer more expressive Dumper() over print(); LMPC #4: Thou Shalt ... Create ... Bug-Free, High-Quality Code ...
$Data::Dumper::Sortkeys = 1;  # sort hash keys

# DEV NOTE: when you include Perl::Types, you also include the modules above via the exports below

# [[[ EXPORTS ]]]
# DEV NOTE: do not export individual variables such as $ARG or @ARG, causes unexplainable errors such as incorrect subroutine arguments;
# export subroutines and typeglobs only;
# "Exporting variables is not a good idea. They can change under the hood, provoking horrible effects at-a-distance that are too hard to track and to fix. Trust me: they are not worth it."   https://perldoc.perl.org/Exporter#What-Not-to-Export
use Exporter qw(import);
our @EXPORT    = (@English::EXPORT, @Carp::EXPORT, @Data::Dumper::EXPORT);  # export all symbols imported from essential modules

# NEED ANSWER: do we need to change @LAST_MATCH_START and @LAST_MATCH_END, exported by English, to be typeglobs instead of array variables?
# NEED ANSWER: do we need to change @LAST_MATCH_START and @LAST_MATCH_END, exported by English, to be typeglobs instead of array variables?
# NEED ANSWER: do we need to change @LAST_MATCH_START and @LAST_MATCH_END, exported by English, to be typeglobs instead of array variables?

#print 'in Perl::Types, have @English::EXPORT = ', Dumper(\@English::EXPORT), "\n";
#die 'TMP DEBUG';



# START HERE: refactor out all of these types into their own .pm files, continue with long-term Perl types refactoring project
# START HERE: refactor out all of these types into their own .pm files, continue with long-term Perl types refactoring project
# START HERE: refactor out all of these types into their own .pm files, continue with long-term Perl types refactoring project

# [[[ DATA TYPES ]]]
package void; 1;
package boolean; 1;
package integer; 1;
package number; 1;
package character; 1;
package string; 1;
package arrayref; 1;
package hashref; 1;
package object; 1;

package integer::method; 1;

package string::arrayref; 1;
package string::hashref; 1;

package hashref::arrayref; 1;
package hashref::hashref; 1;
package hashref::hashref::hashref; 1;

package string::hashref::arrayref; 1;

package filehandleref; 1;

package void::method; 1;

package Perl::Types;

1;
