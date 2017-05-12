use strict;
use warnings;

use Test::More 'tests' => 15;

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

    my %public  :Field;
    my %private :Field;
    my %misc    :Field
                :Name( 'misc' );
    my %hidden  :Field;

    my %init_args :InitArgs = (
        'pub' => {
            'field' => \%public,
        },
        'priv' => {
            'field' => \%private,
            'def'   => 'der priv',
        },
        'misc'   => '',
        'hidden' => '',
    );

    sub _init :Init
    {
        my ($self, $args) = @_;

        if (exists($args->{'misc'})) {
            $self->set(\%misc, $args->{'misc'});
        }
        if (exists($args->{'hidden'})) {
            $self->set(\%hidden, $args->{'hidden'});
        }
    }
}

package MyClass;
{
    use Object::InsideOut;

    my @content :Field :Acc(content);
}

package main;

MAIN:
{
    my $obj = MyDer->new({
                  MyBase   => { pub => 'base pub' },
                  MyDer    => { pub => 'der pub'  },
                  'misc'   => 'other',
                  'hidden' => 'invisible',
              });

    my $dump = $obj->dump();

    ok($dump                                  => 'Representation is valid');
    is(ref($dump), 'ARRAY'                    => 'Representation is valid');
    my ($class, $hash) = @{$dump};

    is($class, 'MyDer'                        => 'Class');

    is($hash->{MyBase}{'pub'}, 'base pub'     => 'Public base attribute');
    is($hash->{MyBase}{'priv'}, 'base priv'   => 'Private base attribute');

    is($hash->{MyDer}{'pub'}, 'der pub'       => 'Public derived attribute');
    is($hash->{MyDer}{'priv'}, 'der priv'     => 'Private derived attribute');
    is($hash->{MyDer}{'misc'}, 'other'        => 'Hidden derived attribute');
    is(Object::InsideOut::Util::hash_re($hash->{MyDer}, qr/^HASH/), 'invisible'
                                              => 'Hidden derived attribute');

    my $str = $obj->Object::InsideOut::dump(1);
    #print(STDERR $str, "\n");

    my $dump2 = eval $str;

    ok($str && ! ref($str)                    => 'String dump');
    ok($dump2                                 => 'eval is valid');
    is(ref($dump2), 'ARRAY'                   => 'eval is valid');
    is_deeply($dump, $dump2                   => 'Dumps are equal');

    eval { my $obj2 = Object::InsideOut::pump($dump); };
    is($@->error(), q/Unnamed field encounted in class 'MyDer'/
                                              => 'Unnamed field');

    my $content = <<CONTENT;
A;B;C
1;2;3
4;5;6
7;8;9
10;11;12
CONTENT

    my $result = <<RESULT;
[
  'MyClass',
  {
    'MyClass' => {
      'content' => 'A;B;C
1;2;3
4;5;6
7;8;9
10;11;12
'
    }
  }
]
RESULT

    $obj = MyClass->new();
    $obj->content($content);
    is($obj->dump(1)."\n", $result, 'Dump string contents verified');
}

exit(0);

# EOF
