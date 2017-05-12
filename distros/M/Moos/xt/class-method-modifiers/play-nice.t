use Test::More;
BEGIN {
    eval q{ require Class::Method::Modifiers; Class::Method::Modifiers->VERSION("1.00"); 1 }
        or plan skip_all => "need Class::Method::Modifiers";
    plan tests => 3;
};

{
    package Local::Class;
    use Moos;
    has number => ();
}

{
    package Local::Class2;
    use Moos;
    use Class::Method::Modifiers;
    extends qw( Local::Class );
    around number => sub {
        my $orig = shift;
        my $self = shift;
        @_ ? $self->$orig(@_) : (2 * $self->$orig);
    };
}

my $obj = Local::Class2->new(number => 42);
is($obj->{number}, 42);
is($obj->number, 84);
$obj->number(12);
is($obj->number, 24);

