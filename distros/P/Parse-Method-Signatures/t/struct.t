use strict;
use warnings;

use Test::More tests => 43;
use Test::Differences;
use Test::Moose;
use MooseX::Types::Structured qw/Dict/;

use Parse::Method::Signatures;

use aliased 'Parse::Method::Signatures::Param';

BEGIN {
    eval "use aliased 'Parse::Method::Signatures::Param::${_}'"
        for qw/Named Positional Bindable Placeholder/;

    eval "use aliased 'Parse::Method::Signatures::Param::Unpacked::${_}' => 'Unpacked${_}'"
        for qw/Array Hash/;
}

{
    my $sig = Parse::Method::Signatures->signature('(Str $name)');

    ok(!$sig->has_named_params);
    ok($sig->has_positional_params);
    is(scalar @{ $sig->positional_params }, 1);

    my ($param) = $sig->positional_params;
    isa_ok($param, Param);
    ok($param->has_type_constraints);
    #is($param->type_constraints->data, 'Str');
    is($param->variable_name, '$name');
    ok($param->required);
    ok(!$param->has_constraints);

    does_ok($param, $_) for Positional, Bindable;

    my $tc = $param->meta_type_constraint;
    isa_ok($tc, 'Moose::Meta::TypeConstraint');
    is($tc->name, 'Str');
}
{
    my $sig = Parse::Method::Signatures->signature('(Str :$who, Int :$age where { $_ > 0 })');

    ok(!$sig->has_positional_params);
    ok($sig->has_named_params);
    is(scalar @{ $sig->named_params }, 2);

    my @params = $sig->named_params;
    isa_ok($_, Param) for @params;
    for my $param (@params) {
        does_ok($param, $_) for Named, Bindable;
    }

    my ($who, $age) = @params;
    #is($who->type_constraints->data, 'Str');
    is($who->variable_name, '$who');
    ok(!$who->required);
    ok(!$who->has_constraints);
    my $tc = $who->meta_type_constraint;
    isa_ok($tc, 'Moose::Meta::TypeConstraint');
    is($tc->name, 'Str');

    #is($age->type_constraints->data, 'Int');
    is($age->variable_name, '$age');
    ok(!$age->required);
    ok($age->has_constraints);
    is_deeply([$age->constraints], ['{ $_ > 0 }']);
    $tc = $age->meta_type_constraint;
    isa_ok($tc, 'Moose::Meta::TypeConstraint');
    is($tc->name, 'Int');
}

{
    my $sig = Parse::Method::Signatures->signature('($, $foo, $)');

    ok($sig->has_positional_params);
    ok(!$sig->has_named_params);
    is(scalar @{ $sig->positional_params }, 3);

    does_ok($sig->positional_params->[0], Placeholder);
    does_ok($sig->positional_params->[2], Placeholder);
}

{
    my $type = 'HashRef[ArrayRef[Moo]|Str]|Num';
    my $param = Parse::Method::Signatures->param("${type} \$foo");

    my $tc = $param->meta_type_constraint;
    isa_ok($tc, 'Moose::Meta::TypeConstraint');
    is($tc->name, $type);
}

{
    my $param = Parse::Method::Signatures->param(
        input => 'Dict[foo => Int] $foo',
        type_constraint_callback => sub {
            my ($tc, $name) = @_;
            return Dict if $name eq 'Dict';
            return $tc->find_registered_constraint($name);
        },
    );
    my $tc = $param->meta_type_constraint;
    is($tc->name, 'MooseX::Types::Structured::Dict[foo,Int]');
    ok($tc->check({foo => 2}), "TC behaves right");
    ok(!$tc->check({foo => "str"}), "TC behaves right");
    ok(!$tc->check({Foo => "str"}), "TC behaves right");
}

=for later

eq_or_diff( 
  scalar Parse::Method::Signatures->signature('(Str $name, Bool :$excited = 0)'),
  { params => [
      { tc => 'Str',
        var => '$name',
      },
      { tc => 'Bool',
        var => '$excited',
        named => 1,
        default => '0'
      },
    ]
  },
);

eq_or_diff(
  scalar Parse::Method::Signatures->signature('(Animal|Human $affe)'),
  { params => [
      { tc => 'Animal|Human',
        var => '$affe'
      },
    ]
  },
);

eq_or_diff(
  scalar Parse::Method::Signatures->signature('(:$a, :$b, :$c)'),
  { params => [
      { var => '$a',
        named => 1
      },
      { var => '$b',
        named => 1
      },
      { var => '$c',
        named => 1
      },
    ]
  },
);

eq_or_diff( 
  scalar Parse::Method::Signatures->signature('( $a,  $b, :$c)'),
  { params => [
      { var => '$a' },
      { var => '$b' },
      { var => '$c',
        named => 1
      },
    ]
  },
);

eq_or_diff( 
  scalar Parse::Method::Signatures->signature('($a , $b!, :$c!, :$d!)'),
  { params => [
      { var => '$a' },
      { var => '$b',
        required => 1
      },
      { var => '$c',
        named => 1,
        required => 1
      },
      { var => '$d',
        named => 1,
        required => 1
      },
    ]
  },
);

eq_or_diff( 
  scalar Parse::Method::Signatures->signature('($a?, $b?, :$c , :$d?)'),
  { params => [
      { var => '$a',
        optional => 1
      },
      { var => '$b',
        optional => 1
      },
      { var => '$c',
        named => 1,
      },
      { var => '$d',
        named => 1,
        optional => 1
      },
    ]
  },
);

eq_or_diff(
  scalar Parse::Method::Signatures->signature('($self:  $moo)'),
  { params => [
      { var => '$moo' }
    ],
    invocant => {
      var => '$self'
    }
  },
);

# TODO: Should this have a empty invocant struct?
eq_or_diff(
  scalar Parse::Method::Signatures->signature('(:     $affe ) # called as $obj->foo(affe => $value)'),
  { params => [
      { var => '$affe',
        named => 1
      }
    ]
  }, 
);

eq_or_diff(
  scalar Parse::Method::Signatures->signature('(:apan($affe)) # called as $obj->foo(apan => $value)'),
  { params => [
      { label => 'apan',
        var => '$affe',
        named => 1
      }
    ]
  },
);

eq_or_diff(
  scalar Parse::Method::Signatures->signature(q#(SomeClass $thing where { $_->can('stuff') }:
Str  $bar  = "apan"
Int :$baz! = 42 where { $_ % 2 == 0 } where { $_ > 10 })#),
  { params => [
      { tc => 'Str',
        var => '$bar',
        default => '"apan"'
      },
      { tc => 'Int',
        var => '$baz',
        named => 1,
        required => 1,
        where => [
          '{ $_ % 2 == 0 }',
          '{ $_ > 10 }'
        ],
        default => '42'
      }
    ],
    invocant => {
      tc => 'SomeClass',
      var => '$thing',
      where => [
        '{ $_->can(\'stuff\') }'
      ]
    }
  },
);


eq_or_diff(
  [ Parse::Method::Signatures->signature('(Str $name)') ],
  [ { params => [
      { tc => 'Str',
        var => '$name',
      }
    ]
  }, ''],
);

eq_or_diff(
  [ Parse::Method::Signatures->signature('(Str $name) further data }') ],
  [ { params => [
      { tc => 'Str',
        var => '$name',
      }
    ]
  }, 'further data }'],
);


eq_or_diff(
  [ Parse::Method::Signatures->param(
      input => 'previous data(Str $name) further data }',
      offset => 14) ],
  [ { tc => 'Str',
      var => '$name',
    },
    ') further data }'],
);
eq_or_diff(
  [ Parse::Method::Signatures->param(
      input => 'Str $name) further data }',
    ) ],
  [ { tc => 'Str',
      var => '$name',
    },
    ') further data }'],
);

eq_or_diff(
  [ Parse::Method::Signatures->signature( "(\$param1 # Foo bar\n \$param2) postfix") ],
  [ { params => [
      { var => '$param1' },
      { var => '$param2' },
    ] },
    'postfix'
  ]
);
