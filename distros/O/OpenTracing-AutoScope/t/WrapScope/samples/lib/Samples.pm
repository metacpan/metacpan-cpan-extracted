package Sample1;
sub foo { }
sub bar { }
sub baz { }

package Sample2;
sub foo { }
sub bar { }
sub baz { }

package Sample3;
sub foo { }
sub bar { }
sub baz { }

package Samples;

sub run {
    Sample1::foo();
    Sample1::bar();
    Sample1::baz();
    Sample2::foo();
    Sample2::bar();
    Sample2::baz();
    Sample3::foo();
    Sample3::bar();
    Sample3::baz();
}

1;
