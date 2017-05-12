use lib (-e 't' ? 't' : 'test'), 'inc';
use TestModuleCompile tests => 1;

no_diff;
filters {
    pm => 'process_pm',
};

pass 'Lexical compilation not implemented yet';

#run_is pm => 'pmc';

__DATA__

=== Apply lexically to bare block.
--- pm
package Foo;

lower lower lower
{
    use Upper;
    lower lower lower
}
lower lower lower
--- pmc
package Foo;

lower lower lower
{
    LOWER LOWER LOWER
}
lower lower lower
