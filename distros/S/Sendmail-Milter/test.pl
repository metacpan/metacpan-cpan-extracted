#
#  Copyright (c) 2000 Charles Ying. All rights reserved.
#
#  This program is free software; you can redistribute it and/or modify
#  it under the same terms as perl itself.
#
#  Please note that this code falls under a different license than the
#  other code found in Sendmail::Milter.
#

use ExtUtils::testlib;

use Sendmail::Milter;

sub dottedline { '-' x 72 . "\n"; }

sub perl_callback
{
	my $interp = shift;

	printf "---> Starting callback from interpreter: [0x%08x].\n", $interp;
	sleep 1;
	printf "---> Finished callback from interpreter: [0x%08x].\n", $interp;
}

print dottedline;
print "Interpreter pool tests. See sample.pl for a sample Milter.\n";
print dottedline;
print "Running starvation test... (Core dump indicates failure ;-)\n";
print dottedline;

Sendmail::Milter::test_intpools(1, 0, 2, 2, \&perl_callback);

# If we didn't core-dump, we're good. :)

print dottedline;
print "Starvation test successful.\n";
print dottedline;
print "Running multiplicity test... (Core dump indicates failure ;-)\n";
print dottedline;

Sendmail::Milter::test_intpools(0, 0, 2, 4, \&perl_callback);

# If we didn't core-dump, we're good. :)

print dottedline;
print "Multiplicity test successful.\n";
print dottedline;
print "Running scalar function name test... (Core dump indicates failure ;-)\n";
print dottedline;

Sendmail::Milter::test_intpools(0, 0, 2, 2, 'perl_callback');

print dottedline;
print "Scalar function name test successful.\n";
print dottedline;
print "Running closure test... (Core dump indicates failure ;-)\n";
print dottedline;

Sendmail::Milter::test_intpools(0, 0, 2, 2, sub
{
	my $interp = shift;
	
	printf "---> Starting callback from interpreter: [0x%08x].\n", $interp;
	sleep 1;
	printf "---> Finished callback from interpreter: [0x%08x].\n", $interp;
});

print dottedline;
print "Closure test successful.\n";
print dottedline;
print "Running recycle test... (Core dump indicates failure ;-)\n";
print dottedline;

Sendmail::Milter::test_intpools(0, 1, 2, 4, \&perl_callback);

print dottedline;
print "Recycle test successful.\n";
print dottedline;
print "All tests finished successfully.\n";
print dottedline;
