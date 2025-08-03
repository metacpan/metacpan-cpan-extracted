use warnings;
use strict;

package Tools;

use OODoc::Template;
use parent 'Exporter';
use Test::More;

our @EXPORT = qw/do_process/;

sub do_process($@)
{   my $t   = shift;
    my ($out, $tree) = $t->process(@_);

    ok(defined $out);
    ok(defined $tree);
    isa_ok($tree, 'ARRAY');

    $out;
}

1;
