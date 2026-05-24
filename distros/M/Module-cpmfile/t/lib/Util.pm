package Util;
use v5.24;
use warnings;
use experimental qw(lexical_subs signatures);

use Exporter 'import';
our @EXPORT = qw(dumper);

use Data::Dumper ();

sub dumper (@args) {
    my $dumper = Data::Dumper->new(\@args);
    $dumper->Indent(1)->Terse(1);
    $dumper->Sortkeys(1) if $dumper->can("Sortkeys");
    $dumper->Dump;
}

1;
