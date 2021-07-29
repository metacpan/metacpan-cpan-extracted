package Util;
use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw(dumper);

use Data::Dumper ();

sub dumper {
    my $dumper = Data::Dumper->new(\@_);
    $dumper->Indent(1)->Terse(1);
    $dumper->Sortkeys(1) if $dumper->can("Sortkeys");
    $dumper->Dump;
}

1;
