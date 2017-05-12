#!/usr/bin/perl
use warnings;
use strict;

use lib 'lib', '../lib';
use Test::More;

BEGIN {plan tests => 20}

use OODoc::Format::Pod;

my $pod = bless {}, 'OODoc::Format::Pod';

sub c($) { $pod->removeMarkup(@_) }

is(c("aap"), "aap"                 , 'simplest case');

is(c("   aap  
 	noot   "), "aap
noot"                              , 'test whitespace cleanup');

is(c("aE<sol>E<gt>E<lt>b"), "a/><b", 'test escapes');

is(c('C<aap>'), 'aap'              , 'ignore code markup');
is(c('I<aap>'), 'aap'              , 'ignore italics markup');
is(c('B<aap>'), 'aap'              , 'ignore bold markup');

is(c('X<aap>'), ''                 , 'no index');
is(c('Z<aap>'), ''                 , 'no format escape');

is(c('aap C<noot> C<mies>'), 'aap noot mies', 'multi');
is(c('a C<< b B< c > >> d'), 'a b c d'      , 'simple nesting');
is(c('a C< b B<< c >> > d'), 'a b c d'      , 'simple nesting');
is(c('C<<< C<a> I<<B<b> >> Z<> >>>'), 'a b' , 'most complex nesting');

is(c('L<manpage>'), 'manpage'                     , 'manpage');
is(c('L<manpage/SECT>')  , 'manpage section SECT' , 'manpage with section');
is(c('L<manpage/"SECT">'), 'manpage section SECT' , 'manpage with section');
is(c('L</"SECT">')       , 'section SECT'         , 'section');

is(c('L<text|manpage>')       , 'text', 'manpage');
is(c('L<text|manpage/SECT>')  , 'text', 'manpage with section');
is(c('L<text|manpage/"SECT">'), 'text', 'manpage with section');
is(c('L<text|/"SECT">')       , 'text', 'section');
