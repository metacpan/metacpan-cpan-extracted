use strict;
use warnings;

use Test::More 'tests' => 37;

package My::Class; {
    use Object::InsideOut;

    sub jinx : Cumulative(bottom up);

    sub auto : Automethod
    {
        my $name = $_;
        return sub {
                        my $self = $_[0];
                        my $class = ref($self) || $self;
                        return "$class->$name";
                   };
    };

    sub jinx
    {
        return 'My::Class->jinx';
    }
}

package My::Sub; {
    use Object::InsideOut qw(My::Class);

    sub jinx : Cumulative(bottom up)
    {
        return 'My::Sub->jinx';
    }

    sub foo
    {
        return 'My::Sub->foo';
    }
}

package My::Bar; {
    use Object::InsideOut qw(My::Class);

    sub auto : Automethod
    {
        if (/^foo$/) {
            return sub { return 'BOOM' }
        }
        return;
    }
}

package My::Baz; {
    use Object::InsideOut qw(My::Bar);
}

package My::MT; {
    sub new { return bless({}, __PACKAGE__); }
}


package Foo; {
    use Object::InsideOut;

    sub auto : Automethod
    {
        my $name = $_;
        return sub {
                        my $self = $_[0];
                        my $class = ref($self) || $self;
                        return __PACKAGE__ . ": $class->$name";
                   };
    };
}

package Bar; {
    use Object::InsideOut qw(Foo);
}

package Baz; {
    use Object::InsideOut qw(Bar);

    sub auto : Automethod
    {
        my $name = $_;

        if ($name eq 'bing') {
            my $self = shift;
            return ($self->can('SUPER::bing'));
        }

        return sub {
                        my $self = $_[0];
                        my $class = ref($self) || $self;
                        return __PACKAGE__ . ": $class->$name";
                   };
    }
}


package NFG; {
    use Object::InsideOut;

    sub _automethod :Automethod {
      my ($self, $val) = @_;
      my $set=exists $_[1];
      my $name=$_;
    }
}


package main;

MAIN:
{
    my (@j, @result, $method);

    $method = My::Class->can('foo');
    ok($method                                 => 'My::Class->foo()');
    is(My::Class->foo(),     'My::Class->foo'  => 'Direct My::Class->foo()');
    is(My::Class->$method(), 'My::Class->foo'  => 'Indirect My::Class->foo()');

    $method = My::Sub->can('foo');
    ok($method                             => 'My::Sub->foo()');
    is(My::Sub->foo(),     'My::Sub->foo'  => 'Direct My::Sub->foo()');
    is(My::Sub->$method(), 'My::Sub->foo'  => 'Indirect My::Sub->foo()');

    $method = My::Sub->can('bar');
    ok($method                             => 'My::Sub->bar()');
    is(My::Sub->bar(),     'My::Sub->bar'  => 'Direct My::Sub->bar()');
    is(My::Sub->$method(), 'My::Sub->bar'  => 'Indirect My::Sub->bar()');

    $method = My::Bar->can('foo');
    ok($method                     => 'My::Bar can foo()');
    is(My::Bar->foo(),     'BOOM'      => 'Direct My::Bar->foo()');
    is(My::Bar->$method(), 'BOOM'      => 'Indirect My::Bar->foo()');

    $method = My::Bar->can('bar');
    ok($method                     => 'My::Bar can bar()');
    is(My::Bar->bar(),     'My::Bar->bar'  => 'Direct My::Bar->bar()');
    is(My::Bar->$method(), 'My::Bar->bar'  => 'Indirect My::Bar->bar()');

    $method = My::Baz->can('foo');
    ok($method                     => 'My::Baz can foo()');
    is(My::Baz->foo(),     'BOOM'      => 'Direct My::Baz->foo()');
    is(My::Baz->$method(), 'BOOM'      => 'Indirect My::Baz->foo()');

    $method = My::Baz->can('bar');
    ok($method                     => 'My::Baz can bar()');
    is(My::Baz->bar(),     'My::Baz->bar'  => 'Direct My::Baz->bar()');
    is(My::Baz->$method(), 'My::Baz->bar'  => 'Indirect My::Baz->bar()');

    $method = My::MT->can('foo');
    ok(!$method              => 'My::MT no can foo()');
    eval { My::MT->foo() };
    ok($@                    => 'No My::MT foo()');

    my $x = My::Class->new();
    @j = $x->jinx();
    @result = qw(My::Class->jinx);
    is_deeply(\@j, \@result, 'Class cumulative');

    my $z = My::Sub->new();
    @j = $z->jinx();
    @result = qw(My::Sub->jinx My::Class->jinx);
    is_deeply(\@j, \@result, 'Subclass cumulative');

    is($x->dummy(), 'My::Class->dummy', 'Class automethod');
    is($z->zebra(), 'My::Sub->zebra', 'Sublass automethod');

    my $y = $x->can('turtle');
    is($x->$y, 'My::Class->turtle', 'Class can+automethod');

    $y = $z->can('snort');
    is($z->$y, 'My::Sub->snort', 'Sublass can+automethod');

    my $obj = My::Bar->new();
    @j = $obj->jinx();
    @result = qw(My::Class->jinx);
    is_deeply(\@j, \@result, 'Inherited cumulative');

    $obj = My::Bar->new();
    is($obj->foom(), 'My::Bar->foom', 'Object automethod');

    $obj = My::Baz->new();
    is($obj->foom(), 'My::Baz->foom', 'Object automethod');

    is(Foo->Baz::SUPER::foo(), 'Foo: Foo->foo'  => 'class::SUPER::method');
    is(Bar->Baz::SUPER::foo(), 'Foo: Bar->foo'  => 'class::SUPER::method');
    is(Baz->bing(),            'Foo: Baz->bing' => 'SUPER::method');
    is(Bar->Baz::foo(),        'Baz: Bar->foo'  => 'class::method');

    $obj = NFG->new();
    eval { $obj->nfg(); };
    like($@->error, qr/did not return a code ref/, 'Defective :Automethod');
}

exit(0);

# EOF
