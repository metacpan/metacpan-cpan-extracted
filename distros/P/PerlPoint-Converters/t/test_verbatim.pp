
=Verbatim Blocks

This tests verbatim blocks:

 # Sample Perl code:
 my $scalar=4;
 my $sref = \\$scalar;

Then same code in a real verbatim block:

<<BLOCK
 # Sample Perl code:
 my $scalar=4;
 my $sref = \$scalar;
BLOCK
