use Sub::Quote;
use Sub::QuoteX::Utils qw[ quote_subs ];

my $sub;

# class with method
{
    package Yipee;
    use Moo;
    sub halloo { shift; print "Yipee, @_\n" }
}

# and the object
my $object = Yipee->new;

# quoted sub
my $foo = quote_sub(
  q[ print "$foo: @_\n"],
  { '$foo' => \"Foo" }
);


# bare sub
sub bar { print "Bar: @_\n" }


# create single subroutine. each invoked piece of code will have a
# localized view of @_
$sub = quote_subs(
    \&bar,                             # bare sub
    $foo,                              # quoted sub
    [ q[ print "$goo: @_\n"],          # code in string with capture
      capture => { '$goo' => \"Goo" },
    ],
    [ $object, 'halloo' ],             # method call
);


# and run it
$sub->( "Common" );

# Bar: Common
# Goo: Common
# Foo: Common
# Yipee: Common


# now, give each a personalized @_
$sub            = quote_subs(
    [ \&bar,                           # bare sub
      args      => [qw( Bar )]
    ],
    [ $foo,                            # quoted sub
      args      => [qw( Foo )]
    ],
    [ q[ print "$goo, @_\n"],          # code in string with capture
      capture => { '$goo' => \"Goo" },
      args    => [qw( Goo )],
    ],
    [ $object, 'halloo',               # method call
        args    => [qw( Yipee )]
    ],
);

$sub->( "Common" );

# Bar: Bar
# Foo: Foo
# Goo: Goo
# Yipee: Yipee

# now, explicitly empty @_
$sub = quote_subs(
    [ \&bar,                           # bare sub
      args => undef
    ],
    [ $foo,                            # quoted sub
      args => undef
    ],
    [ q[ print "$goo, @_\n"],          # code in string with capture
      capture => { '$goo' => \"Goo" },
      args    => undef,
    ],
    [ $object, 'halloo',               #method call
      args => undef
    ],
);

$sub->( "Common" );

# Bar:
# Foo:
# Goo:
# Yipee:
