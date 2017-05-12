#!/usr/bin/perl -w

use strict;

use Test::More tests => 7;
use Test::Exception;

use String::Expand qw(
   expand_strings
);

my %s;

%s = ( foo => 'one', bar => 'two' );
expand_strings( \%s, {} );
is_deeply( \%s, { foo => 'one', bar => 'two' }, 'Plain strings' );

%s = ( foo => 'one is $ONE', bar => 'two is $TWO' );
expand_strings( \%s, { ONE => 1, TWO => 2 } );
is_deeply( \%s, { foo => 'one is 1', bar => 'two is 2' }, 'Independent strings' );

%s = ( dollar => '\$', slash => '\\\\', combination => 'dollar is \$, slash is \\\\' );
expand_strings( \%s, {} );
is_deeply( \%s, { dollar => '$', slash => '\\', combination => 'dollar is $, slash is \\' },
           'Strings with literals' );

%s = ( foo => 'bar is ${bar}', bar => 'quux' );
expand_strings( \%s, {} );
is_deeply( \%s, { foo => 'bar is quux', bar => 'quux' }, 'Chain of strings (no overlay)' );

%s = ( foo => 'bar is ${bar}', bar => 'quux is ${quux}' );
expand_strings( \%s, { quux => 'splot' } );
is_deeply( \%s, { foo => 'bar is quux is splot', bar => 'quux is splot' }, 'Chain of strings (with overlay)' );

%s = ( foo => '${foo}' );
dies_ok( sub { expand_strings( \%s, {} ) },
         'Exception (loop) throws exception' );

%s = ( foo => 'bar is ${bar}', bar => 'quux' );
expand_strings( \%s, { bar => 'splot' } );
is_deeply( \%s, { foo => 'bar is quux', bar => 'quux' }, 'Chain with overlay' );
