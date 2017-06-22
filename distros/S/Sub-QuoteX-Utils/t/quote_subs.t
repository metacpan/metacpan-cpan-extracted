#! perl

use strict;
use warnings;

use Test2::Bundle::Extended;

use Sub::Quote;
use Sub::QuoteX::Utils qw[ quote_subs ];

my $sub;

my @results;

# class with method
{
    package Yipee;
    use Moo;

    # make sure we don't inadvertently use bool context
    use overload bool => sub { 0 };
    use overload '""' => sub { $_[0] };

    sub halloo {
        shift;
        $_[0] = "Yipee";
        push @main::results, [@_];
    }
}

# and the object
my $object = Yipee->new;

# quoted sub
my $foo = quote_sub( q[ unshift @_, $foo; push @main::results, [ @_ ];],
    { '$foo' => \q[Foo] } );

# bare sub
sub bar {
    unshift @_, 'Bar';
    push @main::results, [@_];
}

# stash @_ in results for testing
my $stash = [ sub { push @main::results, [@_] } , local => 0 ];

subtest 'common, localized @_' => sub {

    @main::results = ();

    # create single subroutine. each invoked piece of code will have a
    # localized view of @_
    my $sub = quote_subs(
        $stash,
        \&bar,    # bare sub
        $stash,
        $foo,     # quoted sub
        $stash,
        [
            q< unshift @_, $goo; push @main::results, [ @_ ];>
            ,     # code in string with capture
            capture => { '$goo' => \q[Goo] },
        ],
        $stash,
        [ $object, 'halloo' ],    # method call
        $stash,
    );

    # and run it
    $sub->( 'Common' );

    is(
        \@main::results,
        [
           [ 'Common' ],
           [ 'Bar',   'Common' ],
           [ 'Common' ],
           [ 'Foo',   'Common' ],
           [ 'Common' ],
           [ 'Goo',   'Common' ],
           [ 'Common' ],
           [ 'Yipee'  ],
           [ 'Common' ],
        ],
    );
};

subtest 'common, non-localized @_' => sub {

    @main::results = ();

    # create single subroutine. each invoked piece of code will have a
    # localized view of @_
    my $sub = quote_subs(
        $stash,
        [ \&bar, local => 0 ],    # bare sub
        $stash,
        [ $foo, local => 0 ],     # quoted sub
        $stash,
        [
            q< unshift @_, $goo; push @main::results, [ @_ ];>
            ,                     # code in string with capture
            capture => { '$goo' => \q[Goo] },
            local   => 0,
        ],
        $stash,
        [ $object, 'halloo', local => 0 ],    # method call
        $stash,
    );

    # and run it
    $sub->( 'Common' );

    is(
        \@main::results,
        [
            [ 'Common' ],
            [ 'Bar', 'Common' ],
            [ 'Bar', 'Common' ],
            [ 'Foo', 'Bar', 'Common' ],
            [ 'Foo', 'Bar', 'Common' ],
            [ 'Goo', 'Foo', 'Bar', 'Common' ],
            [ 'Goo', 'Foo', 'Bar', 'Common' ],
            [ 'Yipee', 'Foo', 'Bar', 'Common' ],
            [ 'Yipee', 'Foo', 'Bar', 'Common' ],
        ],
    );
};

subtest 'per chunk, localized @_' => sub {

    @main::results = ();

    # now, give each a personalized @_
    my $sub = quote_subs(
        $stash,
        [
            \&bar,    # bare sub
            args => [qw( Bar )]
        ],
        $stash,
        [
            $foo,     # quoted sub
            args => [qw( Foo )]
        ],
        $stash,
        [
            q< unshift @_, $goo; push @main::results, [ @_ ];>
            ,         # code in string with capture
            capture => { '$goo' => \q[Goo] },
            args    => [qw( Goo )],
        ],
        $stash,
        [
            $object, 'halloo',    # method call
            args => [qw( Yipee )]
        ],
        $stash,
    );

    $sub->( 'Common' );

    is(
        \@main::results,
        [
            [ 'Common' ],
            [ 'Bar',   'Bar' ],
            [ 'Common' ],
            [ 'Foo',   'Foo' ],
            [ 'Common' ],
            [ 'Goo',   'Goo' ],
            [ 'Common' ],
            [ 'Yipee'  ],
            [ 'Common' ],
        ],
    );
};


subtest 'per chunk, non-localized @_' => sub {

    @main::results = ();

    # now, give each a personalized @_
    my $sub = quote_subs(
        $stash,
        [
            \&bar,    # bare sub
            args => [qw( Bar )],
            local => 0,
        ],
        $stash,
        [
            $foo,     # quoted sub
            args => [qw( Foo )],
            local => 0,
        ],
        $stash,
        [
            q< unshift @_, $goo; push @main::results, [ @_ ];>
            ,         # code in string with capture
            capture => { '$goo' => \q[Goo] },
            args    => [qw( Goo )],
            local => 0,
        ],
        $stash,
        [
            $object, 'halloo',    # method call
            args => [qw( Yipee )],
            local => 0,
        ],
        $stash,
    );

    $sub->( 'Common' );

    is(
        \@main::results,
        [
            [ 'Common' ],
            [ 'Bar', 'Bar' ],
            [ 'Bar', 'Bar' ],
            [ 'Foo',   'Foo' ],
            [ 'Foo',   'Foo' ],
            [ 'Goo',   'Goo' ],
            [ 'Goo',   'Goo' ],
            [ 'Yipee'  ],
            [ 'Yipee'  ],
        ],
    );
};



subtest 'empty, localized @_' => sub {

    @main::results = ();

    # now, explicitly empty @_
    $sub = quote_subs(
        $stash,
        [
            \&bar,    # bare sub
            args => undef
        ],
        $stash,
        [
            $foo,     # quoted sub
            args => undef
        ],
        $stash,
        [
            q{unshift @_, $goo; push @main::results, [ @_ ];}
            ,         # code in string with capture
            capture => { '$goo' => \q[Goo] },
            args    => undef,
        ],
        $stash,
        [
            $object, 'halloo',    #method call
            args => undef
        ],
        $stash,
    );

    $sub->( 'Common' );

    is( \@main::results,
        [
          ['Common' ],
          ['Bar'],
          ['Common' ],
          ['Foo'],
          ['Common' ],
          ['Goo'],
          ['Common' ],
          ['Yipee'],
          ['Common' ],
        ],
    );
};

done_testing();
