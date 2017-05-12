use strict;
use warnings;

use Test::More 'tests' => 16;

package Person; {
    use Object::InsideOut;
    my @name :Field :Arg('name');

    my %init_args :InitArgs = (
        'alias' => '',
        'person' => {
            'regex' => qr/^p/i,
            'field' => \@name,
        },
    );
}

package Foo; {
    use Object::InsideOut;
    my @foo :Field;
}

package Bar; {
    use Object::InsideOut;

    sub _init :Init
    {
        my ($self, $args) = @_;
        if (exists($$args{'bar'})) {
            Test::More::ok(1, ':Init with param');
        } elsif (exists($$args{'baz'})) {
            Test::More::ok(1, ':Init with misspelled param');
        } else {
            Test::More::ok(0, 'BUG!!!');
        }
    }
}

package Who; {
    use Object::InsideOut;
    my @name :Field;

    my %init_args :InitArgs = (
        'alias' => '',
    );

    sub _init :Init
    {
        my ($self, $args) = @_;
        if (exists($$args{'alias'})) {
            $self->set(\@name, $$args{'alias'});
        }
    }
}


package main;

MAIN:
{
    eval { my $obj = Person->new(nane => 'Joe'); };
    like($@, qr/Unhandled parameter:/, 'Misspelled param');
    eval { my $obj = Person->new(Person => { nane => 'Joe' }); };
    like($@, qr/Unhandled parameter for class/, 'Misspelled param');

    eval { my $obj = Person->new(alias => 'Joe'); };
    like($@, qr/Unhandled parameter for class/, ':InitArg with no :Init');
    eval { my $obj = Person->new(Person => { alias => 'Joe' }); };
    like($@, qr/Unhandled parameter for class/, ':InitArg with no :Init');
    my $obj = Person->new(parson => 'John');
    ok($obj, 'Regex matches');

    $obj = Foo->new();
    ok($obj, 'No params');
    eval { my $obj = Foo->new('bar' => 'baz'); };
    like($@, qr/Unhandled parameter:/, 'No :InitArg and no :Init');
    eval { my $obj = Foo->new(Foo => { 'bar' => 'baz' }); };
    like($@, qr/Unhandled parameter for class/, 'No :InitArg and no :Init');

    $obj = Bar->new('bar' => 1);
    ok($obj, ':Init with param');
    $obj = Bar->new('baz' => 1);
    ok($obj, ':Init with misspelled param');

    $obj = Who->new('alias' => 'Joe');
    ok($obj, ':Init and :InitArgs');
    $obj = Who->new(Who => {'alias' => 'Joe'});
    ok($obj, ':Init and :InitArgs');

    eval { my $obj = Who->new('aliaX' => 'Joe'); };
    like($@, qr/Unhandled parameter:/, ':InitArg and :Init with typo');
    eval { my $obj = Who->new(Who => {'aliaX' => 'Joe'}); };
    like($@, qr/Unhandled parameter for class/, ':InitArg and :Init with typo');
}

exit(0);

# EOF
