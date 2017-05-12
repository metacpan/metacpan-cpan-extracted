use strict;
use warnings;

use Test::More 'tests' => 2;

package Base1; {
    use Object::InsideOut;

    sub base_first :Chained            { shift; return(@_, __PACKAGE__); }
    sub der_first  :Chained(bottom up) { shift; return(@_, __PACKAGE__); }
}

package Base2; {
    use Object::InsideOut qw(Base1);

    sub base_first :Chained            { shift; return(@_, __PACKAGE__); }
    sub der_first  :Chained(bottom up) { shift; return(@_, __PACKAGE__); }
}

package Base3; {
    use Object::InsideOut qw(Base1);

    sub base_first :Chained            { shift; return(@_, __PACKAGE__); }
    sub der_first  :Chained(bottom up) { shift; return(@_, __PACKAGE__); }
}

package Base4; {
    use Object::InsideOut;

    sub base_first                     { shift; return(@_, __PACKAGE__); }
    sub der_first                      { shift; return(@_, __PACKAGE__); }
}

package Der1; {
    use Object::InsideOut qw(Base2 Base3 Base4);

    sub base_first :Chained            { shift; return(@_, __PACKAGE__); }
    sub der_first  :Chained(bottom up) { shift; return(@_, __PACKAGE__); }
}

package Der2; {
    use Object::InsideOut qw(Base2 Base3 Base4);

    sub base_first :Chained            { shift; return(@_, __PACKAGE__); }
    sub der_first  :Chained(bottom up) { shift; return(@_, __PACKAGE__); }
}

package Reder1; {
    use Object::InsideOut qw(Der1 Der2);

    sub base_first :Chained            { shift; return(@_, __PACKAGE__); }
    sub der_first  :Chained(bottom up) { shift; return(@_, __PACKAGE__); }
}

package main;

MAIN:
{
    my $obj = Reder1->new();

    my @top_down = $obj->base_first();
    my @bot_up   = $obj->der_first();

    my @my_top_down = qw(Base1 Base2 Base3 Der1 Der2 Reder1);
    my @my_bot_up   = qw(Reder1 Der2 Der1 Base3 Base2 Base1);

    is_deeply(\@top_down, \@my_top_down      => 'List chained down');
    is_deeply(\@bot_up,   \@my_bot_up        => 'List chained up');
}

exit(0);

# EOF
