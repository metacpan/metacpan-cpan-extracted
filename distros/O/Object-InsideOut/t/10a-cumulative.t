use strict;
use warnings;

use Test::More 'tests' => 1;

package Base1; {
    use Object::InsideOut;

    sub foo :Cumulative :MergedArgs
    {
        my ($self, $args) = @_;
        my $pkg = __PACKAGE__;
        return ($args->{$pkg});
    }
}

package Base2; {
    use Object::InsideOut qw(Base1);

    sub foo :Cumulative :MergedArgs
    {
        my ($self, $args) = @_;
        my $pkg = __PACKAGE__;
        return ($args->{$pkg});
    }
}

package Base3; {
    use Object::InsideOut qw(Base1);

    sub foo :Cumulative :MergedArgs
    {
        my ($self, $args) = @_;
        my $pkg = __PACKAGE__;
        return ($args->{$pkg});
    }
}

package Base4; {
    use Object::InsideOut;

    sub foo :MergedArgs  # but not Cumulative!
    {
        my ($self, $args) = @_;
        my $pkg = __PACKAGE__;
        return ($args->{$pkg});
    }
}

package Der1; {
    use Object::InsideOut qw(Base2 Base3 Base4);

    sub foo :Cumulative :MergedArgs
    {
        my ($self, $args) = @_;
        my $pkg = __PACKAGE__;
        return ($args->{$pkg});
    }
}

package Der2; {
    use Object::InsideOut qw(Base2 Base3 Base4);

    sub foo :Cumulative :MergedArgs
    {
        my ($self, $args) = @_;
        my $pkg = __PACKAGE__;
        return ($args->{$pkg});
    }
}

package Reder1; {
    use Object::InsideOut qw(Der1 Der2);

    sub foo :Cumulative :MergedArgs
    {
        my ($self, $args) = @_;
        my $pkg = __PACKAGE__;
        return ($args->{$pkg});
    }
}

package main;

MAIN:
{
    my $obj = Reder1->new();

    my @expected = ('foo', 'bar', 'baz', 'bing', 'bang', 'bong');

    my @got = $obj->foo( 'Base1'  => 'foo',
                       { 'Base2'  => 'bar', },
                       { 'Base3'  => 'baz',
                         'Der1'   => 'bing', },
                         'Der2'   => 'bang',
                       { 'Reder1' => 'bong', } );

    is_deeply(\@got, \@expected => 'Cumulative methods with merged args');
}

exit(0);

# EOF
