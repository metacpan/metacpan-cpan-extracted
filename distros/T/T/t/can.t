use T2::B 'Extended';
use T2;

t2->ok(!T2->can('ok'), "T2 can() does not give false positives");
t2->ok(T2->can('import'), "T2 can() still works");
t2->ok(t2->can('ok'), "can() on the object t2() returns gives us the function");

t2->done_testing;
