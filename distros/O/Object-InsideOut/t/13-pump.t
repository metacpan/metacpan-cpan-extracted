use strict;
use warnings;

use Test::More 'tests' => 19;

package MyBase; {
    use Object::InsideOut;

    my %public  :Field;
    my %private :Field;

    my %init_args :InitArgs = (
        'pub' => {
            'field' => \%public,
        },
        'priv' => {
            'field' => \%private,
            'def'   => 'base priv',
        },
    );

    # No :Init sub needed
}

package MyDer; {
    use Object::InsideOut qw(MyBase);

    my @public  :Field;
    my @private :Field;
    my @misc    :Field('Name' => 'misc');

    my %init_args :InitArgs = (
        'pub' => {
            'field' => \@public,
        },
        'priv' => {
            'field' => \@private,
            'def'   => 'der priv',
        },
        'misc'   => '',
        'hidden' => '',
    );

    sub _init :Init
    {
        my ($self, $args) = @_;

        if (exists($args->{'misc'})) {
            $self->set(\@misc, $args->{'misc'});
        }
    }
}


package MyDas; {
    use Object::InsideOut qw(MyDer);

    sub _dump :Dump
    {
        my $self = shift;
        return ({ 'key' => 'value' });
    }

    sub _pump :Pump
    {
        my ($self, $data) = @_;

        Test::More::is($data->{'key'}, 'value' => 'Pumper got data');
    }

}

package main;

MAIN:
{
    my $obj = MyDas->new({
                  MyBase   => { pub => 'base pub' },
                  MyDer    => { pub => 'der pub'  },
                  'misc'   => 'other',
                  'hidden' => 'invisible',
              });

    my $dump = $obj->dump();

    ok($dump                                  => 'Representation is valid');
    is(ref($dump), 'ARRAY'                    => 'Representation is valid');
    my ($class, $hash) = @{$dump};

    is($class, 'MyDas'                        => 'Class');

    is($hash->{MyBase}{'pub'}, 'base pub'     => 'Public base attribute');
    is($hash->{MyBase}{'priv'}, 'base priv'   => 'Private base attribute');

    is($hash->{MyDer}{'pub'}, 'der pub'       => 'Public derived attribute');
    is($hash->{MyDer}{'priv'}, 'der priv'     => 'Private derived attribute');
    is($hash->{MyDer}{'misc'}, 'other'        => 'Hidden derived attribute');

    is($hash->{MyDas}{'key'}, 'value'         => 'Dumper gave value');

    my $str = $obj->dump(1);
    #print(STDERR $str, "\n");

    my $dump2 = eval $str;

    ok($str && ! ref($str)                    => 'String dump');
    ok($dump2                                 => 'eval is valid');
    is(ref($dump2), 'ARRAY'                   => 'eval is valid');
    is_deeply($dump, $dump2                   => 'Dumps are equal');

    my $obj2;
    eval { $obj2 = Object::InsideOut::pump($dump); };
    ok(! $@,                                  => 'Pump in hash');
    $dump2 = $obj2->dump();
    is_deeply($dump, $dump2                   => 'Redump equals dump');

    my $obj3;
    eval { $obj3 = Object::InsideOut::pump($str); };
    ok(! $@,                                  => 'Pump in string');
    $dump2 = $obj3->dump();
    is_deeply($dump, $dump2                   => 'Redump equals dump');
}

exit(0);

# EOF
