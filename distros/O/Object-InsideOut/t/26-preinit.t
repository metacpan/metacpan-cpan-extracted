use strict;
use warnings;

use Test::More 'tests' => 8;

package Foo; {
    use Object::InsideOut;

    my @data :Field('Acc'=>'data');

    my %init_args :InitArgs = (
        'DATA' => {
            'Field' => \@data,
        },
    );
}

package Bar; {
    use Object::InsideOut qw(Foo);

    sub _preinit :PreInit
    {
        my ($self, $args) = @_;

        if (! exists($args->{'DATA'})) {
            $args->{'DATA'} = 'bar';
        }
    }
}


package Baz; {
    use Object::InsideOut qw(Bar);
}


package main;
MAIN:
{
    my $obj = Bar->new('DATA' => 'main');
    ok($obj                     => 'Object okay');
    is($obj->data(), 'main'     => 'Object data from main');

    $obj = Bar->new();
    ok($obj                     => 'Object okay');
    is($obj->data(), 'bar'      => 'Object data from bar');

    $obj = Baz->new('DATA' => 'main');
    ok($obj                     => 'Object okay');
    is($obj->data(), 'main'     => 'Object data from main');

    $obj = Baz->new();
    ok($obj                     => 'Object okay');
    is($obj->data(), 'bar'      => 'Object data from bar');
}

exit(0);

# EOF
