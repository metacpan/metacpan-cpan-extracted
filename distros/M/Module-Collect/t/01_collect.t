use strict;
use warnings;
use Test::More tests => 4;

use File::Spec::Functions;

use Module::Collect;

my $collect = Module::Collect->new( path => catfile('t', 'plugins') );

my($pkg1) = grep { $_ eq 'MyApp::Foo' } map { $_->{package} } @{ $collect->modules };
is $pkg1, 'MyApp::Foo';

my($pkg2) = grep { $_ eq 'error' } map { $_->{package} } @{ $collect->modules };
ok !$pkg2;

my($pkg3) = grep { $_ eq 'With::Pod' } map { $_->{package} } @{ $collect->modules };
is $pkg3, 'With::Pod';

my($pkg4) = grep { $_ eq 'With::Comment' } map { $_->{package} } @{ $collect->modules };
is $pkg4, 'With::Comment';
