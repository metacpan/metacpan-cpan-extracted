package _common;

# common parts for Struct::Path tests

use Data::Dumper qw();
use parent qw(Exporter);

our @EXPORT_OK = qw(scmp sdump);

sub scmp($$) {
    return "GOT: " . sdump(shift) . ";\nEXP: " . sdump(shift) . ";";
}

sub sdump($) {
    return Data::Dumper->new([shift])->Terse(1)->Sortkeys(1)->Quotekeys(0)->Indent(0)->Deepcopy(1)->Dump();
}

1;
