## Test case donated by Stevan Little

use strict;
use warnings;

use Test::More tests => 25;
use Data::Dumper;

{
    package Interpreter;
    use Moose;
    use MooseX::Types::Structured qw(Dict Tuple);
    use MooseX::Types::Moose qw(
        Int
        Str
        ScalarRef
    );
    use MooseX::Types -declare => [qw(
        Var
        Const
        Pair
        Op
        BinOp
        Lambda
        App
        Expr
    )];

    use Data::Dumper 'Dumper';

    subtype Var()   => as ScalarRef;
    subtype Const() => as Int | Str;
    subtype Pair()  => as Tuple[ Expr, Expr ];

    enum Op() => [ qw[ + - ] ];

    subtype BinOp()  => as Tuple[ Expr, Op, Expr ];
    subtype Lambda() => as Tuple[ Var, Expr ];
    subtype App()    => as Tuple[ Lambda, Expr ];
    subtype Expr()   => as Var | Const | Pair | BinOp | Lambda | App;

    sub match {
        my ($to_match, @cases) = @_;
        my $default;
        if (@cases % 2 != 0) {
            $default = pop @cases;
        }
        while (@cases) {
            my ($type, $action) = splice @cases, 0, 2;
            #warn "Got " . Dumper($to_match) . " in " . $type->name;
            if ($type->check($to_match)) {
                local $_ = $to_match;
                return $action->($to_match);
            }
        }
        {
            local $_ = $to_match;
            return $default->($to_match) if $default;
        }
    }

    sub run {
        my ($source, $e) = @_;
        $e ||= {};
        #use Data::Dumper; warn "run(e) => " . Dumper $e;
        return match $source,
              Var() => sub { $e->{ ${$_} } },
            Const() => sub { $_[0] },
            BinOp() => sub { $_->[1] eq '+'
                                ? ( run( $_->[0], $e ) + run( $_->[2], $e ) )
                                : ( run( $_->[0], $e ) - run( $_->[2], $e ) ) },
           Lambda() => sub { $_ },
              App() => sub {
                             my ( $p, $body ) = @{ run( $_[0]->[0], $e ) };
                             $e->{ ${ $p } }  = run( $_[0]->[1], $e );
                             run( $body, $e );
                           },
             Pair() => sub { $_ },
             Expr() => sub { run($_, $e) },
                       sub { confess "[run] Bad Source:" . Dumper $_ };
    }

    sub pprint {
        my ($source) = @_;
        return match $source,
               Var() => sub { 'Var(' . ${$_} . ')'                                        },
                Op() => sub { 'Op(' . $_ . ')'                                            },
             Const() => sub { 'Const(' . $_ . ')'                                         },
             BinOp() => sub { 'BinOp( ' . ( join ' ' => map { pprint($_) } @{$_} ) . ' )' },
            Lambda() => sub { "Lambda( " . pprint($_->[0]) . ' ' . pprint($_->[1]) . " )" },
               App() => sub { "App( " . pprint($_->[0]) . ' ' . pprint($_->[1]) . " )"    },
              Pair() => sub { 'Pair(' . pprint($_->[0]) . ' => ' . pprint($_->[1]) . ')'  },
              Expr() => sub { pprint($_)                                                  },
                        sub { confess "[pprint] Bad Source:" . Dumper $_                  };
    }
}

{
    BEGIN { Interpreter->import(':all') };

    ok is_Var(\'x'), q{passes is_Var('x')};

    ok is_Const(1), q{passes is_Const(1)};
    ok is_Const('Hello World'), q{passes is_Const};

    ok is_Pair([ 'Hello', 'World' ]), q{passes is_Pair};
    ok is_Pair([ \'Hello', 'World' ]), q{passes is_Pair};
    ok is_Pair([ \'Hello', 100 ]), q{passes is_Pair};
    ok is_Pair([ \'Hello', [ 1, '+', 1] ]), q{passes is_Pair};

    ok is_Op('+'), q{passes is_Op('+')};
    ok is_Op('-'), q{passes is_Op('-')};

    ok is_BinOp([ 1, '+', 1]), q{passes is_BinOp([ 1, '+', 1])};
    ok is_BinOp([ '+', '+', '+' ]), q{passes is_BinOp([ '+', '+', '+' ])};
    ok is_BinOp([ 1, '+', [ 1, '+', 1 ]]), q{passes is_BinOp([ 1, '+', 1])};

    ok is_Lambda([ \'x', [ \'x', '+', \'x' ]]), q{passes is_Lambda};
    ok is_App([ [ \'x', [ \'x', '+', \'x' ]], 10 ]), q{passes is_App};

    ok Expr->check([ 11, '+', 12]), '... check is supported';
    ok is_Expr(\'x'), q{passes is_Expr(\'x')};
    ok is_Expr(10), q{passes is_Expr(10)};
    ok is_Expr([ 1, '+', 1]), q{passes is_Expr([ 1, '+', 1])};
    ok is_Expr([ 1, '+', [ 1, '+', 1 ]]), q{passes is_Expr([ 1, '+', [ 1, '+', 1 ]])};

    my $source = [ [ \'x', [ \'x', '+', \'x' ]], 10 ];

    is Interpreter::pprint($source),
    'App( Lambda( Var(x) BinOp( Var(x) Op(+) Var(x) ) ) Const(10) )',
    '... pretty printed correctly';

    is Interpreter::run([ 1, '+', 1 ]), 2, '... eval-ed correctly';

    is Interpreter::run([ 1, '+', [ 1, '+', 1 ] ]), 3, '... eval-ed correctly';

    is_deeply Interpreter::run([ \'x', [ \'x', '+', \'x' ]]),
    [ \'x', [ \'x', '+', \'x' ]],
    '... eval-ed correctly';

    is Interpreter::run($source), 20, '... eval-ed correctly';

    is Interpreter::run(
        [
            [ \'x', [ \'x', '+', \'x' ] ],
            [ 2, '+', 2 ]
        ]
    ), 8, '... eval-ed correctly';

}


