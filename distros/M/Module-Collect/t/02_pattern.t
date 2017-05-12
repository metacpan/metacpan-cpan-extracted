use strict;
use warnings;
use Test::More tests => 2;

use File::Spec::Functions;

use Module::Collect;

my $collect = Module::Collect->new( path => catfile('t', 'plugins'), pattern => '*.plugin' );
is $collect->modules->[0]->{package}, 'Baz';
is scalar(@{ $collect->modules }), 1;
