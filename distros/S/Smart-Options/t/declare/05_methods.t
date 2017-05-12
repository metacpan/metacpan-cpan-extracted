use strict;
use warnings;
use Smart::Options::Declare;
use Test::More;
use Test::Exception;

{
    package Foo;
    use Smart::Options::Declare;
    sub new {
        my $class = shift;
        return bless {}, $class;
    }
    sub class_method {
        opts my $class,
             my $ppp => 'Str';
        return "CLASS_METHOD: $class, $ppp";
    }
    sub instance_method {
        opts my $self,
             my $ppp => 'Str';
        return sprintf("INSTANCE_METHOD: %s, $ppp", ref($self));
    }
}

@ARGV = qw(--ppp=YAY);
is( Foo->class_method(), "CLASS_METHOD: Foo, YAY");
@ARGV = qw(--ppp=PEY);
is(Foo->new->instance_method(), "INSTANCE_METHOD: Foo, PEY");
done_testing;
