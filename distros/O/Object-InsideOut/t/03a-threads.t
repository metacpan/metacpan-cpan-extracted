use strict;
use warnings;

use Config;
BEGIN {
    if (! $Config{useithreads} || $] < 5.008) {
        print("1..0 # Skip Threads not supported\n");
        exit(0);
    }
}

use threads;
use threads::shared;

if ($] == 5.008) {
    require 't/test.pl';   # Test::More work-alike for Perl 5.8.0
} else {
    require Test::More;
}
Test::More->import();
plan('tests' => 12);


package My::Obj; {
    use Object::InsideOut;

    my @x : Field({'accessor'=>'x'});
}

package My::Obj::Sub; {
    use Object::InsideOut qw(My::Obj);

    my @y : Field({'accessor'=>'y'});
}


package main;

MAIN:
{
    my $obj = My::Obj->new();
    $obj->x(5);
    is($obj->x(), 5, 'Class set data');

    my $obj2 = My::Obj::Sub->new();
    $obj2->x(9);
    $obj2->y(3);
    is($obj2->x(), 9, 'Subclass set data');
    is($obj2->y(), 3, 'Subclass set data');

    my $rc = threads->create(
                        sub {
                            is($obj->x(), 5, 'Thread class data');
                            is($obj2->x(), 9, 'Thread subclass data');
                            is($obj2->y(), 3, 'Thread subclass data');

                            $obj->x([1, 2, 3]);
                            $obj2->x(99);
                            $obj2->y(3-1);

                            is_deeply($obj->x(), [1, 2, 3], 'Thread class data');
                            is($obj2->x(), 99, 'Thread subclass data');
                            is($obj2->y(), 2, 'Thread subclass data');

                            return (1);
                        }
                    )->join();

    is($obj->x(), 5, 'Class data unchanged');
    is($obj2->x(), 9, 'Subclass data unchanged');
    is($obj2->y(), 3, 'Subclass data unchanged');
}

exit(0);

# EOF
