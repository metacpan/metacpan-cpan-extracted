use Test2::V0;
use Smart::Args::TypeTiny;

{
    package Foo;
    use Smart::Args::TypeTiny;

    sub new { bless {}, shift }

    sub class_method {
        args my $class => 'ClassName',
             my $x     => 'Int',
             my $y     => 'Str',
             my $z     => { isa => 'Int', default => 10 },
             ;
    }

    sub instance_method {
        args my $self,
             my $x => 'Int',
             my $y => 'Str',
             my $z => { isa => 'HashRef', optional => 1 },
             ;
    }
}

sub foo {
    args_pos my $x => 'Int',
             my $y => 'Str',
             ;
}

is +Foo->class_method(x => 1, y => 'one'), {x => 1, y => 'one', z => 10};
is +Foo->new->instance_method(x => 1, y => 'one'), {x => 1, y => 'one', z => undef};
is foo(1, 'one'), {x => 1, y => 'one'};

done_testing;
