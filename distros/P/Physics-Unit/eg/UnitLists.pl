# This is a simple test program to list data from the Unit
# module.  This is similar to UnitGenPages.pl, but this prints in
# text format to STDOUT, whereas that prints HTML format to two files.

use Physics::Unit ':ALL';

@units = ListUnits;
print "Units:\n";
for $n (@units) {
    $u = GetUnit($n);
    printf("%25s: %30s %35s %20s\n", $n, $u->def, $u->expanded, $u->type);
}

@types = ListTypes;
print "Types are:\n";
print "  ", join ",\n  ", ListTypes();
print "\n\n";

