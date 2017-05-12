#!/usr/local/bin/perl
#
# $Id: unicode.pl,v 0.1 2006/03/25 10:43:27 dankogai Exp dankogai $
#
use strict;
use warnings;
use lib './lib';

use Poem qw/-review/;
Perlハカー 金と力は なかりけり
弾 the Just Another Perl Poet
no Poem;

use Poem qw/-review -utf8/;
Perlハカー 金と力は なかりけり
弾 the Just Another Perl Poet
no Poem;

use Poem qw/-review -utf8 -deparse/;
Perlハカー 金と力は なかりけり
弾 the Just Another Perl Poet
no Poem;
__END__
