#!/usr/local/bin/perl

BEGIN { push(@INC, './t') }
use W;
print W->new()->test('test3', "examples/ctokens.pl", *DATA);

__END__
1
+
2
