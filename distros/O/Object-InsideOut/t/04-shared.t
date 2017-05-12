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
plan('tests' => 16);


package My::Obj; {
    use Object::InsideOut;

    my %x : Field({'accessor'=>'x'});
    my %data :Field
             :Type(numeric)
             :All(data);
}

package My::Obj::Sub; {
    use Object::InsideOut ':SHARED', qw(My::Obj);

    my %y : Field({'accessor'=>'y'});
}


package main;

MAIN:
{
    SKIP: {
        skip('Shared in shared not supported', 4) if (($] < 5.008009) || ($threads::shared::VERSION lt '1.15'));

        # Test that obj IDs work for shared objects
        my $ot1 :shared;
        my $ot2 :shared;

        sub th
        {
            my $tid = threads->tid();

            if ($tid == 1) {
                $ot1 = My::Obj->new('data' => $tid);
                is($ot1->data(), $tid, 'Obj data is TID in thread');
            } else {
                $ot2 = My::Obj->new('data' => $tid);
                is($ot2->data(), $tid, 'Obj data is TID in thread');
            }
        }

        my $th1 = threads->create(\&th);
        my $th2 = threads->create(\&th);

        $th2->join();
        $th1->join();

        is($ot1->data(), 1, 'Obj data is TID in main');
        is($ot2->data(), 2, 'Obj data is TID in main');
    }

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

                            $obj->x([ 1, 2, 3]);
                            $obj2->x(99);
                            $obj2->y(3-1);

                            is_deeply($obj->x(), [1, 2, 3], 'Thread class data');
                            is($obj2->x(), 99, 'Thread subclass data');
                            is($obj2->y(), 2, 'Thread subclass data');

                            return (1);
                        }
                    )->join();

    is_deeply($obj->x(), [1, 2, 3], 'Thread class data');
    is($obj2->x(), 99, 'Thread subclass data');
    is($obj2->y(), 2, 'Thread subclass data');
}

exit(0);

# EOF
