use strict;
use warnings;

use Test::More tests => 5;

package Local::Point;
BEGIN { ::use_ok 'My::Object', { x => 0, y => 0 } }

sub dump {
    my $p = shift;
    return sprintf 'Point(%i,%i)', $p->x, $p->y;
}

package Local::Point3d;
use subs qw(dump);
BEGIN { ::use_ok 'Local::Point', { z => 0 } }

sub dump {
    my $p = shift;
    return sprintf 'Point3d(%i,%i,%i)', $p->x, $p->y, $p->z;
}

package main;
my $p = Local::Point::NEW->(x => 1, y => 2);
is $p->dump, 'Point(1,2)', 'call method';

*p3d = Local::Point3d::NEW;
my $q = p3d(x => 3, y => 4, z => 5);
is $q->dump, 'Point3d(3,4,5)', 'call child method';
is Local::Point::dump($q), 'Point(3,4)', 'call parent method';
