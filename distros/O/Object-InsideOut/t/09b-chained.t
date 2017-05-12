use strict;
use warnings;

use Test::More 'tests' => 3;

package Base1; {
    use Object::InsideOut;

    sub foo :Chained :MergedArgs :Restricted(Outside)
    {
        my ($self, $args) = @_;
        push(@{$args->{'list'}}, __PACKAGE__);
        return ({'list' => $args->{'list'}}, 'last' => __PACKAGE__);
    }
}

package Base2; {
    use Object::InsideOut qw(Base1);

    sub foo :Chained :MergedArgs
    {
        my ($self, $args) = @_;
        push(@{$args->{'list'}}, __PACKAGE__);
        return ('list' => $args->{'list'}, 'last' => __PACKAGE__);
    }
}

package Base3; {
    use Object::InsideOut qw(Base1);

    sub foo :Chained :MergedArgs
    {
        my ($self, $args) = @_;
        push(@{$args->{'list'}}, __PACKAGE__);
        return ({'list' => $args->{'list'}, 'last' => __PACKAGE__});
    }
}

package Base4; {
    use Object::InsideOut;

    sub foo :MergedArgs  # but not chained!
    {
        my ($self, $args) = @_;
        push(@{$args->{'list'}}, __PACKAGE__);
        $args->{'last'} = __PACKAGE__;
        return ($args);
    }
}

package Der1; {
    use Object::InsideOut qw(Base2 Base3 Base4);

    sub foo :Chained :MergedArgs :Restricted('', Prog)
    {
        my ($self, $args) = @_;
        push(@{$args->{'list'}}, __PACKAGE__);
        return ({'list' => $args->{'list'}}, {'last' => __PACKAGE__});
    }
}

package Der2; {
    use Object::InsideOut qw(Base2 Base3 Base4);

    sub foo :Chained :MergedArgs
    {
        my ($self, $args) = @_;
        push(@{$args->{'list'}}, __PACKAGE__);
        return ('list' => $args->{'list'}, {'last' => __PACKAGE__});
    }
}

package Reder1; {
    use Object::InsideOut qw(Der1 Der2);

    sub foo :Chained :MergedArgs
    {
        my ($self, $args) = @_;
        push(@{$args->{'list'}}, __PACKAGE__);
        $args->{'last'} = __PACKAGE__;
        return ($args);
    }

    sub get_foo
    {
        my $self = shift;
        return ($self->foo());
    }
}

package Outside; {
    use Object::InsideOut;

    sub bar
    {
        my $self = shift;
        my $obj  = shift;
        return ($obj->foo());
    }
}

package main;

MAIN:
{
    my $obj = Reder1->new();

    eval { $obj->foo() };
    like($@, qr/restricted method/ => ':Restricted + :Chained');

    my $expected = {
          'last' => 'Reder1',
          'list' => [
                      'Base1',
                      'Base2',
                      'Base3',
                      'Der1',
                      'Der2',
                      'Reder1'
                    ]
        };

    my ($got) = $obj->get_foo();

    is_deeply($got, $expected => 'Chained methods with merged args');

    my $out = Outside->new();
    ($got) = $out->bar($obj);

    is_deeply($got, $expected => 'Chained methods with merged args');
}

exit(0);

# EOF
