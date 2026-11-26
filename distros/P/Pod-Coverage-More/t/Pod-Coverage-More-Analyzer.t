#!perl

use 5.036;
use warnings FATAL => q{all};
use re q{/xsaa};

use Test2::V1 -i;    ## no critic (ProhibitUnusedImports) -i imports every tool, which the policy cannot see
use Test2::Plugin::NoWarnings;

use FindBin;
use lib "$FindBin::Bin/lib";

# The fixtures, whose subs the tests analyze.
require Analyzed;
require Signed;

use B ();

use Pod::Coverage::More::Analyzer;

# Short forms of a record, so a failure shows every difference on one line each.
sub params_of {
    my ($rec) = @_;
    return [ map { ( $_->{name} // '?' ) . "#$_->{index}:$_->{source}" . ( $_->{optional} ? ' optional' : '' ) . ( $_->{default} ? " default $_->{default}{mode}" : '' ) . ( $_->{keys} ? " keys @{$_->{keys}}" : '' ) } @{ $rec->{params} } ];
}

sub returns_of {
    my ($rec) = @_;
    return [
        map {
            my $r = $_;
            join ' ', $r->{type},
              map { defined $r->{$_} ? "$_=$r->{$_}" : () } qw{value class class_from name function method coderef context op count}
        } @{ $rec->{returns} }
    ];
}

# The names of the constraints under KEY of each record of ITEMS, with a dash where there is none.
sub constraint_names {
    my ( $items, $key ) = @_;
    my @names;
    foreach my $item (@$items) {
        push @names, $item->{$key} ? $item->{$key}->display_name : q{-};
    }
    return \@names;
}

# Each parameter of a record with its declared constraint and what declared it, or a dash.
sub declared_of {
    my ($rec) = @_;
    my @short;
    foreach my $param ( @{ $rec->{params} } ) {
        push @short, ( $param->{name} // q{?} ) . q{:} . ( $param->{declared} ? $param->{declared}->display_name . " by $param->{declared_by}" : q{-} );
    }
    return \@short;
}

# The constraint of each value that a record returns, marked weak where an operator gave it.
sub returns_with_weakness {
    my ($rec) = @_;
    my @short;
    foreach my $returned ( @{ $rec->{returns} } ) {
        push @short, ( $returned->{constraint} ? $returned->{constraint}->display_name : q{-} ) . ( $returned->{weak} ? q{ weak} : q{} );
    }
    return \@short;
}

subtest backend_for => sub {
    like( dies { Pod::Coverage::More::Analyzer::backend_for(5.034) },    qr/not[ ]supported/, "5.34 is older than the oldest version set" );
    like( dies { Pod::Coverage::More::Analyzer::backend_for(5.035999) }, qr/not[ ]supported/, "the last 5.35 is still older than the oldest version set" );
    is( Pod::Coverage::More::Analyzer::backend_for(5.036),    'Pod::Coverage::More::Analyzer::Perl5_36', "5.36 has its own set" );
    is( Pod::Coverage::More::Analyzer::backend_for(5.036003), 'Pod::Coverage::More::Analyzer::Perl5_36', "5.36 maintenance releases stay in it" );
    is( Pod::Coverage::More::Analyzer::backend_for(5.038),    'Pod::Coverage::More::Analyzer::Perl5_38', "5.38 starts the padsv_store set" );
    is( Pod::Coverage::More::Analyzer::backend_for(5.042004), 'Pod::Coverage::More::Analyzer::Perl5_38', "5.42 is the last of the padsv_store set" );
    is( Pod::Coverage::More::Analyzer::backend_for(5.044),    'Pod::Coverage::More::Analyzer::Perl5_44', "5.44 starts the multiparam set" );
    is( Pod::Coverage::More::Analyzer::backend_for(5.046),    'Pod::Coverage::More::Analyzer::Perl5_44', "later perls fall into the newest set" );
};

subtest new => sub {
    my $analyzer = Pod::Coverage::More::Analyzer->new;
    is( ref($analyzer), Pod::Coverage::More::Analyzer::backend_for($]), "new returns the backend for the running perl $]" );
};

my $analyzer = Pod::Coverage::More::Analyzer->new;

subtest analyze_package => sub {
    my $subs = $analyzer->analyze_package('Analyzed');
    ok( !exists $subs->{croak},    "croak, imported from Carp, is left out" );
    ok( !exists $subs->{blessed},  "blessed, imported from Scalar::Util, is left out" );
    ok( exists $subs->{generated}, "a closure assigned to a glob is included" );
    is( [ grep { $subs->{$_}{name} ne $_ } keys %$subs ], [], "every record carries the name it is filed under" );
};

my $subs = $analyzer->analyze_package('Analyzed');

subtest constants => sub {
    is( $subs->{LIMIT}{kind},            'constant',             "use constant gives a constant" );
    is( returns_of( $subs->{LIMIT} ),    ['number value=5'],     "a numeric constant returns its number" );
    is( returns_of( $subs->{GREETING} ), ['string value=hello'], "a string constant returns its string" );
};

subtest positional_parameters => sub {
    is( params_of( $subs->{shifted} ),                 [ '$self#0:shift', '$name#1:shift' ],                                                          "each shift takes the next index" );
    is( params_of( $subs->{listed} ),                  [ '$self#0:list', '$first#1:list', '@rest#2:list' ],                                           "a list assignment from \@_ ends with its slurpy array" );                          ## no critic (RequireQwForLiteralLists) qw warns about the # in each
    is( params_of( $subs->{listed_undef_last} )->[-1], q{?#2:list},                                                                                   "an undef in a list assignment from \@_ is an unnamed parameter, at its index" );
    is( params_of( $subs->{listed_undef_first} ),      [ q{?#0:list}, q{$value#1:list} ],                                                             "and takes its index from the parameters after it" );
    is( params_of( $subs->{elements} ),                [ '?#0:element', '?#1:element' ],                                                              "\$_[N] used directly gives unnamed parameters" );
    is( params_of( $subs->{defaulted_empty} ),         [q{$x#0:element}],                                                                             "a ternary on \@_ with an empty list is no default" );
    is( params_of( $subs->{defaulted} ),               [ q{$x#0:element}, q{$y#1:element optional default =}, q{$z#2:element optional default //=} ], "\$_[N] with a default is an optional parameter" );
    is( params_of( $subs->{shift_method} ),            ['?#0:shift'],                                                                                 "shift->method gives an unnamed parameter" );
    is( params_of( $subs->{anon_inside} ),             ['$x#0:shift'],                                                                                "the shift inside a nested anonymous sub belongs to that sub" );
    is( params_of( $subs->{generated} ),               ['$q#0:list'],                                                                                 "a closure assigned to a glob has its parameters read" );
    ok( $subs->{generated}{generated}, "a closure assigned to a glob is marked generated" );
    ok( !$subs->{shifted}{generated},  "a named sub is not marked generated" );
    is( params_of( $subs->{evaled} ), [ '$self#0:list', '$value#1:list' ], "a sub built by string eval has its parameters read" );
    ok( $subs->{evaled}{generated}, "a sub built by string eval is marked generated" );
};

subtest named_parameters => sub {
    is( params_of( $subs->{named} ),       [ '$self#0:shift', '%opts#1:list keys verbose size count name' ], "keys read from a hash of named arguments, by exists, in arithmetic and as call arguments" );
    is( params_of( $subs->{hashref_arg} ), [ '$self#0:list',  '$args#1:list keys alpha' ],                   "keys read through a hashref parameter" );
    ok( $subs->{hashref_arg}{usage}{'$args'}{hashref}, "a parameter dereferenced as a hash is used as a hashref" );
};

subtest usage => sub {
    my $usage = $subs->{uses}{usage};
    ok( $usage->{'$num'}{numeric},  "a variable added to is used as a number" );
    ok( $usage->{'$str'}{string},   "a variable concatenated is used as a string" );
    ok( $usage->{'$code'}{coderef}, "a variable called is used as a coderef" );
    is( $usage->{'$obj'}{methods}, ['render'], "a variable that methods are called on records them" );
    ok( !$usage->{'$num'}{string}, "a variable only used as a number is not used as a string" );
};

subtest returns => sub {
    is( returns_of( $subs->{shifted} ),                    ['variable name=$name'], "a returned variable is named" );
    is( returns_of( $subs->{listed} ),                     ['number'],              "scalar(\@array) returns a number" );
    is( returns_of( $subs->{bare_return} ),                ['empty'],               "return with no value" );
    is( returns_of( $subs->{listy} ),                      ['list count=3'],        "a list of three values" );
    is( returns_of( $subs->{branches} ),                   [ 'number value=1',     'string value=no' ],               "one value per return in an if/else" );
    is( returns_of( $subs->{ternary} ),                    [ 'arrayref',           'undef' ],                         "both branches of a ternary, one an empty []" );
    is( returns_of( $subs->{ternary_empty_else} ),         [ 'string',             'empty' ],                         "a ternary whose second branch is an empty list" );
    is( returns_of( $subs->{ternary_empty_then} ),         [ 'empty',              'string' ],                        "a ternary whose first branch is an empty list" );
    is( returns_of( $subs->{ternary_empty_fall_through} ), [ 'empty',              'number value=7' ],                "a ternary with an empty list as the last statement" );
    is( returns_of( $subs->{context_empty_list} ),         [ 'empty context=list', 'number value=0 context=scalar' ], "wantarray with an empty list for list context" );
    is( returns_of( $subs->{empty_hashref} ),              ['hashref'],                       "an empty {} is a hashref" );
    is( returns_of( $subs->{fall_through} ),               [ 'string value=yes', 'hashref' ], "the last statement of each branch when there is no return" );
    ok( ( grep { $_->{implicit} } @{ $subs->{fall_through}{returns} } ) == 2, "values from falling off the end are marked implicit" );
    is( returns_of( $subs->{context} ),     [ 'number value=1 context=list', 'number value=0 context=scalar' ], "wantarray says which value goes with which context" );
    is( returns_of( $subs->{calls} ),       ['call function=Analyzed::listed'],                                 "a returned call names the function" );
    is( returns_of( $subs->{named} ),       [ 'number', 'method method=frob' ],                                 "a returned method call names the method" );
    is( returns_of( $subs->{anon_inside} ), ['call coderef=$f'],                                                "a returned call of a coderef names the variable" );
};

subtest objects => sub {
    is( returns_of( $subs->{fixed_class} ),                               ['object class=Some::Class'],                "bless with a literal class" );
    is( returns_of( $subs->{one_arg_bless} ),                             ['object class=Analyzed'],                   "bless with one argument blesses into the package" );
    is( returns_of( $subs->{constructor} ),                               ['object class=Analyzed class_from=$class'], "bless into ref(\$class) || \$class takes the class from \$class" );
    is( constraint_names( $subs->{constructor}{returns}, 'constraint' ),  ['InstanceOf["Analyzed"]'],                  "which is the invocant, so the object is an instance of the package" );
    is( returns_of( $subs->{chosen_class} ),                              ['object class_from=$kind'],                 "bless into another argument takes the class from it" );
    is( constraint_names( $subs->{chosen_class}{returns}, 'constraint' ), ['Object'],                                  "and the object is of any class" );
};

subtest dies => sub {
    is(
        $subs->{dies}{dies},
        [
            { via => 'die',         line => 127, caught => 0 },
            { via => 'Carp::croak', line => 128, caught => 0 },
            { via => 'die',         line => 129, caught => 1 },
        ],
        "die, an imported croak, and a die inside eval"
    );
    is( $subs->{shifted}{dies}, [], "a sub with no explicit termination" );
    like( $subs->{exits_hard}{dies}, [ { via => q{POSIX::_exit}, caught => 0 } ], "POSIX::_exit terminates" );
    is( $subs->{clucks}{dies}, [], "Carp::cluck only warns, so it is no termination" );
    like( $subs->{throws}{dies},        [ { via => 'throw',     caught => 0 } ], "an exception class's throw terminates" );
    like( $subs->{logs_fatal}{dies},    [ { via => 'log_fatal', caught => 0 } ], "so does log_fatal, as Dist::Zilla's logger dies there" );
    like( $subs->{logs_and_dies}{dies}, [ { via => 'logdie',    caught => 0 } ], "and Log::Log4perl's logdie" );
    is( $subs->{logs_only}{dies}, [], "a log method of another level is no termination" );
};

subtest never_returns => sub {
    ok( $subs->{refuses_too}{never_returns},          "a sub whose every path dies never returns" );
    ok( $subs->{abstract_via_lexical}{never_returns}, "nor does one whose every path calls a lexical sub that never returns" );
    ok( $subs->{abstract_via_package}{never_returns}, "or a sub of its package that never returns" );
    is( $subs->{abstract_via_lexical}{returns}, [], "and the value of that call is no return value" );
    ok( !$subs->{sometimes_refuses}{never_returns}, "but a sub that returns on another path does return" );
    is( $subs->{abstract_via_lexical}{dies}, [], "a call that never returns is no termination of the caller's own" );
};

subtest signatures => sub {
    my $signed = $analyzer->analyze_package('Signed');
    is( params_of( $signed->{plain} ),                  [ '$x#0:signature', '$y#1:signature' ],                       "two mandatory parameters" );
    is( params_of( $signed->{defaults} ),               [ '$x#0:signature', '$y#1:signature optional default =' ],    "a parameter with a default is optional" );
    is( $signed->{defaults}{params}[1]{default}{value}, [ { type => 'number', value => 5 } ],                         "the value of a literal default" );
    is( params_of( $signed->{slurpy_array} ),           [ '$x#0:signature', '@rest#1:signature optional' ],           "a slurpy array" );
    is( params_of( $signed->{slurpy_hash} ),            [ '$x#0:signature', '%opts#1:signature optional keys size' ], "a slurpy hash and the keys read from it" );
    ok( $signed->{slurpy_hash}{params}[1]{slurpy}, "a slurpy hash is marked slurpy" );
    is( params_of( $signed->{placeholder} ),      [ '?#0:signature',  '$y#1:signature' ],         "a placeholder parameter has no name" );
    is( params_of( $signed->{anonymous_slurpy} ), [ '$x#0:signature', '?#1:signature optional' ], "a slurpy parameter with no name has none" );
    ok( $signed->{anonymous_slurpy}{params}[1]{slurpy}, "and is marked slurpy" );
    is( [ map { [ @{$_}{qw{name index optional}} ] } @{ $signed->{defaulted_placeholder}{params} } ], [ [ '$x', 0, 0 ], [ undef, 1, 1 ] ], "a placeholder with a default has no name either, and is optional" );
    is( params_of( $signed->{empty} ),                                                                [],                                  "an empty signature has no parameters" );
};

subtest signature_defaults_5_38 => sub {
    skip_all("perl $] cannot compile the //= and ||= defaults that 5.38 added") if $] < 5.038;
    require Signed538;
    my $signed = $analyzer->analyze_package('Signed538');
    is(
        params_of( $signed->{defaults} ),
        [
            '$x#0:signature',
            '$z#1:signature optional default //=',
            '$w#2:signature optional default ||=',
        ],
        "a default for an undef argument and a default for a false argument"
    );
    is( $signed->{defaults}{params}[1]{default}{value}, [ { type => 'string', value => 'z' } ], "the value of a //= default" );
    is( $signed->{defaults}{params}[2]{default}{value}, [ { type => 'arrayref' } ],             "the value of a ||= default" );
};

subtest constraints => sub {
    my @params = @{ $subs->{uses}{params} };
    my %inferred;
    @inferred{ map { $_->{name} } @params } = @{ constraint_names( \@params, q{inferred} ) };
    is( \%inferred,                                                   { q{$num} => q{Num}, q{$str} => q{Str}, q{$code} => q{CodeRef}, q{$obj} => q{HasMethods["render"]} }, "each parameter has the constraint that its uses amount to" );
    is( $subs->{hashref_arg}{params}[1]{inferred}->display_name,      q{HashRef},                                                                                           "a parameter dereferenced as a hash is a HashRef" );
    is( constraint_names( $subs->{ternary}{returns}, q{constraint} ), [qw{ArrayRef Undef}],                                                                                 "each value a sub returns has its constraint" );
    is( $subs->{fixed_class}{returns}[0]{constraint}->display_name,   q{InstanceOf["Some::Class"]},                                                                         "an object of a literal class is an instance of it" );
    is( $subs->{LIMIT}{returns}[0]{constraint}->display_name,         q{Int},                                                                                               "so does the value of a constant" );
    ok( !defined $subs->{shifted}{returns}[0]{constraint}, "a returned variable has no constraint by itself" );
};

subtest declared_by_the_code => sub {
    require Guarded;
    my $guarded = $analyzer->analyze_package(q{Guarded});
    is( declared_of( $guarded->{guarded} ),           [ q{$count:Int by Type::Tiny}, q{$opts:HashRef by Type::Tiny}, q{$list:ArrayRef by Type::Tiny}, q{$thing:InstanceOf["Foo"] by Type::Tiny} ], "a guard of a Type::Library declares the type of the variable it checks" );
    is( declared_of( $guarded->{compiled} ),          [ q{$x:Int by Type::Params}, q{$y:Optional[Str] by Type::Params} ], "a checker that compile() returned declares its types by position" );
    is( declared_of( $guarded->{validated} ),         [ q{$x:Int by Type::Params}, q{$y:Str by Type::Params} ],           "so does validate()" );
    is( params_of( $guarded->{via_plain_checker} ),   [ q{$x#0:checked},           q{%rest#1:checked} ],                  "a call that receives \@_ names the parameters it returns, even with no types" );
    is( declared_of( $guarded->{via_plain_checker} ), [ q{$x:-},                   q{%rest:-} ],                          "and declares no types that the op tree does not show" );
};

subtest numbers => sub {
    require Big;
    my $big = $analyzer->analyze_package(q{Big});
    is( returns_with_weakness( $big->{literal} ), [q{InstanceOf["Math::BigInt"]}],      "a literal under use bigint is a Math::BigInt, for certain" );
    is( returns_with_weakness( $big->{sum} ),     [q{InstanceOf["Math::BigInt"] weak}], "arithmetic under use bigint gives a Math::BigInt, as far as an operator says" );
    is( returns_with_weakness( $big->{sized} ),   [q{Maybe[Int] weak}],                 "length outside the scope of bigint is a whole number or undef, as far as an operator says" );
    is( returns_with_weakness( $big->{PAIR} ),    [q{ArrayRef}],                        "a constant that holds an array reference is an ArrayRef" );
    is( returns_with_weakness( $subs->{listed} ), [q{Int}],                             "the count of an array is an Int, which no overloading changes" );
};

subtest reads_args_and_signature => sub {
    is( $subs->{shifted}{reads_args},     1, "a sub that shifts \@_ reads it" );
    is( $subs->{elements}{reads_args},    1, "so does one that reads \$_[N]" );
    is( $subs->{calls}{reads_args},       1, "and one that passes \@_ on" );
    is( $subs->{bare_return}{reads_args}, 0, "a sub that never touches \@_ does not" );
    my $signed = $analyzer->analyze_package(q{Signed});
    is( $signed->{empty}{signature}, 1, "an empty signature is a signature" );
    is( $subs->{shifted}{signature}, 0, "and a sub without one has none" );
};

subtest generated => sub {
    require Installed;
    my $installed = $analyzer->analyze_package(q{Installed});
    ok( $installed->{helper}{generated}, "a sub that another file compiled and installed under the name of the package is generated" );
    ok( !$installed->{own}{generated},   "a sub that the package compiled itself is not" );
};

subtest core_class => sub {
    skip_all("perl $] has no class feature") if $] < 5.038;
    require CoreClass;
    my $class = $analyzer->analyze_package(q{CoreClass});
    is( params_of( $class->{add} ),  [ q{$self#0:invocant}, q{$item#1:signature}, q{$qty#2:signature optional default =} ], "the implicit \$self of a method with a signature is parameter 0" );
    is( params_of( $class->{name} ), [q{$self#0:invocant}],                                                                 "a method without a signature still takes \$self" );
    ok( $class->{add}{method},  "a method of the class feature is marked a method" );
    ok( !$class->{new}{method}, "its constructor is not" );
};

subtest without_multideref => sub {

    # Last, because loading autovivification stops perl compiling multideref for code compiled after it.
    require Unfolded;
    is( [ grep { $_ eq q{multideref} } map { op_names($_) } \&Unfolded::named, \&Unfolded::hashref_arg ], [], "the fixture has the folded op nowhere, so these assertions read the unfolded ops" );

    my $unfolded = $analyzer->analyze_package(q{Unfolded});
    is( params_of( $unfolded->{named} ),       [ q{$self#0:list}, q{%opts#1:list keys gone verbose size} ], "keys read by delete, exists and a plain hash element" );
    is( params_of( $unfolded->{hashref_arg} ), [ q{$self#0:list}, q{$args#1:list keys alpha} ],             "a key read through a hashref" );
    ok( $unfolded->{hashref_arg}{usage}{q{$args}}{hashref}, "a parameter dereferenced as a hash is used as a hashref" );
};

# The names of every op of a sub, so a test can make sure that a fixture compiled to the ops it means to test.
sub op_names {
    my ($code) = @_;
    my @names;
    my @todo = ( B::svref_2object($code)->ROOT );
    while ( my $op = shift @todo ) {
        next if !$$op;
        push @names, $op->name;
        push @todo,  $analyzer->op_kids($op);
    }
    return @names;
}

done_testing;
