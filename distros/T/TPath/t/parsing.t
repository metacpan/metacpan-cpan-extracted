# what expressions we can make ASTs for

use strict;
use warnings;

use TPath::Grammar qw(parse);
use Test::More;
use Test::Exception;
use List::MoreUtils qw(natatime);

# a bunch of expressions licensed by the spec
my @parsable = make_paths(<<'END');
a[@b(not @c)]
a
~a~
~a~~b~
//foo
:id(bar)
:root
(a)
(/a)?
a?
a+
a*
a{1,2}
a{2}
a{,2}
a{2,}
a(/b|/c)
a(/b|/c){1,2}
a(/b|/c){2}
a(/b|/c){,2}
a(/b|/c){2,}
/..
/.
/>a
child::a
ancestor-or-self::a
leaf::a
:root/a
:root//a
:,a:a,
::a,a:
:"a a"
:'a a'
//@:,a:a,
//@::a,a:
//@:"a a"
//@:'a a'
^a
/^a
//^a
^~a~
/^~a~
//^~a~
^@a
/^@a
//^@a
/b/leaf::a
/a/b
/a[@test]
/a[@t-est]
/a[@t:est]
/a[@t3st]
/a[@_test]
/a[@$test]
/a[@test(.)]
/a[@test(1)]
/a[@test("foo")]
/a[@test("fo'o")]
/a[@test("fo\"o")]
/a[@test('foo')]
/a[@test('fo"o')]
/a[@test('fo\'o')]
/a[@test(@foo)]
/a[@test(1,2)]
/a[1 < @test]
/a[1 = @test]
/a[1 == @test]
/a[1 <= @test]
/a[1 >= @test]
/a[1 != @test]
/a[@test > 1]
/a[! a]
/a[(a)]
/a[a;b]
/a[a ; b]
/a[a&b]
/a[a||b]
/a[0][@test]
/a[b[c]]
/a|//b
//b:b
//b:b[@attr != "1"]
//b:b[@attr(1) != "1"]
//b:b[@attr("fo:o") != "1"]
a[@b =~ 'c']
a[@b !~ 'c']
a{0,}
:(a)
:{a}
:[a]
:<a>
:/a/
:,a,
/a/"a"
/a/'a'
*[@foo |= 'bar']
*[@foo =|= 'bar']
*[@foo =| 'bar']
*
/*
//*
child::*
//a[@foo = @echo(*)]
//a[@foo == @echo(*)]
//a [ @foo == 1 ]
//a [0] //b [ c ]
/a/:p
/a/:p[@foo]
/a/:p{2}
//a/previous::*
//*[a + 1 = @foo]
//*[1+2=3]
//*[-a=@foo]
//*[:sqrt(4)=@foo]
//*[:sqrt(@foo)=4]
//*[:sqrt(foo)=4]
//*[(1+@foo)**2 > b]
//*[. = *]
//*[* = .]
//*[@a(.) = @a(*)]
END

push @parsable, q{

# a comment

/a #comment
[1] # comment  
};
push @parsable, q{//@foo(
    1,
    "arg" # comment
    )
};

# a bunch of expressions not licensed by the spec
my @unparsable = make_paths(<<'END');
@a
/a(1)
//a(1)
/>a(1)
/*(1)
//*(1)
/>*(1)
/child::a(1)
a(b)
a{}
a{0}
a{,}
a{,0}
a{2,1}
a:(a(
// a
a *
END

# pairs of expressions that should have the same ASTs
my @equivalent = make_paths(<<'END');
::a:
a

//@::a:
//@a

::a\:a:
a\:a

/a/'a'
/a/a

/a/"a"
/a/a

:(a)
a

:<a>
a

:{a}
a

:[a]
a

a[b]
a[(b)]

a[b]
a[(((b)))]

a[@b or @c]
a[@b || @c]

a[@b or @c & @d]
a[@b or (@c & @d)]

a[@b or @c or @d or @e]
a[@b or ((@c or @d) or @e)]

a[@b]
a[!!@b]

a[!@b]
a[!!!@b]

a
(a)

a?
(a)?

a
((a))

a
a{1}

a
a{1,1}

a?
a{,1}

a{,1}
a{0,1}

a?
a{0,1}

a+
a{1,}

/a/b
(/a/b){1}

/a/b
(/a/b){1,1}

(/a/b)?
(/a/b){,1}

(/a/b)?
(/a/b){0,1}

(/a/b)+
(/a/b){1,}

a{0,}
a*

a[2+2=4]
a[:sqrt(16)=4]

a[@foo + 1=2]
a[1+@foo = 2]

a[1+(2+(3+(4+5))) = @b]
a[15=@b]

a[2*(1+2+3+4)=@b]
a[20=@b]
END

push @equivalent, q{//a//b}, q{
    //a # comment
    
    //b
    #comment
    #comment
};
push @equivalent, q{//@foo('bar')}, q{//@foo
    # comment
    ( # comment
    'bar' # comment
    ) #comment
};
push @equivalent, q{//a[@b = 'c']}, q{
    //a #comment
    [ # comment
    @b # comment
    = # comment
    'c' #comment
    ] # comment
};

# some leaf values to test
my @leaves = make_paths(<<'END');
a[@b = 'foo']
v
foo

//@b
name
b

~a~~b~
pattern
a~b

/>a
separator
/>

//@\'b
name
'b

//@:,'b,
name
'b

:id(\))
id
)

//\3
specific
3

//a[9]
idx
9

//a[-1]
idx
-1

//a[@b = 'fo\'o']
v
fo'o

//a[@b = "fo\"o"]
v
fo"o

//a[@b('c')]
v
c

//a[@b(1)]
v
1
END

push @leaves, q{//a[@b('
    c')]}, 'v', q{
    c};

plan tests => @parsable + @unparsable + @equivalent / 2 + @leaves / 3;

for my $e (@parsable) {
    lives_ok { parse($e) } "can parse $e";
}

for my $e (@unparsable) {
    dies_ok { parse($e) } "cannot parse $e";
}

my $i = natatime 2, @equivalent;
while ( my ( $left, $right ) = $i->() ) {
    is_deeply parse($left), parse($right), "$left  ~  $right";
}

$i = natatime 3, @leaves;
while ( my ( $expression, $key, $value ) = $i->() ) {
    is leaf( $expression, $key ), $value,
      "the value of $key in $expression is $value";
}

#done_testing();

sub leaf {
    my ( $expression, $key ) = @_;
    my $ref = parse($expression);
    return find_leaf( $ref, $key );
}

sub find_leaf {
    my ( $ref, $key ) = @_;
    my $type = ref $ref;
    if ( $type eq 'HASH' ) {
        while ( my ( $k, $v ) = each %$ref ) {
            return $v if $k eq $key;
            my $r = find_leaf( $v, $key );
            return $r if defined $r;
        }
        return undef;
    }
    if ( $type eq 'ARRAY' ) {
        for my $v (@$ref) {
            my $r = find_leaf( $v, $key );
            return $r if defined $r;
        }
        return undef;
    }
    return undef;
}

# convert a stringified list of expressions into the expressions to test
sub make_paths {
    my $text = shift;
    grep { $_ !~ /^#/ }
      map { ( my $v = $_ ) =~ s/^\s++|\s++$//g; $v ? $v : () }
      $text =~ /^.*$/gm;
}

