#!perl

use 5.036;
use warnings FATAL => q{all};

use Test2::V1 -i;    ## no critic (ProhibitUnusedImports) -i imports every tool, which the policy cannot see
use Test2::Plugin::NoWarnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Module::Runtime qw{require_module};

use Pod::Coverage::More::Analyzer;

my $analyzer = Pod::Coverage::More::Analyzer->new;

# Loads the fixture of a system, or skips the subtest when the system is not installed: each system is optional.
sub analyze_or_skip {
    my ( $system, $fixture ) = @_;
    skip_all("$system is not installed") if !eval { require_module($system); 1 };
    require_module($fixture);
    return $analyzer->analyze_package($fixture);
}

# Short forms of the declared parameters of a record, so a failure shows every difference on one line each.
sub declared_params {
    my ($rec) = @_;
    my @short;
    foreach my $param ( @{ $rec->{declared}{params} } ) {
        my $where = $param->{invocant} ? q{invocant} : defined $param->{named} ? "named $param->{named}" : "#$param->{index}";
        push @short, $where . ( $param->{type} ? q{:} . $param->{type}->display_name : q{} ) . ( $param->{optional} ? q{ optional} : q{} );
    }
    return \@short;
}

sub declared_returns {
    my ($rec) = @_;
    my @names;
    foreach my $type ( @{ $rec->{declared}{returns} } ) {
        push @names, $type->display_name;
    }
    return \@names;
}

# The declared type that each analyzed parameter of a record took, with a dash where it took none.
sub declared_types_of_params {
    my ($rec) = @_;
    my @names;
    foreach my $param ( @{ $rec->{params} } ) {
        push @names, $param->{declared} ? $param->{declared}->display_name : q{-};
    }
    return \@names;
}

subtest Moose => sub {
    my $subs = analyze_or_skip( 'Moose', 'Declared::WithMoose' );
    is( $subs->{name}{declared}{via},           'Moose',                                     "the declarations come from Moose" );
    is( $subs->{name}{declared}{role},          'reader',                                    "a read-only attribute declares a reader" );
    is( declared_returns( $subs->{name} ),      ['Str'],                                     "which returns the type of the attribute" );
    is( $subs->{name}{declared}{documentation}, 'Who it is',                                 "and carries its documentation" );
    is( declared_params( $subs->{items} ),      [ 'invocant', '#1:ArrayRef[Int] optional' ], "a read-write attribute declares an accessor that takes an optional value" );
    is( declared_returns( $subs->{has_items} ), ['Bool'],                                    "a predicate returns a Bool" );
    is( $subs->{clear_items}{declared}{role},   'clearer',                                   "a clearer is declared" );
    is(
        declared_params( $subs->{new} ),
        [ 'invocant', 'named items:ArrayRef[Int] optional', 'named name:Str', 'named friend:Maybe[Declared::WithMoose] optional' ],
        "the constructor takes each attribute, in the order of their names, by its init_arg, and requires the required ones"
    );
    is( declared_returns( $subs->{new} ), ['InstanceOf["Declared::WithMoose"]'], "the constructor returns an instance" );
    ok( $subs->{greet}{declared}{wrapped}, "a method that a modifier wraps is marked wrapped" );
    is( [ map { $_->{name} } @{ $subs->{greet}{params} } ], [ q{$self}, q{$who} ], "and its record describes the original method, not the modifier" );
};

subtest Moo => sub {
    my $subs = analyze_or_skip( 'Moo', 'Declared::WithMoo' );
    is( $subs->{name}{declared}{via},          'Moo',      "a Moo class is read through its Moose metaclass" );
    is( declared_returns( $subs->{name} ),     ['Str'],    "a reader returns the type of the attribute" );
    is( $subs->{size}{declared}{role},         'accessor', "a read-write attribute declares an accessor" );
    is( declared_returns( $subs->{has_size} ), ['Bool'],   "the predicate that predicate => 1 names is declared" );
};

subtest Mouse => sub {
    my $subs = analyze_or_skip( 'Mouse', 'Declared::WithMouse' );
    is( $subs->{name}{declared}{via},          'Mouse',                           "the declarations come from Mouse" );
    is( declared_params( $subs->{name} ),      [ 'invocant', '#1:Str optional' ], "a read-write attribute declares an accessor" );
    is( declared_returns( $subs->{has_name} ), ['Bool'],                          "and its predicate" );
};

subtest 'Class::Tiny' => sub {
    my $subs = analyze_or_skip( 'Class::Tiny', 'Declared::WithTiny' );
    is( $subs->{name}{declared}{role}, 'accessor', "each attribute declares an accessor" );
    is( $subs->{size}{declared}{role}, 'accessor', "so does an attribute with a default" );
    ok( !exists $subs->{new}, "the constructor is inherited from Class::Tiny::Object, so the package has none to declare" );
};

subtest 'Function::Parameters' => sub {
    my $subs = analyze_or_skip( 'Function::Parameters', 'Declared::WithFP' );
    is( declared_params( $subs->{add} ),   [ '#0:Int', '#1:Int optional' ],                         "positional parameters with their types" );
    is( $subs->{add}{declared}{role},      'function',                                              "fun declares a function" );
    is( declared_params( $subs->{greet} ), [ 'invocant', 'named who:Str', 'named times optional' ], "method declares an invocant, and named parameters" );
};

subtest Kavorka => sub {
    my $subs = analyze_or_skip( 'Kavorka', 'Declared::WithKavorka' );
    is( declared_params( $subs->{scale} ), [ '#0:Int', '#1:Num optional' ], "positional parameters with their types" );
};

subtest 'Object::Pad' => sub {
    my $subs = analyze_or_skip( 'Object::Pad', 'Declared::WithPad' );
    is( declared_params( $subs->{hello} ), ['invocant'],                 "a method declares its implicit \$self" );
    is( $subs->{name}{declared}{role},     'reader',                     "a field with :reader declares its reader" );
    is( declared_params( $subs->{new} ),   [ 'invocant', 'named name' ], "a field with :param declares a parameter of the constructor" );
};

subtest 'Type::Params' => sub {
    my $subs = analyze_or_skip( 'Type::Params', 'Declared::WithTypeParams' );
    is( declared_params( $subs->{add} ),  [ '#0:Int', '#1:Int optional' ], "positional parameters with their types" );
    is( declared_returns( $subs->{add} ), ['Int'],                         "and the declared return type" );
    ok( $subs->{add}{declared}{wrapped}, "the wrapper is marked wrapped" );
    is( declared_types_of_params( $subs->{add} ), [qw{Int Int}],                                               "the parameters of the wrapped sub take the declared types by position" );
    is( declared_params( $subs->{greet} ),        [ 'invocant', 'named who:Str', 'named times:Int optional' ], "a method with named parameters" );
};

subtest 'Method::Signatures' => sub {
    my $subs = analyze_or_skip( 'Method::Signatures', 'Declared::WithMS' );
    my @declared;
    foreach my $param ( @{ $subs->{scale}{params} } ) {
        push @declared, "$param->{name}:" . ( $param->{declared} ? $param->{declared}->display_name . " by $param->{declared_by}" : q{-} );
    }
    is( \@declared, [ q{$x:Int by Method::Signatures}, q{$by:Num by Method::Signatures} ], "the type checks that Method::Signatures compiles declare the types" );
};

done_testing;
