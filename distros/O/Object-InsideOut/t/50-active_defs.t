use Test::More tests => 58;
{
    package Iterator;
    use Object::InsideOut;

    my @next : Field Arg(start);

    sub next {
        my ($self) = @_;
        my $next = $next[$$self];
        $next[$$self]++;
        $next[$$self] = substr($next[$$self],-1) . substr($next[$$self],0,-1);
        return $next;
    }
}

{
    package Foo;
    use Object::InsideOut;

    sub triple { shift(@_) x 3 }

    my @ID     : Field Get(ID)     SequenceFrom(1);
    my @rating : Field Get(Rating) SeqFrom('XXX');
    my @ccv    : Field Get(CCV)    SeqFrom(Iterator->new(start=>triple('A')));

    my @seven  : Field Get(Seven)  Default(7);
    my @ID2    : Field Get(ID2)    Default($self->ID() + 1);
}

# Test sequential defaults...
is(Foo->new->ID, 1 => 'First ID in sequence');
is(Foo->new->ID, 2 => 'Second ID in sequence');
is(Foo->new->ID, 3 => 'Third ID in sequence');

is(Foo->new->Rating, 'XYA' => 'Fourth rating in sequence');
is(Foo->new->Rating, 'XYB' => 'Fifth rating in sequence');
is(Foo->new->Rating, 'XYC' => 'Sixth rating in sequence');

is(Foo->new->CCV, 'CCC' => 'Seventh CCV in sequence');
is(Foo->new->CCV, 'DCC' => 'Eighth CCV in sequence');
is(Foo->new->CCV, 'DDC' => 'Ninth CCV in sequence');

# Test constant default...
is(Foo->new->Seven, 7 => "Seven is 7");
is(Foo->new->Seven, 7 => "Seven still 7");
is(Foo->new->Seven, 7 => "Seven always 7");

# Test args to :Default...
my $obj = Foo->new;
is $obj->ID2 - 1, $obj->ID  => 'Default via $self';


package Bar; {
    use Object::InsideOut;

    my @h1 :Field :Get(H1) :Default({});
    my @h2 :Field :Get(H2) :Arg(Hash2) :Default({});
    my @h3 :Field :Get(H3) :Arg(Name => 'Hash3', Default => {});
    my @h4 :Field :Get(H4);

    my @r1 :Field :Get(R1) :Default(rand);
    my @r2 :Field :Get(R2) :Arg(Rand2) :Default(rand);
    my @r3 :Field :Get(R3) :Arg(Name => 'Rand3', Default => sub {rand});
    my @r4 :Field :Get(R4);

    my @m1 :Field :Get(M1) :Default($self->biz);
    my @m2 :Field :Get(M2) :Arg(Meth2) :Default($self->biz);
    my @m3 :Field :Get(M3) :Arg(Name => 'Meth3', Default => sub {shift->biz});
    my @m4 :Field :Get(M4);

    my @c1 :Field :Get(C1) :Default(bork);
    my @c2 :Field :Get(C2) :Arg(Code2) :Default(bork);
    my @c3 :Field :Get(C3) :Arg(Name => 'Code3', Default => \&bork);
    my @c4 :Field :Get(C4);

    my @f1 :Field :Get(F1) :Default(our $next; ++$next);
    my @f2 :Field :Get(F2) :Arg(Func2) :Default(our $nn; ++$nn, $nn*$nn);
    my @f3 :Field :Get(F3) :Arg(Name => 'Func3', Default => sub {our $foo; --$foo});
    my @f4 :Field :Get(F4);

    sub biz :Private
    {
        return ref(shift);
    }

    sub bork :Restricted
    {
        __PACKAGE__
    }

    my %init_args :InitArgs = (
        'Hash4' => {
            'Field' => \@h4,
            'Default' => {},
        },
        'Rand4' => {
            'Field' => \@r4,
            'Default' => sub {rand},
        },
        'Meth4' => {
            'Field' => \@m4,
            'Default' => sub {shift->biz},
        },
        'Code4' => {
            'Field' => \@c4,
            'Default' => \&bork,
        },
        'Func4' => {
            'Field' => \@f4,
            'Default' => sub {our $bar; chr(++$bar + 64)},
        },
    );

}

package main;

my $o1 = Bar->new('Hash3' => {'argx' => '-'},
                  'Rand2' => 'nill',
                  'Meth2' => 'foo',
                  'Func2' => 99,
                 );
my $o2 = Bar->new('Hash4' => [1,2,3],
                  'Rand3' => 1.0,
                  'Meth3' => Foo->new(),
                  'Func3' => 98,
                 );
my $o3 = Bar->new('Hash2' => 'bork',
                  'Rand4' => time,
                  'Meth4' => $],
                  'Func4' => 97,
                 );

$o1->H1->{'foo'} = 12;
$o2->H1->{'foo'} = 'bar';
is($o1->H1->{'foo'}, 12 => 'Separate hashes');
ok(!exists $o3->H1->{'foo'} => 'Separate hashes');

$o2->H2->{'foo'} = 'bip';
$o1->H2->{'foo'} = 44;
is($o2->H2->{'foo'}, 'bip' => 'Separate hashes');
is($o3->H2, 'bork' => 'Default override');

$o2->H3->{'bar'} = 'zero';
$o3->H3->{'bar'} = 44;
is($o2->H3->{'bar'}, 'zero' => 'Separate hashes');
is($o1->H3->{'argx'}, '-' => 'Default override');

$o1->H4->{'biff'} = {'foo'=>'true'};
$o3->H4->{'biff'} = 'xyz';
is($o1->H4->{'biff'}->{'foo'}, 'true' => 'Separate hashes');
is($o2->H4->[2], 3 => 'Default override');

my $r1 = $o1->R1;
my $r2 = $o2->R1;
ok(0 <= $r1 && $r1 < 1 => 'R1 for o1 is random');
ok(0 <= $r2 && $r2 < 1 => 'R1 for o2 is random');
isnt($r1, $r2 => 'Rands are different');

$r1 = $o1->R2;
$r2 = $o2->R2;
$r3 = $o3->R2;
is($r1, 'nill' => 'Default override');
ok(0 <= $r2 && $r2 < 1 => 'R2 for o2 is random');
ok(0 <= $r3 && $r3 < 1 => 'R2 for o3 is random');
isnt($r2, $r3 => 'Rands are different');

$r1 = $o1->R3;
$r2 = $o2->R3;
$r3 = $o3->R3;
ok(0 <= $r1 && $r1 < 1 => 'R3 for o1 is random');
is($r2, 1.0 => 'Default override');
ok(0 <= $r3 && $r3 < 1 => 'R3 for o3 is random');
isnt($r1, $r3 => 'Rands are different');

$r1 = $o1->R4;
$r2 = $o2->R4;
$r3 = $o3->R4;
ok(0 <= $r1 && $r1 < 1 => 'R4 for o1 is random');
ok(0 <= $r2 && $r2 < 1 => 'R4 for o2 is random');
ok($r3 > 1329336828 => 'Default override');
isnt($r1, $r2 => 'Rands are different');

is($o1->M1, 'Bar' => 'Private method access');
is($o1->M2, 'foo' => 'Default override');
is($o1->M3, 'Bar' => 'Private method access');
is($o1->M4, 'Bar' => 'Private method access');

is($o2->M3->ID2 - 1, $o2->M3->ID => 'Default override');
is($o3->M4, $] => 'Default override');

is($o1->C1, 'Bar' => 'Class method access');
is($o1->C2, 'Bar' => 'Class method access');
is($o1->C3, 'Bar' => 'Class method access');
is($o1->C4, 'Bar' => 'Class method access');

is($o1->F1, 1 => 'Default code');
is($o2->F1, 2 => 'Default code');
is($o3->F1, 3 => 'Default code');

is($o1->F2, 99 => 'Default override');
is($o2->F2, 1 => 'Default code');
is($o3->F2, 4 => 'Default code');

is($o1->F3, -1 => 'Default code');
is($o2->F3, 98 => 'Default override');
is($o3->F3, -2 => 'Default code');

is($o1->F4, 'A' => 'Default code');
is($o2->F4, 'B' => 'Default code');
is($o3->F4, 97 => 'Default override');

# EOF
