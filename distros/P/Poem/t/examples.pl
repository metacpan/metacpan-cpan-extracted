#!/usr/local/bin/perl
#
# $Id: examples.pl,v 0.1 2006/03/25 10:43:27 dankogai Exp dankogai $
#
use strict;
use warnings;
use lib './lib';
# Just prints a poem.
use Poem;
There are more than one way to do it. -- Larry Wall
no Poem;

# now let perl review it
use Poem qw/-review/;
There are more than one way to do it. -- Larry Wall
no Poem;

# one more time with "Do"
use Poem qw/-review/;
There are more than one way to Do it. -- Larry Wall
no Poem;

# this works
use Poem qw/-review/;
$Perl = "Practical Extractaction and Report Language";
no Poem;

# but not under stricture
use Poem qw/-review -strict/;
$Perl = "Pathologically Eclectic Rubbish Lister";
no Poem;

# Surprisingly, this works even under stricture
use Poem qw/-review -strict/;
Just Another Perl Poet
no Poem;

# Let perl deparse it
use Poem qw/-review -deparse/;
Just Another Perl Poet
no Poem;

# Who said talk is cheap?
use Poem qw/-review -act/;
Just Another Perl Poet
no Poem;

# This is truly a no-op
use Poem -quiet;
Just Another Perl Poet
no Poem;
__END__
