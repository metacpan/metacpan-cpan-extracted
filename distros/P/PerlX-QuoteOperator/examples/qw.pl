#!/usr/bin/env perl

use strict;
use warnings;
use 5.010;

# some qw// examples

use PerlX::QuoteOperator qwuc => { 
    -debug      => 1,
    -emulate    => 'qw', 
    -with       => sub (@) { map { uc } @_ },
};

# yikes.. it does qw/one two three/ as well!  
say qwuc/foo bar baz/, qw/one two three/;

# above doesn't work because this is the transmogrified line
# say qwuc qw/foo bar baz/, qw/one two three/;

# so must implictly cover off the corners!
say ((qwuc/foo bar baz/), qw/one two three/);

# or enforce the -parser option
use PerlX::QuoteOperator qwucx => { 
    -debug      => 1,
    -emulate    => 'qw',
    -parser     => 1,
    -with       => sub (@) { map { uc } @_ },
};

# now works as expected
say qwucx/foo bar baz/, qw/one two three/;

# because this is what it now looks like
# say qwucx(qw/foo bar baz/), qw/one two three/;


# lets do list to hash
use PerlX::QuoteOperator qwHash => { 
    -debug      => 1,
    -emulate    => 'qw',
    -with       => sub (@) { my $n; map { $_ => ++$n } @_ },
};

my %months = qwHash/Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec/;

say $months{ Jun };