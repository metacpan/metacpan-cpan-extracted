#!/usr/bin/perl

##
## Tests for Petal::Utils :uri modifiers
##

use blib;
use strict;
#use warnings;

use Test::More qw( no_plan );

use Carp;
use t::LoadPetal;

use Petal::Utils qw( :uri );

my $hash = {
	and    => 'this&that',
	space  => 'this that',
	comma  => 'this,that',
	scolon => 'this;that',
	slash  => 'this/that',
	qmark  => 'this?that',
	dot    => 'this.that',
};
my $template = Petal->new('uri.html');
my $out      = $template->process( $hash );

# UriEscape
like($out, qr/this\%26that/, '&');
like($out, qr/this\%20that/, "' '");
like($out, qr/this\%2Cthat/, ',');
like($out, qr/this\%3Bthat/, ';');
like($out, qr/this\%2Fthat/, '/');
like($out, qr/this\%3Fthat/, '?');
like($out, qr/this\.that/,   '.');
# that's enough proof for me.
