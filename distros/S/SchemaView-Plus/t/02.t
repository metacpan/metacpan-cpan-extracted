# test loading

BEGIN { $| = 1; print "1..4\n"; }
END { print "not ok 1\n" unless $loaded; }

use Hints;

$loaded = 1;
print "ok 1\n";

# test output from module

my @data = <DATA>;

my $hints = new Hints;

$hints->load_from_file(\@data);

print "not " if $hints->count() != 3 or $hints->first() ne 'First' 
		or $hints->next() ne 'Second' or not defined $hints->item(3);

print "ok 2\n";

$hints->clear;

print "not " if $hints->count();

print "ok 3\n";

$hints->load_from_file(\@data,'@-@');

print "not " if $hints->count() != 2;
# or $hints->item(1) ne 'Special' ;

print "ok 4\n";

__DATA__
First
---
Second
---
Third
@-@
Special
