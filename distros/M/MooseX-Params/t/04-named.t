use strict;
use warnings;

use Test::Most;

{
    package TestExecute;

    use Moose;
    use MooseX::Params;

    sub name :Args(self: Str :first, Str :last) {
        "$_{first} $_{last}"
    }

    sub title :Args(self: Str name, Str :title) {
        $_{title} ? "$_{title} $_{name}" : $_{name}
    }

    sub nick :Args(self: Str :name, Str :nickname(nick)) {
        "$_{name} is $_{nick}"
    }

    sub initials :Args(self: Str :first, Str :last, Str =:initials) {
        $_{initials}
    }

    sub _build_param_initials
    {
        substr( $_{first}, 0, 1 ) . substr( $_{last}, 0, 1 )
    }
}

my $object = TestExecute->new;

is( $object->name( first => 'Abraham', last => 'Lincoln'), 'Abraham Lincoln', 'named parameters' );
is( $object->title('Abraham Lincoln', title => 'President'), 'President Abraham Lincoln', 'mixed parameters' );
is( $object->nick( name => 'Abraham', nickname => 'Abe'), 'Abraham is Abe', 'init_arg' );
is( $object->initials( first => 'Abraham', last => 'Lincoln'), 'AL', 'lazy' );

done_testing();
