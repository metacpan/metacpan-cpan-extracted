package t::lib::Foo;
use strict;
use warnings;
use base qw(Exporter);
our @EXPORT = qw(add);
use Smart::Args;

sub add {
    args my $x => 'Num', my $y => 'Num';
    return $x + $y;
}
1;
