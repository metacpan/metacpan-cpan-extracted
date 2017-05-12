use strict;
use warnings;

use Test::More 'tests' => 62;

package Base1; {
    use Object::InsideOut;

    sub base_first :Cumulative(top down)  { shift; return(@_, __PACKAGE__); }
    sub der_first  :Cumulative(bottom up) { shift; return(@_, __PACKAGE__); }
    sub shift_obj  :Cumulative            { return shift; }
}

package Base2; {
    use Object::InsideOut qw(Base1);

    sub base_first :Cumulative            { shift; return(@_, __PACKAGE__); }
    sub der_first  :Cumulative(bottom up) { shift; return(@_, __PACKAGE__); }
    sub shift_obj  :Cumulative            { return shift; }
}

package Base3; {
    use Object::InsideOut qw(Base1);

    sub base_first :Cumulative            { shift; return(@_, __PACKAGE__); }
    sub der_first  :Cumulative(bottom up) { shift; return(@_, __PACKAGE__); }
    sub shift_obj  :Cumulative            { return shift; }
}

package Base4; {
    use Object::InsideOut;

    sub base_first                     { shift; return(@_, __PACKAGE__); }
    sub der_first                      { shift; return(@_, __PACKAGE__); }
}

package Der1; {
    use Object::InsideOut qw(Base2 Base3 Base4);

    sub base_first :Cumulative            { shift; return(@_, __PACKAGE__); }
    sub der_first  :Cumulative(bottom up) { shift; return(@_, __PACKAGE__); }
    sub shift_obj  :Cumulative            { return shift; }
}

package Der2; {
    use Object::InsideOut qw(Base2 Base3 Base4);

    sub base_first :Cumulative            { shift; return(@_, __PACKAGE__); }
    sub der_first  :Cumulative(bottom up) { shift; return(@_, __PACKAGE__); }
    sub shift_obj  :Cumulative            { return shift; }
}

package Reder1; {
    use Object::InsideOut qw(Der1 Der2);

    sub base_first :Cum            { shift; return(@_, __PACKAGE__); }
    sub der_first  :Cum(bottom up) { shift; return(@_, __PACKAGE__); }
    sub shift_obj  :Cum(top down)  { return shift; }
}

package main;

MAIN:
{
    my $obj = Reder1->new();

    for (1..2) {
        my $top_down = $obj->base_first();
        my $bot_up   = $obj->der_first();
        my $objs     = $obj->shift_obj();

        my @top_down = qw(Base1 Base2 Base3 Der1 Der2 Reder1);
        my @bot_up   = qw(Reder1 Der2 Der1 Base3 Base2 Base1);
        my @objs     = ($obj) x 6;

        is_deeply(\@$top_down, \@top_down      => 'List chained down');
        is_deeply(\@$bot_up,   \@bot_up        => 'List chained up');

        is(int $bot_up,   int @bot_up          => 'Numeric chained up');
        is(int $top_down, int @top_down        => 'Numeric chained down');

        is("$bot_up",   join(q{}, @bot_up)     => 'String chained up');
        is("$top_down", join(q{}, @top_down)   => 'String chained down');

        for my $pkg (keys(%{$bot_up})) {
            ok(grep($pkg, @bot_up)   => "Valid up hash key ($pkg)");
            is($pkg, $bot_up->{$pkg} => "Valid up hash value ($pkg)");
        }

        while(my $pkg = each(%{$top_down})) {
            ok(grep($pkg, @top_down) => "Valid down hash key ($pkg)");
            is($pkg, $bot_up->{$pkg} => "Valid down hash value ($pkg)");
        }

        is_deeply(\@$objs, \@objs    => 'shift(@_) used in method');
    }
}

exit(0);

# EOF
