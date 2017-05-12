#!/usr/bin/perl -w
use strict;
use Calc;

my $parser = Calc->new();
$parser->input(<<'EOI'
a = 2*3       # 1: 6
d = 5/(a-6)   # 2: division by zero
b = (a+1)/7   # 3: 1
c=a*3+4)-5    # 4: syntax error
a = a+1       # 5: 7
EOI
);
my $t = $parser->Run();
print "========= Symbol Table ==============\n";
print "$_ = $t->{$_}\n" for sort keys %$t;

