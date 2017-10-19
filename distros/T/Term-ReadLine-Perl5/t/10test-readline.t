# -*- perl -*-
#  Test script for Term::ReadLine:Perl
#
#  Adapted from readline.t of Term::ReadLine::Gnu
#	Copyright (c) 2010 Hiroo Hayashi.  All rights reserved.
#
#	This program is free software; you can redistribute it and/or
#	modify it under the same terms as Perl itself.

use strict; use warnings;

# Note: we don't use Helper here. Should we?
use lib '../lib' ;
use Test::More;

BEGIN {
    $ENV{PERL_RL} = 'Perl5';	# force to use Term::ReadLine::Perl5
    $ENV{LANG} = 'C';
    $ENV{'COLUMNS'} = 80;
    $ENV{'LINES'} = 25;
    # stop reading ~/.inputrc
    $ENV{'INPUTRC'} = '/dev/null';
}

use Term::ReadLine::Perl5;

my $verbose = @ARGV && ($ARGV[0] eq 'verbose');
########################################################################
# test new method

my $t;
eval { $t  = Term::ReadLine::Perl5->new('ReadLineTest'); };
plan skip_all => "Need access to tty" unless $t;
ok($t, "new method, new's");

my $OUT;
if ($verbose) {
    $OUT = $t->OUT;
} else {
    open(NULL, '>/dev/null') or die "cannot open \`/dev/null\': $!\n";
    $OUT = \*NULL;
    $t->Attribs->{outstream} = \*NULL;
}

########################################################################
note('ReadLine method');

is($t->ReadLine, 'Term::ReadLine::Perl5',
   "Package name should be 'Term::ReadLine::Perl5'");

########################################################################

my %features = %{ $t->Features };
my $res = %features;
ok($res, 'Got Features method');

note('MinLine()');
my $old_value = $t->MinLine();
is($t->MinLine(), $old_value,
   "MinLine() with nothing should not change anything");
is($t->MinLine(20), $old_value,
   "MinLine(20) should return previous value $old_value");
is($t->MinLine($old_value), 20,
   "MinLine(20) should return value we just set: 20");

done_testing();
