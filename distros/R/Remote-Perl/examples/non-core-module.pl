# Run with: remperl HOST examples/non-core-module.pl
# Demonstrates module serving: uses Text::ASCIITable (not a core module).
use v5.36;
use Text::ASCIITable;

my $t = Text::ASCIITable->new({ headingText => 'Greeting' });
$t->setCols('Message');
$t->addRow('Hello World');
print $t;
