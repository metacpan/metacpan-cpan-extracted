use strict;
use warnings;

use Test::More 'tests' => 11;

# The::Borg is a class we want to delegate to...
package The::Borg; {
    use Object::InsideOut;

    sub assimilate {
        return "You will be assimilated";
    }

    sub admonish {
        return "Resistance is futile";
    }

    sub advise {
        return "We will add your biological and cultural distinctiveness to our own";
    }

    sub answer {
        return "No";
    }
}

# Federation is another class we want to delegate to...
package Federation; {
    use Object::InsideOut;

    sub assimilate {
        return "Welcome to the Federation";
    }

    sub admonish {
        return "Respect the Prime Directive";
    }

    sub advise {
        my ($self, $who) = @_;
        return "We come in peace, $who (shoot to kill!)";
    }

    sub answer {
        return "Ye kenna change the laws o' physics";
    }

    sub assist {
        return "The Prime Directive forbids us to intervene";
    }
}

package Foo; {
    use Object::InsideOut;

    sub foo {
        return 'bar';
    }
}

package Delegator; {
    use Object::InsideOut;

    my @borg :Field(Std=>'borg', Handles=>'engulf-->assimilate')
             :Type(The::Borg);
    my @fed  :Field('Std'=>'fed', 'Handles'=>'admonish advise', Type=>'Federation');
    my @foo  :Field('Std'=>'foo')
             :Handle('baz' --> 'foo')
             :Handle('bar' --> 'foo');

    sub init : Init {
        my ($self, $args) = @_;

        $self->set_borg(The::Borg->new());
        $self->set_fed(Federation->new());
        $self->set_foo(Foo->new());
    }

    sub answer : Method {
        return "Aye, captain";
    }
}


package DelegatorClassy; {
    use Object::InsideOut;

    my @borg :Field(Std=>'borg', Handles=>'The::Borg')
             :Type(The::Borg);

    my @fed  :Std(fed) :Handles(Federation::) :Type(Federation);

    sub init : Init {
        my ($self, $args) = @_;

        $self->set_borg(The::Borg->new());
        $self->set_fed(Federation->new());
    }

    sub answer : Method {
        return "Aye, captain";
    }
}

package main;
MAIN:
{
    my $obj = Delegator->new();

    is($obj->engulf,        The::Borg->assimilate,     'engulf delegated to Borg->assimilate');
    is($obj->admonish,      Federation->admonish,      'admonish delegated to Federation');
    is($obj->advise('sir'), Federation->advise('sir'), 'advise delegated to Federation');
    is($obj->answer,        Delegator->answer,         'answer did not delegate');
    is($obj->baz,           Foo->foo,                  'first :Handle works');
    is($obj->bar,           Foo->foo,                  'second :Handle works');
}

{
    my $obj = DelegatorClassy->new();

    is($obj->assimilate,    The::Borg->assimilate,     'assimilate delegated to Borg');
    is($obj->admonish,      The::Borg->admonish,       'admonish delegated to Borg');
    is($obj->advise('sir'), The::Borg->advise('sir'),  'advise delegated to Borg');
    is($obj->assist(),      Federation->assist(),      'assist delegated to Federation');
    is($obj->answer,        DelegatorClassy->answer,   'answer did not delegate');
}

exit(0);

# EOF
