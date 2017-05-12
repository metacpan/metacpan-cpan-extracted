
use strict;
use Test::More tests => 3;

use_ok('Template::Plugin::ListCompare');

my $template = Template::Plugin::ListCompare->new(1, 2, 3, 4);

can_ok($template, 'new');

ok($template->isa('List::Compare'), 'Plugin is List::Compare');
