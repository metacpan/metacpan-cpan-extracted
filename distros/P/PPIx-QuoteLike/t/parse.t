package main;

use 5.006;

use strict;
use warnings;

use PPIx::QuoteLike;
use Test::More 0.88;	# Because of done_testing();

my $obj;

$obj = PPIx::QuoteLike->new( q{''} );
if ( ok $obj, q<Able to parse ''> ) {
    cmp_ok $obj->failures(), '==', 0, q<Failures parsing ''>;
    cmp_ok $obj->interpolates(), '==', 0, q<Does '' interpolate>;
    is $obj->content(), q{''}, q<Can recover ''>;
    is $obj->__get_value( 'type' ), q{}, q<Type of ''>;
    is $obj->delimiters(), q{''}, q<Delimiters of ''>;
    is $obj->__get_value( 'start' ), q{'}, q<Start delimiter of ''>;
    is $obj->__get_value( 'finish' ), q{'}, q<Finish delimiter of ''>;
    is $obj->encoding(), undef, q<'' encoding>;
    is_deeply [ sort $obj->variables() ],
	[ qw{  } ],
	q<'' interpolated variables>;
    cmp_ok $obj->postderef(), '==', 1, q<'' postderef>;
    cmp_ok scalar $obj->elements(), '==', 3,
	q<Number of elements of ''>;
    cmp_ok scalar $obj->children(), '==', 0,
	q<Number of children of ''>;
}

$obj = PPIx::QuoteLike->new( q{"foo\"bar"} );
if ( ok $obj, q<Able to parse "foo\"bar"> ) {
    cmp_ok $obj->failures(), '==', 0, q<Failures parsing "foo\"bar">;
    cmp_ok $obj->interpolates(), '==', 1, q<Does "foo\"bar" interpolate>;
    is $obj->content(), q{"foo\"bar"}, q<Can recover "foo\"bar">;
    is $obj->__get_value( 'type' ), q{}, q<Type of "foo\"bar">;
    is $obj->delimiters(), q{""}, q<Delimiters of "foo\"bar">;
    is $obj->__get_value( 'start' ), q{"}, q<Start delimiter of "foo\"bar">;
    is $obj->__get_value( 'finish' ), q{"}, q<Finish delimiter of "foo\"bar">;
    is $obj->encoding(), undef, q<"foo\"bar" encoding>;
    is_deeply [ sort $obj->variables() ],
	[ qw{  } ],
	q<"foo\"bar" interpolated variables>;
    cmp_ok $obj->postderef(), '==', 1, q<"foo\"bar" postderef>;
    cmp_ok scalar $obj->elements(), '==', 4,
	q<Number of elements of "foo\"bar">;
    cmp_ok scalar $obj->children(), '==', 1,
	q<Number of children of "foo\"bar">;
    if ( my $kid = $obj->child( 0 ) ) {
	ok $kid->isa( 'PPIx::QuoteLike::Token::String' ),
	    q<"foo\"bar" child 0 class>;
	is $kid->content(), q{foo\"bar},
	    q<"foo\"bar" child 0 content>;
	is $kid->error(), undef,
	    q<"foo\"bar" child 0 error>;
	cmp_ok $kid->parent(), '==', $obj,
	    q<"foo\"bar" child 0 parent>;
	cmp_ok $kid->previous_sibling() || 0, '==', $obj->__kid( 0 - 1 ),
	    q<"foo\"bar" child 0 previous sibling>;
	cmp_ok $kid->next_sibling() || 0, '==', $obj->__kid( 0 + 1 ),
	    q<"foo\"bar" child 0 next sibling>;
    }
}

$obj = PPIx::QuoteLike->new( q/q{\Qx}/ );
if ( ok $obj, q<Able to parse q{\Qx}> ) {
    cmp_ok $obj->failures(), '==', 0, q<Failures parsing q{\Qx}>;
    cmp_ok $obj->interpolates(), '==', 0, q<Does q{\Qx} interpolate>;
    is $obj->content(), q/q{\Qx}/, q<Can recover q{\Qx}>;
    is $obj->__get_value( 'type' ), q{q}, q<Type of q{\Qx}>;
    is $obj->delimiters(), q/{}/, q<Delimiters of q{\Qx}>;
    is $obj->__get_value( 'start' ), q/{/, q<Start delimiter of q{\Qx}>;
    is $obj->__get_value( 'finish' ), q/}/, q<Finish delimiter of q{\Qx}>;
    is $obj->encoding(), undef, q<q{\Qx} encoding>;
    is_deeply [ sort $obj->variables() ],
	[ qw{  } ],
	q<q{\Qx} interpolated variables>;
    cmp_ok $obj->postderef(), '==', 1, q<q{\Qx} postderef>;
    cmp_ok scalar $obj->elements(), '==', 4,
	q<Number of elements of q{\Qx}>;
    cmp_ok scalar $obj->children(), '==', 1,
	q<Number of children of q{\Qx}>;
    if ( my $kid = $obj->child( 0 ) ) {
	ok $kid->isa( 'PPIx::QuoteLike::Token::String' ),
	    q<q{\Qx} child 0 class>;
	is $kid->content(), q{\Qx},
	    q<q{\Qx} child 0 content>;
	is $kid->error(), undef,
	    q<q{\Qx} child 0 error>;
	cmp_ok $kid->parent(), '==', $obj,
	    q<q{\Qx} child 0 parent>;
	cmp_ok $kid->previous_sibling() || 0, '==', $obj->__kid( 0 - 1 ),
	    q<q{\Qx} child 0 previous sibling>;
	cmp_ok $kid->next_sibling() || 0, '==', $obj->__kid( 0 + 1 ),
	    q<q{\Qx} child 0 next sibling>;
    }
}

$obj = PPIx::QuoteLike->new( q/qq {\Qx}/ );
if ( ok $obj, q<Able to parse qq {\Qx}> ) {
    cmp_ok $obj->failures(), '==', 0, q<Failures parsing qq {\Qx}>;
    cmp_ok $obj->interpolates(), '==', 1, q<Does qq {\Qx} interpolate>;
    is $obj->content(), q/qq {\Qx}/, q<Can recover qq {\Qx}>;
    is $obj->__get_value( 'type' ), q{qq}, q<Type of qq {\Qx}>;
    is $obj->delimiters(), q/{}/, q<Delimiters of qq {\Qx}>;
    is $obj->__get_value( 'start' ), q/{/, q<Start delimiter of qq {\Qx}>;
    is $obj->__get_value( 'finish' ), q/}/, q<Finish delimiter of qq {\Qx}>;
    is $obj->encoding(), undef, q<qq {\Qx} encoding>;
    is_deeply [ sort $obj->variables() ],
	[ qw{  } ],
	q<qq {\Qx} interpolated variables>;
    cmp_ok $obj->postderef(), '==', 1, q<qq {\Qx} postderef>;
    cmp_ok scalar $obj->elements(), '==', 6,
	q<Number of elements of qq {\Qx}>;
    cmp_ok scalar $obj->children(), '==', 2,
	q<Number of children of qq {\Qx}>;
    if ( my $kid = $obj->child( 0 ) ) {
	ok $kid->isa( 'PPIx::QuoteLike::Token::Control' ),
	    q<qq {\Qx} child 0 class>;
	is $kid->content(), q{\Q},
	    q<qq {\Qx} child 0 content>;
	is $kid->error(), undef,
	    q<qq {\Qx} child 0 error>;
	cmp_ok $kid->parent(), '==', $obj,
	    q<qq {\Qx} child 0 parent>;
	cmp_ok $kid->previous_sibling() || 0, '==', $obj->__kid( 0 - 1 ),
	    q<qq {\Qx} child 0 previous sibling>;
	cmp_ok $kid->next_sibling() || 0, '==', $obj->__kid( 0 + 1 ),
	    q<qq {\Qx} child 0 next sibling>;
    }
    if ( my $kid = $obj->child( 1 ) ) {
	ok $kid->isa( 'PPIx::QuoteLike::Token::String' ),
	    q<qq {\Qx} child 1 class>;
	is $kid->content(), q{x},
	    q<qq {\Qx} child 1 content>;
	is $kid->error(), undef,
	    q<qq {\Qx} child 1 error>;
	cmp_ok $kid->parent(), '==', $obj,
	    q<qq {\Qx} child 1 parent>;
	cmp_ok $kid->previous_sibling() || 0, '==', $obj->__kid( 1 - 1 ),
	    q<qq {\Qx} child 1 previous sibling>;
	cmp_ok $kid->next_sibling() || 0, '==', $obj->__kid( 1 + 1 ),
	    q<qq {\Qx} child 1 next sibling>;
    }
}

$obj = PPIx::QuoteLike->new( q{qx '$foo'} );
if ( ok $obj, q<Able to parse qx '$foo'> ) {
    cmp_ok $obj->failures(), '==', 0, q<Failures parsing qx '$foo'>;
    cmp_ok $obj->interpolates(), '==', 0, q<Does qx '$foo' interpolate>;
    is $obj->content(), q{qx '$foo'}, q<Can recover qx '$foo'>;
    is $obj->__get_value( 'type' ), q{qx}, q<Type of qx '$foo'>;
    is $obj->delimiters(), q{''}, q<Delimiters of qx '$foo'>;
    is $obj->__get_value( 'start' ), q{'}, q<Start delimiter of qx '$foo'>;
    is $obj->__get_value( 'finish' ), q{'}, q<Finish delimiter of qx '$foo'>;
    is $obj->encoding(), undef, q<qx '$foo' encoding>;
    is_deeply [ sort $obj->variables() ],
	[ qw{  } ],
	q<qx '$foo' interpolated variables>;
    cmp_ok $obj->postderef(), '==', 1, q<qx '$foo' postderef>;
    cmp_ok scalar $obj->elements(), '==', 5,
	q<Number of elements of qx '$foo'>;
    cmp_ok scalar $obj->children(), '==', 1,
	q<Number of children of qx '$foo'>;
    if ( my $kid = $obj->child( 0 ) ) {
	ok $kid->isa( 'PPIx::QuoteLike::Token::String' ),
	    q<qx '$foo' child 0 class>;
	is $kid->content(), q{$foo},
	    q<qx '$foo' child 0 content>;
	is $kid->error(), undef,
	    q<qx '$foo' child 0 error>;
	cmp_ok $kid->parent(), '==', $obj,
	    q<qx '$foo' child 0 parent>;
	cmp_ok $kid->previous_sibling() || 0, '==', $obj->__kid( 0 - 1 ),
	    q<qx '$foo' child 0 previous sibling>;
	cmp_ok $kid->next_sibling() || 0, '==', $obj->__kid( 0 + 1 ),
	    q<qx '$foo' child 0 next sibling>;
    }
}

$obj = PPIx::QuoteLike->new( q{"$foo"} );
if ( ok $obj, q<Able to parse "$foo"> ) {
    cmp_ok $obj->failures(), '==', 0, q<Failures parsing "$foo">;
    cmp_ok $obj->interpolates(), '==', 1, q<Does "$foo" interpolate>;
    is $obj->content(), q{"$foo"}, q<Can recover "$foo">;
    is $obj->__get_value( 'type' ), q{}, q<Type of "$foo">;
    is $obj->delimiters(), q{""}, q<Delimiters of "$foo">;
    is $obj->__get_value( 'start' ), q{"}, q<Start delimiter of "$foo">;
    is $obj->__get_value( 'finish' ), q{"}, q<Finish delimiter of "$foo">;
    is $obj->encoding(), undef, q<"$foo" encoding>;
    is_deeply [ sort $obj->variables() ],
	[ qw{ $foo } ],
	q<"$foo" interpolated variables>;
    cmp_ok $obj->postderef(), '==', 1, q<"$foo" postderef>;
    cmp_ok scalar $obj->elements(), '==', 4,
	q<Number of elements of "$foo">;
    cmp_ok scalar $obj->children(), '==', 1,
	q<Number of children of "$foo">;
    if ( my $kid = $obj->child( 0 ) ) {
	ok $kid->isa( 'PPIx::QuoteLike::Token::Interpolation' ),
	    q<"$foo" child 0 class>;
	is $kid->content(), q{$foo},
	    q<"$foo" child 0 content>;
	is $kid->error(), undef,
	    q<"$foo" child 0 error>;
	cmp_ok $kid->parent(), '==', $obj,
	    q<"$foo" child 0 parent>;
	cmp_ok $kid->previous_sibling() || 0, '==', $obj->__kid( 0 - 1 ),
	    q<"$foo" child 0 previous sibling>;
	cmp_ok $kid->next_sibling() || 0, '==', $obj->__kid( 0 + 1 ),
	    q<"$foo" child 0 next sibling>;
	is_deeply [ sort $kid->variables() ],
	    [ qw{ $foo } ],
	    q<"$foo" child 0 interpolated variables>;
    }
}

$obj = PPIx::QuoteLike->new( q{"$$foo"} );
if ( ok $obj, q<Able to parse "$$foo"> ) {
    cmp_ok $obj->failures(), '==', 0, q<Failures parsing "$$foo">;
    cmp_ok $obj->interpolates(), '==', 1, q<Does "$$foo" interpolate>;
    is $obj->content(), q{"$$foo"}, q<Can recover "$$foo">;
    is $obj->__get_value( 'type' ), q{}, q<Type of "$$foo">;
    is $obj->delimiters(), q{""}, q<Delimiters of "$$foo">;
    is $obj->__get_value( 'start' ), q{"}, q<Start delimiter of "$$foo">;
    is $obj->__get_value( 'finish' ), q{"}, q<Finish delimiter of "$$foo">;
    is $obj->encoding(), undef, q<"$$foo" encoding>;
    is_deeply [ sort $obj->variables() ],
	[ qw{ $foo } ],
	q<"$$foo" interpolated variables>;
    cmp_ok $obj->postderef(), '==', 1, q<"$$foo" postderef>;
    cmp_ok scalar $obj->elements(), '==', 4,
	q<Number of elements of "$$foo">;
    cmp_ok scalar $obj->children(), '==', 1,
	q<Number of children of "$$foo">;
    if ( my $kid = $obj->child( 0 ) ) {
	ok $kid->isa( 'PPIx::QuoteLike::Token::Interpolation' ),
	    q<"$$foo" child 0 class>;
	is $kid->content(), q{$$foo},
	    q<"$$foo" child 0 content>;
	is $kid->error(), undef,
	    q<"$$foo" child 0 error>;
	cmp_ok $kid->parent(), '==', $obj,
	    q<"$$foo" child 0 parent>;
	cmp_ok $kid->previous_sibling() || 0, '==', $obj->__kid( 0 - 1 ),
	    q<"$$foo" child 0 previous sibling>;
	cmp_ok $kid->next_sibling() || 0, '==', $obj->__kid( 0 + 1 ),
	    q<"$$foo" child 0 next sibling>;
	is_deeply [ sort $kid->variables() ],
	    [ qw{ $foo } ],
	    q<"$$foo" child 0 interpolated variables>;
    }
}

$obj = PPIx::QuoteLike->new( q/qx{${foo}bar}/ );
if ( ok $obj, q<Able to parse qx{${foo}bar}> ) {
    cmp_ok $obj->failures(), '==', 0, q<Failures parsing qx{${foo}bar}>;
    cmp_ok $obj->interpolates(), '==', 1, q<Does qx{${foo}bar} interpolate>;
    is $obj->content(), q/qx{${foo}bar}/, q<Can recover qx{${foo}bar}>;
    is $obj->__get_value( 'type' ), q{qx}, q<Type of qx{${foo}bar}>;
    is $obj->delimiters(), q/{}/, q<Delimiters of qx{${foo}bar}>;
    is $obj->__get_value( 'start' ), q/{/, q<Start delimiter of qx{${foo}bar}>;
    is $obj->__get_value( 'finish' ), q/}/, q<Finish delimiter of qx{${foo}bar}>;
    is $obj->encoding(), undef, q<qx{${foo}bar} encoding>;
    is_deeply [ sort $obj->variables() ],
	[ qw{ $foo } ],
	q<qx{${foo}bar} interpolated variables>;
    cmp_ok $obj->postderef(), '==', 1, q<qx{${foo}bar} postderef>;
    cmp_ok scalar $obj->elements(), '==', 5,
	q<Number of elements of qx{${foo}bar}>;
    cmp_ok scalar $obj->children(), '==', 2,
	q<Number of children of qx{${foo}bar}>;
    if ( my $kid = $obj->child( 0 ) ) {
	ok $kid->isa( 'PPIx::QuoteLike::Token::Interpolation' ),
	    q<qx{${foo}bar} child 0 class>;
	is $kid->content(), q/${foo}/,
	    q<qx{${foo}bar} child 0 content>;
	is $kid->error(), undef,
	    q<qx{${foo}bar} child 0 error>;
	cmp_ok $kid->parent(), '==', $obj,
	    q<qx{${foo}bar} child 0 parent>;
	cmp_ok $kid->previous_sibling() || 0, '==', $obj->__kid( 0 - 1 ),
	    q<qx{${foo}bar} child 0 previous sibling>;
	cmp_ok $kid->next_sibling() || 0, '==', $obj->__kid( 0 + 1 ),
	    q<qx{${foo}bar} child 0 next sibling>;
	is_deeply [ sort $kid->variables() ],
	    [ qw{ $foo } ],
	    q<qx{${foo}bar} child 0 interpolated variables>;
    }
    if ( my $kid = $obj->child( 1 ) ) {
	ok $kid->isa( 'PPIx::QuoteLike::Token::String' ),
	    q<qx{${foo}bar} child 1 class>;
	is $kid->content(), q{bar},
	    q<qx{${foo}bar} child 1 content>;
	is $kid->error(), undef,
	    q<qx{${foo}bar} child 1 error>;
	cmp_ok $kid->parent(), '==', $obj,
	    q<qx{${foo}bar} child 1 parent>;
	cmp_ok $kid->previous_sibling() || 0, '==', $obj->__kid( 1 - 1 ),
	    q<qx{${foo}bar} child 1 previous sibling>;
	cmp_ok $kid->next_sibling() || 0, '==', $obj->__kid( 1 + 1 ),
	    q<qx{${foo}bar} child 1 next sibling>;
    }
}

$obj = PPIx::QuoteLike->new( q{<$foo>} );
if ( ok $obj, q<Able to parse <$foo>> ) {
    cmp_ok $obj->failures(), '==', 0, q<Failures parsing <$foo>>;
    cmp_ok $obj->interpolates(), '==', 1, q<Does <$foo> interpolate>;
    is $obj->content(), q{<$foo>}, q<Can recover <$foo>>;
    is $obj->__get_value( 'type' ), q{}, q<Type of <$foo>>;
    is $obj->delimiters(), q{<>}, q<Delimiters of <$foo>>;
    is $obj->__get_value( 'start' ), q{<}, q<Start delimiter of <$foo>>;
    is $obj->__get_value( 'finish' ), q{>}, q<Finish delimiter of <$foo>>;
    is $obj->encoding(), undef, q<<$foo> encoding>;
    is_deeply [ sort $obj->variables() ],
	[ qw{ $foo } ],
	q<<$foo> interpolated variables>;
    cmp_ok $obj->postderef(), '==', 1, q<<$foo> postderef>;
    cmp_ok scalar $obj->elements(), '==', 4,
	q<Number of elements of <$foo>>;
    cmp_ok scalar $obj->children(), '==', 1,
	q<Number of children of <$foo>>;
    if ( my $kid = $obj->child( 0 ) ) {
	ok $kid->isa( 'PPIx::QuoteLike::Token::Interpolation' ),
	    q<<$foo> child 0 class>;
	is $kid->content(), q{$foo},
	    q<<$foo> child 0 content>;
	is $kid->error(), undef,
	    q<<$foo> child 0 error>;
	cmp_ok $kid->parent(), '==', $obj,
	    q<<$foo> child 0 parent>;
	cmp_ok $kid->previous_sibling() || 0, '==', $obj->__kid( 0 - 1 ),
	    q<<$foo> child 0 previous sibling>;
	cmp_ok $kid->next_sibling() || 0, '==', $obj->__kid( 0 + 1 ),
	    q<<$foo> child 0 next sibling>;
	is_deeply [ sort $kid->variables() ],
	    [ qw{ $foo } ],
	    q<<$foo> child 0 interpolated variables>;
    }
}

$obj = PPIx::QuoteLike->new( q/"foo@{[ qq<$bar$baz> ]}buzz"/ );
if ( ok $obj, q<Able to parse "foo@{[ qq<$bar$baz> ]}buzz"> ) {
    cmp_ok $obj->failures(), '==', 0, q<Failures parsing "foo@{[ qq<$bar$baz> ]}buzz">;
    cmp_ok $obj->interpolates(), '==', 1, q<Does "foo@{[ qq<$bar$baz> ]}buzz" interpolate>;
    is $obj->content(), q/"foo@{[ qq<$bar$baz> ]}buzz"/, q<Can recover "foo@{[ qq<$bar$baz> ]}buzz">;
    is $obj->__get_value( 'type' ), q{}, q<Type of "foo@{[ qq<$bar$baz> ]}buzz">;
    is $obj->delimiters(), q{""}, q<Delimiters of "foo@{[ qq<$bar$baz> ]}buzz">;
    is $obj->__get_value( 'start' ), q{"}, q<Start delimiter of "foo@{[ qq<$bar$baz> ]}buzz">;
    is $obj->__get_value( 'finish' ), q{"}, q<Finish delimiter of "foo@{[ qq<$bar$baz> ]}buzz">;
    is $obj->encoding(), undef, q<"foo@{[ qq<$bar$baz> ]}buzz" encoding>;
    is_deeply [ sort $obj->variables() ],
	[ qw{ $bar $baz } ],
	q<"foo@{[ qq<$bar$baz> ]}buzz" interpolated variables>;
    cmp_ok $obj->postderef(), '==', 1, q<"foo@{[ qq<$bar$baz> ]}buzz" postderef>;
    cmp_ok scalar $obj->elements(), '==', 6,
	q<Number of elements of "foo@{[ qq<$bar$baz> ]}buzz">;
    cmp_ok scalar $obj->children(), '==', 3,
	q<Number of children of "foo@{[ qq<$bar$baz> ]}buzz">;
    if ( my $kid = $obj->child( 0 ) ) {
	ok $kid->isa( 'PPIx::QuoteLike::Token::String' ),
	    q<"foo@{[ qq<$bar$baz> ]}buzz" child 0 class>;
	is $kid->content(), q{foo},
	    q<"foo@{[ qq<$bar$baz> ]}buzz" child 0 content>;
	is $kid->error(), undef,
	    q<"foo@{[ qq<$bar$baz> ]}buzz" child 0 error>;
	cmp_ok $kid->parent(), '==', $obj,
	    q<"foo@{[ qq<$bar$baz> ]}buzz" child 0 parent>;
	cmp_ok $kid->previous_sibling() || 0, '==', $obj->__kid( 0 - 1 ),
	    q<"foo@{[ qq<$bar$baz> ]}buzz" child 0 previous sibling>;
	cmp_ok $kid->next_sibling() || 0, '==', $obj->__kid( 0 + 1 ),
	    q<"foo@{[ qq<$bar$baz> ]}buzz" child 0 next sibling>;
    }
    if ( my $kid = $obj->child( 1 ) ) {
	ok $kid->isa( 'PPIx::QuoteLike::Token::Interpolation' ),
	    q<"foo@{[ qq<$bar$baz> ]}buzz" child 1 class>;
	is $kid->content(), q/@{[ qq<$bar$baz> ]}/,
	    q<"foo@{[ qq<$bar$baz> ]}buzz" child 1 content>;
	is $kid->error(), undef,
	    q<"foo@{[ qq<$bar$baz> ]}buzz" child 1 error>;
	cmp_ok $kid->parent(), '==', $obj,
	    q<"foo@{[ qq<$bar$baz> ]}buzz" child 1 parent>;
	cmp_ok $kid->previous_sibling() || 0, '==', $obj->__kid( 1 - 1 ),
	    q<"foo@{[ qq<$bar$baz> ]}buzz" child 1 previous sibling>;
	cmp_ok $kid->next_sibling() || 0, '==', $obj->__kid( 1 + 1 ),
	    q<"foo@{[ qq<$bar$baz> ]}buzz" child 1 next sibling>;
	is_deeply [ sort $kid->variables() ],
	    [ qw{ $bar $baz } ],
	    q<"foo@{[ qq<$bar$baz> ]}buzz" child 1 interpolated variables>;
    }
    if ( my $kid = $obj->child( 2 ) ) {
	ok $kid->isa( 'PPIx::QuoteLike::Token::String' ),
	    q<"foo@{[ qq<$bar$baz> ]}buzz" child 2 class>;
	is $kid->content(), q{buzz},
	    q<"foo@{[ qq<$bar$baz> ]}buzz" child 2 content>;
	is $kid->error(), undef,
	    q<"foo@{[ qq<$bar$baz> ]}buzz" child 2 error>;
	cmp_ok $kid->parent(), '==', $obj,
	    q<"foo@{[ qq<$bar$baz> ]}buzz" child 2 parent>;
	cmp_ok $kid->previous_sibling() || 0, '==', $obj->__kid( 2 - 1 ),
	    q<"foo@{[ qq<$bar$baz> ]}buzz" child 2 previous sibling>;
	cmp_ok $kid->next_sibling() || 0, '==', $obj->__kid( 2 + 1 ),
	    q<"foo@{[ qq<$bar$baz> ]}buzz" child 2 next sibling>;
    }
}

$obj = PPIx::QuoteLike->new( q{"$foo::$bar"} );
if ( ok $obj, q<Able to parse "$foo::$bar"> ) {
    cmp_ok $obj->failures(), '==', 0, q<Failures parsing "$foo::$bar">;
    cmp_ok $obj->interpolates(), '==', 1, q<Does "$foo::$bar" interpolate>;
    is $obj->content(), q{"$foo::$bar"}, q<Can recover "$foo::$bar">;
    is $obj->__get_value( 'type' ), q{}, q<Type of "$foo::$bar">;
    is $obj->delimiters(), q{""}, q<Delimiters of "$foo::$bar">;
    is $obj->__get_value( 'start' ), q{"}, q<Start delimiter of "$foo::$bar">;
    is $obj->__get_value( 'finish' ), q{"}, q<Finish delimiter of "$foo::$bar">;
    is $obj->encoding(), undef, q<"$foo::$bar" encoding>;
    is_deeply [ sort $obj->variables() ],
	[ qw{ $bar $foo } ],
	q<"$foo::$bar" interpolated variables>;
    cmp_ok $obj->postderef(), '==', 1, q<"$foo::$bar" postderef>;
    cmp_ok scalar $obj->elements(), '==', 6,
	q<Number of elements of "$foo::$bar">;
    cmp_ok scalar $obj->children(), '==', 3,
	q<Number of children of "$foo::$bar">;
    if ( my $kid = $obj->child( 0 ) ) {
	ok $kid->isa( 'PPIx::QuoteLike::Token::Interpolation' ),
	    q<"$foo::$bar" child 0 class>;
	is $kid->content(), q{$foo},
	    q<"$foo::$bar" child 0 content>;
	is $kid->error(), undef,
	    q<"$foo::$bar" child 0 error>;
	cmp_ok $kid->parent(), '==', $obj,
	    q<"$foo::$bar" child 0 parent>;
	cmp_ok $kid->previous_sibling() || 0, '==', $obj->__kid( 0 - 1 ),
	    q<"$foo::$bar" child 0 previous sibling>;
	cmp_ok $kid->next_sibling() || 0, '==', $obj->__kid( 0 + 1 ),
	    q<"$foo::$bar" child 0 next sibling>;
	is_deeply [ sort $kid->variables() ],
	    [ qw{ $foo } ],
	    q<"$foo::$bar" child 0 interpolated variables>;
    }
    if ( my $kid = $obj->child( 1 ) ) {
	ok $kid->isa( 'PPIx::QuoteLike::Token::String' ),
	    q<"$foo::$bar" child 1 class>;
	is $kid->content(), q{::},
	    q<"$foo::$bar" child 1 content>;
	is $kid->error(), undef,
	    q<"$foo::$bar" child 1 error>;
	cmp_ok $kid->parent(), '==', $obj,
	    q<"$foo::$bar" child 1 parent>;
	cmp_ok $kid->previous_sibling() || 0, '==', $obj->__kid( 1 - 1 ),
	    q<"$foo::$bar" child 1 previous sibling>;
	cmp_ok $kid->next_sibling() || 0, '==', $obj->__kid( 1 + 1 ),
	    q<"$foo::$bar" child 1 next sibling>;
    }
    if ( my $kid = $obj->child( 2 ) ) {
	ok $kid->isa( 'PPIx::QuoteLike::Token::Interpolation' ),
	    q<"$foo::$bar" child 2 class>;
	is $kid->content(), q{$bar},
	    q<"$foo::$bar" child 2 content>;
	is $kid->error(), undef,
	    q<"$foo::$bar" child 2 error>;
	cmp_ok $kid->parent(), '==', $obj,
	    q<"$foo::$bar" child 2 parent>;
	cmp_ok $kid->previous_sibling() || 0, '==', $obj->__kid( 2 - 1 ),
	    q<"$foo::$bar" child 2 previous sibling>;
	cmp_ok $kid->next_sibling() || 0, '==', $obj->__kid( 2 + 1 ),
	    q<"$foo::$bar" child 2 next sibling>;
	is_deeply [ sort $kid->variables() ],
	    [ qw{ $bar } ],
	    q<"$foo::$bar" child 2 interpolated variables>;
    }
}

$obj = PPIx::QuoteLike->new( q/"@{$x[$i]}"/ );
if ( ok $obj, q<Able to parse "@{$x[$i]}"> ) {
    cmp_ok $obj->failures(), '==', 0, q<Failures parsing "@{$x[$i]}">;
    cmp_ok $obj->interpolates(), '==', 1, q<Does "@{$x[$i]}" interpolate>;
    is $obj->content(), q/"@{$x[$i]}"/, q<Can recover "@{$x[$i]}">;
    is $obj->__get_value( 'type' ), q{}, q<Type of "@{$x[$i]}">;
    is $obj->delimiters(), q{""}, q<Delimiters of "@{$x[$i]}">;
    is $obj->__get_value( 'start' ), q{"}, q<Start delimiter of "@{$x[$i]}">;
    is $obj->__get_value( 'finish' ), q{"}, q<Finish delimiter of "@{$x[$i]}">;
    is $obj->encoding(), undef, q<"@{$x[$i]}" encoding>;
    is_deeply [ sort $obj->variables() ],
	[ qw{ $i @x } ],
	q<"@{$x[$i]}" interpolated variables>;
    cmp_ok $obj->postderef(), '==', 1, q<"@{$x[$i]}" postderef>;
    cmp_ok scalar $obj->elements(), '==', 4,
	q<Number of elements of "@{$x[$i]}">;
    cmp_ok scalar $obj->children(), '==', 1,
	q<Number of children of "@{$x[$i]}">;
    if ( my $kid = $obj->child( 0 ) ) {
	ok $kid->isa( 'PPIx::QuoteLike::Token::Interpolation' ),
	    q<"@{$x[$i]}" child 0 class>;
	is $kid->content(), q/@{$x[$i]}/,
	    q<"@{$x[$i]}" child 0 content>;
	is $kid->error(), undef,
	    q<"@{$x[$i]}" child 0 error>;
	cmp_ok $kid->parent(), '==', $obj,
	    q<"@{$x[$i]}" child 0 parent>;
	cmp_ok $kid->previous_sibling() || 0, '==', $obj->__kid( 0 - 1 ),
	    q<"@{$x[$i]}" child 0 previous sibling>;
	cmp_ok $kid->next_sibling() || 0, '==', $obj->__kid( 0 + 1 ),
	    q<"@{$x[$i]}" child 0 next sibling>;
	is_deeply [ sort $kid->variables() ],
	    [ qw{ $i @x } ],
	    q<"@{$x[$i]}" child 0 interpolated variables>;
    }
}

$obj = PPIx::QuoteLike->new( <<'__END_OF_HERE_DOCUMENT'
<< "EOD"
$foo->{bar}bazzle
EOD
__END_OF_HERE_DOCUMENT
 );
if ( ok $obj, q{Able to parse << "EOD"
$foo->{bar}bazzle
EOD
} ) {
    cmp_ok $obj->failures(), '==', 0, q{Failures parsing << "EOD"
$foo->{bar}bazzle
EOD
};
    cmp_ok $obj->interpolates(), '==', 1, q{Does << "EOD"
$foo->{bar}bazzle
EOD
 interpolate};
    is $obj->content(), <<'__END_OF_HERE_DOCUMENT'
<< "EOD"
$foo->{bar}bazzle
EOD
__END_OF_HERE_DOCUMENT
, q{Can recover << "EOD"
$foo->{bar}bazzle
EOD
};
    is $obj->__get_value( 'type' ), '<<',
	q{Type of << "EOD"
$foo->{bar}bazzle
EOD
};
    is $obj->delimiters(), q{"EOD"EOD}, q{Delimiters of << "EOD"
$foo->{bar}bazzle
EOD
};
    is $obj->__get_value( 'start' ), q{"EOD"}, q{Start delimiter of << "EOD"
$foo->{bar}bazzle
EOD
};
    is $obj->__get_value( 'finish' ), q{EOD}, q{Finish delimiter of << "EOD"
$foo->{bar}bazzle
EOD
};
    is $obj->encoding(), undef, q{<< "EOD"
$foo->{bar}bazzle
EOD
 encoding};
    is_deeply [ sort $obj->variables() ],
	[ qw{ $foo } ],
	q{<< "EOD"
$foo->{bar}bazzle
EOD
 interpolated variables};
    cmp_ok $obj->postderef(), '==', 1, q{<< "EOD"
$foo->{bar}bazzle
EOD
 postderef};
    cmp_ok scalar $obj->elements(), '==', 8,
	q{Number of elements of << "EOD"
$foo->{bar}bazzle
EOD
};
    cmp_ok scalar $obj->children(), '==', 2,
	q{Number of children of << "EOD"
$foo->{bar}bazzle
EOD
};
    if ( my $kid = $obj->child( 0 ) ) {
	ok $kid->isa( 'PPIx::QuoteLike::Token::Interpolation' ),
	    q{<< "EOD"
$foo->{bar}bazzle
EOD
 child 0 class};
	is $kid->content(), q/$foo->{bar}/,
	    q{<< "EOD"
$foo->{bar}bazzle
EOD
 child 0 content};
	is $kid->error(), undef,
	    q{<< "EOD"
$foo->{bar}bazzle
EOD
 child 0 error};
	cmp_ok $kid->parent(), '==', $obj,
	    q{<< "EOD"
$foo->{bar}bazzle
EOD
 child 0 parent};
	cmp_ok $kid->previous_sibling() || 0, '==', $obj->__kid( 0 - 1 ),
	    q{<< "EOD"
$foo->{bar}bazzle
EOD
 child 0 previous sibling};
	cmp_ok $kid->next_sibling() || 0, '==', $obj->__kid( 0 + 1 ),
	    q{<< "EOD"
$foo->{bar}bazzle
EOD
 child 0 next sibling};
	is_deeply [ sort $kid->variables() ],
	    [ qw{ $foo } ],
	    q{<< "EOD"
$foo->{bar}bazzle
EOD
 child 0 interpolated variables};
    }
    if ( my $kid = $obj->child( 1 ) ) {
	ok $kid->isa( 'PPIx::QuoteLike::Token::String' ),
	    q{<< "EOD"
$foo->{bar}bazzle
EOD
 child 1 class};
	is $kid->content(), q{bazzle
},
	    q{<< "EOD"
$foo->{bar}bazzle
EOD
 child 1 content};
	is $kid->error(), undef,
	    q{<< "EOD"
$foo->{bar}bazzle
EOD
 child 1 error};
	cmp_ok $kid->parent(), '==', $obj,
	    q{<< "EOD"
$foo->{bar}bazzle
EOD
 child 1 parent};
	cmp_ok $kid->previous_sibling() || 0, '==', $obj->__kid( 1 - 1 ),
	    q{<< "EOD"
$foo->{bar}bazzle
EOD
 child 1 previous sibling};
	cmp_ok $kid->next_sibling() || 0, '==', $obj->__kid( 1 + 1 ),
	    q{<< "EOD"
$foo->{bar}bazzle
EOD
 child 1 next sibling};
    }
}

$obj = PPIx::QuoteLike->new( q{"@@x"} );
if ( ok $obj, q{Able to parse "@@x"} ) {
    cmp_ok $obj->failures(), '==', 0, q{Failures parsing "@@x"};
    cmp_ok $obj->interpolates(), '==', 1, q{Does "@@x" interpolate};
    is $obj->content(), q{"@@x"}, q{Can recover "@@x"};
    is $obj->__get_value( 'type' ), q{}, q{Type of "@@x"};
    is $obj->delimiters(), q{""}, q{Delimiters of "@@x"};
    is $obj->__get_value( 'start' ), q{"}, q{Start delimiter of "@@x"};
    is $obj->__get_value( 'finish' ), q{"}, q{Finish delimiter of "@@x"};
    is $obj->encoding(), undef, q{"@@x" encoding};
    is_deeply [ sort $obj->variables() ],
	[ qw{ @x } ],
	q{"@@x" interpolated variables};
    cmp_ok $obj->postderef(), '==', 1, q{"@@x" postderef};
    cmp_ok scalar $obj->elements(), '==', 5,
	q{Number of elements of "@@x"};
    cmp_ok scalar $obj->children(), '==', 2,
	q{Number of children of "@@x"};
    if ( my $kid = $obj->child( 0 ) ) {
	ok $kid->isa( 'PPIx::QuoteLike::Token::String' ),
	    q{"@@x" child 0 class};
	is $kid->content(), q{@},
	    q{"@@x" child 0 content};
	is $kid->error(), undef,
	    q{"@@x" child 0 error};
	cmp_ok $kid->parent(), '==', $obj,
	    q{"@@x" child 0 parent};
	cmp_ok $kid->previous_sibling() || 0, '==', $obj->__kid( 0 - 1 ),
	    q{"@@x" child 0 previous sibling};
	cmp_ok $kid->next_sibling() || 0, '==', $obj->__kid( 0 + 1 ),
	    q{"@@x" child 0 next sibling};
    }
    if ( my $kid = $obj->child( 1 ) ) {
	ok $kid->isa( 'PPIx::QuoteLike::Token::Interpolation' ),
	    q{"@@x" child 1 class};
	is $kid->content(), q{@x},
	    q{"@@x" child 1 content};
	is $kid->error(), undef,
	    q{"@@x" child 1 error};
	cmp_ok $kid->parent(), '==', $obj,
	    q{"@@x" child 1 parent};
	cmp_ok $kid->previous_sibling() || 0, '==', $obj->__kid( 1 - 1 ),
	    q{"@@x" child 1 previous sibling};
	cmp_ok $kid->next_sibling() || 0, '==', $obj->__kid( 1 + 1 ),
	    q{"@@x" child 1 next sibling};
	is_deeply [ sort $kid->variables() ],
	    [ qw{ @x } ],
	    q{"@@x" child 1 interpolated variables};
    }
}

$obj = PPIx::QuoteLike->new( q{"x@*y"} );
if ( ok $obj, q{Able to parse "x@*y"} ) {
    cmp_ok $obj->failures(), '==', 0, q{Failures parsing "x@*y"};
    cmp_ok $obj->interpolates(), '==', 1, q{Does "x@*y" interpolate};
    is $obj->content(), q{"x@*y"}, q{Can recover "x@*y"};
    is $obj->__get_value( 'type' ), q{}, q{Type of "x@*y"};
    is $obj->delimiters(), q{""}, q{Delimiters of "x@*y"};
    is $obj->__get_value( 'start' ), q{"}, q{Start delimiter of "x@*y"};
    is $obj->__get_value( 'finish' ), q{"}, q{Finish delimiter of "x@*y"};
    is $obj->encoding(), undef, q{"x@*y" encoding};
    is_deeply [ sort $obj->variables() ],
	[ qw{  } ],
	q{"x@*y" interpolated variables};
    cmp_ok $obj->postderef(), '==', 1, q{"x@*y" postderef};
    cmp_ok scalar $obj->elements(), '==', 4,
	q{Number of elements of "x@*y"};
    cmp_ok scalar $obj->children(), '==', 1,
	q{Number of children of "x@*y"};
    if ( my $kid = $obj->child( 0 ) ) {
	ok $kid->isa( 'PPIx::QuoteLike::Token::String' ),
	    q{"x@*y" child 0 class};
	is $kid->content(), q{x@*y},
	    q{"x@*y" child 0 content};
	is $kid->error(), undef,
	    q{"x@*y" child 0 error};
	cmp_ok $kid->parent(), '==', $obj,
	    q{"x@*y" child 0 parent};
	cmp_ok $kid->previous_sibling() || 0, '==', $obj->__kid( 0 - 1 ),
	    q{"x@*y" child 0 previous sibling};
	cmp_ok $kid->next_sibling() || 0, '==', $obj->__kid( 0 + 1 ),
	    q{"x@*y" child 0 next sibling};
    }
}

$obj = PPIx::QuoteLike->new( q{"$@"} );
if ( ok $obj, q{Able to parse "$@"} ) {
    cmp_ok $obj->failures(), '==', 0, q{Failures parsing "$@"};
    cmp_ok $obj->interpolates(), '==', 1, q{Does "$@" interpolate};
    is $obj->content(), q{"$@"}, q{Can recover "$@"};
    is $obj->__get_value( 'type' ), q{}, q{Type of "$@"};
    is $obj->delimiters(), q{""}, q{Delimiters of "$@"};
    is $obj->__get_value( 'start' ), q{"}, q{Start delimiter of "$@"};
    is $obj->__get_value( 'finish' ), q{"}, q{Finish delimiter of "$@"};
    is $obj->encoding(), undef, q{"$@" encoding};
    is_deeply [ sort $obj->variables() ],
	[ qw{ $@ } ],
	q{"$@" interpolated variables};
    cmp_ok $obj->postderef(), '==', 1, q{"$@" postderef};
    cmp_ok scalar $obj->elements(), '==', 4,
	q{Number of elements of "$@"};
    cmp_ok scalar $obj->children(), '==', 1,
	q{Number of children of "$@"};
    if ( my $kid = $obj->child( 0 ) ) {
	ok $kid->isa( 'PPIx::QuoteLike::Token::Interpolation' ),
	    q{"$@" child 0 class};
	is $kid->content(), q{$@},
	    q{"$@" child 0 content};
	is $kid->error(), undef,
	    q{"$@" child 0 error};
	cmp_ok $kid->parent(), '==', $obj,
	    q{"$@" child 0 parent};
	cmp_ok $kid->previous_sibling() || 0, '==', $obj->__kid( 0 - 1 ),
	    q{"$@" child 0 previous sibling};
	cmp_ok $kid->next_sibling() || 0, '==', $obj->__kid( 0 + 1 ),
	    q{"$@" child 0 next sibling};
	is_deeply [ sort $kid->variables() ],
	    [ qw{ $@ } ],
	    q{"$@" child 0 interpolated variables};
    }
}

$obj = PPIx::QuoteLike->new( q/"${x}[0]"/ );
if ( ok $obj, q{Able to parse "${x}[0]"} ) {
    cmp_ok $obj->failures(), '==', 0, q{Failures parsing "${x}[0]"};
    cmp_ok $obj->interpolates(), '==', 1, q{Does "${x}[0]" interpolate};
    is $obj->content(), q/"${x}[0]"/, q{Can recover "${x}[0]"};
    is $obj->__get_value( 'type' ), q{}, q{Type of "${x}[0]"};
    is $obj->delimiters(), q{""}, q{Delimiters of "${x}[0]"};
    is $obj->__get_value( 'start' ), q{"}, q{Start delimiter of "${x}[0]"};
    is $obj->__get_value( 'finish' ), q{"}, q{Finish delimiter of "${x}[0]"};
    is $obj->encoding(), undef, q{"${x}[0]" encoding};
    is_deeply [ sort $obj->variables() ],
	[ qw{ $x } ],
	q{"${x}[0]" interpolated variables};
    cmp_ok $obj->postderef(), '==', 1, q{"${x}[0]" postderef};
    cmp_ok scalar $obj->elements(), '==', 5,
	q{Number of elements of "${x}[0]"};
    cmp_ok scalar $obj->children(), '==', 2,
	q{Number of children of "${x}[0]"};
    if ( my $kid = $obj->child( 0 ) ) {
	ok $kid->isa( 'PPIx::QuoteLike::Token::Interpolation' ),
	    q{"${x}[0]" child 0 class};
	is $kid->content(), q/${x}/,
	    q{"${x}[0]" child 0 content};
	is $kid->error(), undef,
	    q{"${x}[0]" child 0 error};
	cmp_ok $kid->parent(), '==', $obj,
	    q{"${x}[0]" child 0 parent};
	cmp_ok $kid->previous_sibling() || 0, '==', $obj->__kid( 0 - 1 ),
	    q{"${x}[0]" child 0 previous sibling};
	cmp_ok $kid->next_sibling() || 0, '==', $obj->__kid( 0 + 1 ),
	    q{"${x}[0]" child 0 next sibling};
	is_deeply [ sort $kid->variables() ],
	    [ qw{ $x } ],
	    q{"${x}[0]" child 0 interpolated variables};
    }
    if ( my $kid = $obj->child( 1 ) ) {
	ok $kid->isa( 'PPIx::QuoteLike::Token::String' ),
	    q{"${x}[0]" child 1 class};
	is $kid->content(), q{[0]},
	    q{"${x}[0]" child 1 content};
	is $kid->error(), undef,
	    q{"${x}[0]" child 1 error};
	cmp_ok $kid->parent(), '==', $obj,
	    q{"${x}[0]" child 1 parent};
	cmp_ok $kid->previous_sibling() || 0, '==', $obj->__kid( 1 - 1 ),
	    q{"${x}[0]" child 1 previous sibling};
	cmp_ok $kid->next_sibling() || 0, '==', $obj->__kid( 1 + 1 ),
	    q{"${x}[0]" child 1 next sibling};
    }
}

$obj = PPIx::QuoteLike->new( q{"$x[$[]"} );
if ( ok $obj, q{Able to parse "$x[$[]"} ) {
    cmp_ok $obj->failures(), '==', 0, q{Failures parsing "$x[$[]"};
    cmp_ok $obj->interpolates(), '==', 1, q{Does "$x[$[]" interpolate};
    is $obj->content(), q{"$x[$[]"}, q{Can recover "$x[$[]"};
    is $obj->__get_value( 'type' ), q{}, q{Type of "$x[$[]"};
    is $obj->delimiters(), q{""}, q{Delimiters of "$x[$[]"};
    is $obj->__get_value( 'start' ), q{"}, q{Start delimiter of "$x[$[]"};
    is $obj->__get_value( 'finish' ), q{"}, q{Finish delimiter of "$x[$[]"};
    is $obj->encoding(), undef, q{"$x[$[]" encoding};
    is_deeply [ sort $obj->variables() ],
	[ qw{ $[ @x } ],
	q{"$x[$[]" interpolated variables};
    cmp_ok $obj->postderef(), '==', 1, q{"$x[$[]" postderef};
    cmp_ok scalar $obj->elements(), '==', 4,
	q{Number of elements of "$x[$[]"};
    cmp_ok scalar $obj->children(), '==', 1,
	q{Number of children of "$x[$[]"};
    if ( my $kid = $obj->child( 0 ) ) {
	ok $kid->isa( 'PPIx::QuoteLike::Token::Interpolation' ),
	    q{"$x[$[]" child 0 class};
	is $kid->content(), q{$x[$[]},
	    q{"$x[$[]" child 0 content};
	is $kid->error(), undef,
	    q{"$x[$[]" child 0 error};
	cmp_ok $kid->parent(), '==', $obj,
	    q{"$x[$[]" child 0 parent};
	cmp_ok $kid->previous_sibling() || 0, '==', $obj->__kid( 0 - 1 ),
	    q{"$x[$[]" child 0 previous sibling};
	cmp_ok $kid->next_sibling() || 0, '==', $obj->__kid( 0 + 1 ),
	    q{"$x[$[]" child 0 next sibling};
	is_deeply [ sort $kid->variables() ],
	    [ qw{ $[ @x } ],
	    q{"$x[$[]" child 0 interpolated variables};
    }
}

$obj = PPIx::QuoteLike->new( q/"$${foo}"/ );
if ( ok $obj, q{Able to parse "$${foo}"} ) {
    cmp_ok $obj->failures(), '==', 0, q{Failures parsing "$${foo}"};
    cmp_ok $obj->interpolates(), '==', 1, q{Does "$${foo}" interpolate};
    is $obj->content(), q/"$${foo}"/, q{Can recover "$${foo}"};
    is $obj->__get_value( 'type' ), q{}, q{Type of "$${foo}"};
    is $obj->delimiters(), q{""}, q{Delimiters of "$${foo}"};
    is $obj->__get_value( 'start' ), q{"}, q{Start delimiter of "$${foo}"};
    is $obj->__get_value( 'finish' ), q{"}, q{Finish delimiter of "$${foo}"};
    is $obj->encoding(), undef, q{"$${foo}" encoding};
    is_deeply [ sort $obj->variables() ],
	[ qw{ $foo } ],
	q{"$${foo}" interpolated variables};
    cmp_ok $obj->postderef(), '==', 1, q{"$${foo}" postderef};
    cmp_ok scalar $obj->elements(), '==', 4,
	q{Number of elements of "$${foo}"};
    cmp_ok scalar $obj->children(), '==', 1,
	q{Number of children of "$${foo}"};
    if ( my $kid = $obj->child( 0 ) ) {
	ok $kid->isa( 'PPIx::QuoteLike::Token::Interpolation' ),
	    q{"$${foo}" child 0 class};
	is $kid->content(), q/$${foo}/,
	    q{"$${foo}" child 0 content};
	is $kid->error(), undef,
	    q{"$${foo}" child 0 error};
	cmp_ok $kid->parent(), '==', $obj,
	    q{"$${foo}" child 0 parent};
	cmp_ok $kid->previous_sibling() || 0, '==', $obj->__kid( 0 - 1 ),
	    q{"$${foo}" child 0 previous sibling};
	cmp_ok $kid->next_sibling() || 0, '==', $obj->__kid( 0 + 1 ),
	    q{"$${foo}" child 0 next sibling};
	is_deeply [ sort $kid->variables() ],
	    [ qw{ $foo } ],
	    q<"$${foo}" child 0 interpolated variables>;
    }
}

$obj = PPIx::QuoteLike->new( q/"${$}"/ );
if ( ok $obj, q{Able to parse "${$}"} ) {
    cmp_ok $obj->failures(), '==', 0, q{Failures parsing "${$}"};
    cmp_ok $obj->interpolates(), '==', 1, q{Does "${$}" interpolate};
    is $obj->content(), q/"${$}"/, q{Can recover "${$}"};
    is $obj->__get_value( 'type' ), q{}, q{Type of "${$}"};
    is $obj->delimiters(), q{""}, q{Delimiters of "${$}"};
    is $obj->__get_value( 'start' ), q{"}, q{Start delimiter of "${$}"};
    is $obj->__get_value( 'finish' ), q{"}, q{Finish delimiter of "${$}"};
    is $obj->encoding(), undef, q<"${$}" encoding>;
    is_deeply [ sort $obj->variables() ],
	[ qw{ $$ } ],
	q{"${$}" interpolated variables};
    cmp_ok $obj->postderef(), '==', 1, q{"${$}" postderef};
    cmp_ok scalar $obj->elements(), '==', 4,
	q{Number of elements of "${$}"};
    cmp_ok scalar $obj->children(), '==', 1,
	q{Number of children of "${$}"};
    if ( my $kid = $obj->child( 0 ) ) {
	ok $kid->isa( 'PPIx::QuoteLike::Token::Interpolation' ),
	    q{"${$}" child 0 class};
	is $kid->content(), q/${$}/,
	    q{"${$}" child 0 content};
	is $kid->error(), undef,
	    q{"${$}" child 0 error};
	cmp_ok $kid->parent(), '==', $obj,
	    q{"${$}" child 0 parent};
	cmp_ok $kid->previous_sibling() || 0, '==', $obj->__kid( 0 - 1 ),
	    q{"${$}" child 0 previous sibling};
	cmp_ok $kid->next_sibling() || 0, '==', $obj->__kid( 0 + 1 ),
	    q{"${$}" child 0 next sibling};
	is_deeply [ sort $kid->variables() ],
	    [ qw{ $$ } ],
	    q{"${$}" child 0 interpolated variables};
    }
}

$obj = PPIx::QuoteLike->new( q/"@{[ ${ foo } ]}"/ );
if ( ok $obj, q{Able to parse "@{[ ${ foo } ]}"} ) {
    cmp_ok $obj->failures(), '==', 0, q{Failures parsing "@{[ ${ foo } ]}"};
    cmp_ok $obj->interpolates(), '==', 1, q{Does "@{[ ${ foo } ]}" interpolate};
    is $obj->content(), q/"@{[ ${ foo } ]}"/, q{Can recover "@{[ ${ foo } ]}"};
    is $obj->__get_value( 'type' ), q{}, q{Type of "@{[ ${ foo } ]}"};
    is $obj->delimiters(), q{""}, q{Delimiters of "@{[ ${ foo } ]}"};
    is $obj->__get_value( 'start' ), q{"}, q{Start delimiter of "@{[ ${ foo } ]}"};
    is $obj->__get_value( 'finish' ), q{"}, q{Finish delimiter of "@{[ ${ foo } ]}"};
    is $obj->encoding(), undef, q{"@{[ ${ foo } ]}" encoding};
    if ( eval { require PPI::Document; 1 } ) {
	is_deeply [ sort $obj->variables() ],
	    [ qw{ $foo } ],
	    q{"@{[ ${ foo } ]}" interpolated variables};
    }
    cmp_ok $obj->postderef(), '==', 1, q{"@{[ ${ foo } ]}" postderef};
    cmp_ok scalar $obj->elements(), '==', 4,
	q{Number of elements of "@{[ ${ foo } ]}"};
    cmp_ok scalar $obj->children(), '==', 1,
	q{Number of children of "@{[ ${ foo } ]}"};
    if ( my $kid = $obj->child( 0 ) ) {
	ok $kid->isa( 'PPIx::QuoteLike::Token::Interpolation' ),
	    q{"@{[ ${ foo } ]}" child 0 class};
	is $kid->content(), q/@{[ ${ foo } ]}/,
	    q{"@{[ ${ foo } ]}" child 0 content};
	is $kid->error(), undef,
	    q{"@{[ ${ foo } ]}" child 0 error};
	cmp_ok $kid->parent(), '==', $obj,
	    q{"@{[ ${ foo } ]}" child 0 parent};
	cmp_ok $kid->previous_sibling() || 0, '==', $obj->__kid( 0 - 1 ),
	    q{"@{[ ${ foo } ]}" child 0 previous sibling};
	cmp_ok $kid->next_sibling() || 0, '==', $obj->__kid( 0 + 1 ),
	    q{"@{[ ${ foo } ]}" child 0 next sibling};
	if ( eval { require PPI::Document; 1 } ) {
	    is_deeply [ sort $kid->variables() ],
		[ qw{ $foo } ],
		q{"@{[ ${ foo } ]}" child 0 interpolated variables};
	}
    }
}

done_testing;

sub PPIx::QuoteLike::__get_value {
    my ( $self, $method, @arg ) = @_;
    my $val = $self->$method( @arg );
    return ref $val ? $val->content() : $val;
}

sub PPIx::QuoteLike::__kid {
    my ( $self, $inx ) = @_;
    $inx >= 0
	and $inx < @{ $self->{children} }
	and return $self->{children}[$inx];
    return 0;
}

1;

# ex: set textwidth=72 :
