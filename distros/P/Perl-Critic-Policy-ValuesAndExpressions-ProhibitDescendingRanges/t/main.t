#!/usr/bin/env perl
use strict;
use warnings FATAL => 'all';

use re '/aa';

use 5.014;

=head1 NAME

t/main.t - which ranges the policy reports as counting down, and which it leaves alone

=head1 DESCRIPTION

A table of snippets that must be reported and a table that must not.

The cases that matter are the ranges that Perl gives an empty or a surprising
list for, the ranges that do what they look like, and the flip-flop operator,
which is C<..> in scalar context and which the policy must never report.

=cut

use Test::More;
use Test::Warnings qw{warnings};

use Perl::Critic;

# Loaded so that a syntax error in it is a compile failure here rather than
# Perl::Critic reporting no such policy.  Named as a string below, which is
# what ProhibitUnusedImports cannot see.
use Perl::Critic::Policy::ValuesAndExpressions::ProhibitDescendingRanges;    ## no critic (ProhibitUnusedImports)

# -profile => q{} because Perl::Critic otherwise walks up from cwd looking for a
# .perlcriticrc, finds this dist's own, and runs every policy in it against
# these snippets.  The anchored long name because -single-policy is a pattern.
my $POLICY = '^Perl::Critic::Policy::ValuesAndExpressions::ProhibitDescendingRanges$';

# A profile in a string, so that a test can set the parameters of the policy.
sub critic_with {
    my (%config) = @_;
    my $profile  = join "\n", '[ValuesAndExpressions::ProhibitDescendingRanges]', map { "$_ = $config{$_}" } sort keys %config;
    return Perl::Critic->new( -profile => \$profile, '-single-policy' => $POLICY, -severity => 1 );
}

my $critic = critic_with();

sub check_table {
    my ( $label, $with, %cases ) = @_;
    foreach my $case ( sort keys %cases ) {
        my ( $expected, $source ) = @{ $cases{$case} };
        is( scalar $with->critique( \$source ), $expected, "$label: $case" ) or diag $source;
    }
    return;
}

check_table(
    'two literals that count down', $critic,
    'numbers, in an assignment to an array' => [ 1, q{my @a = 10 .. 1;} ],
    'numbers, one apart'                    => [ 1, q{my @a = 2 .. 1;} ],
    'numbers, in a for list'                => [ 1, q{for my $i ( 10 .. 1 ) { print $i }} ],
    'numbers, after a for modifier'         => [ 1, q{print for 10 .. 1;} ],
    'negative numbers'                      => [ 1, q{my @a = ( -1 .. -5 );} ],
    'from a positive to a negative number'  => [ 1, q{my @a = ( 5 .. -1 );} ],
    'a unary minus with a space'            => [ 1, q{my @a = ( - 1 .. - 5 );} ],
    'a hex number'                          => [ 1, q{my @a = ( 0x10 .. 1 );} ],
    'a binary number'                       => [ 1, q{my @a = ( 0b11 .. 2 );} ],
    'an octal number'                       => [ 1, q{my @a = ( 010 .. 7 );} ],
    'a number with underscores'             => [ 1, q{my @a = ( 1_000 .. 999 );} ],
    'a number with an exponent'             => [ 1, q{my @a = ( 1e1 .. 9 );} ],
    'floats that truncate apart'            => [ 1, q{my @a = ( 2.5 .. 1.5 );} ],
    'numeric strings'                       => [ 1, q{my @a = ( '5' .. '1' );} ],
    'numeric strings, the right with a 0'   => [ 1, q{my @a = ( '10' .. '09' );} ],
    'a number and a numeric string'         => [ 1, q{my @a = ( 5 .. '1' );} ],
    'a longer string than the right end'    => [ 1, q{my @a = ( 'aa' .. 'b' );} ],
    'a string to the empty string'          => [ 1, q{my @a = ( 'x' .. '' );} ],
    'letters, one character each'           => [ 1, q{my @a = ( 'z' .. 'a' );} ],
    'letters and digits'                    => [ 1, q{my @a = ( 'a3' .. 'a1' );} ],
    'letters, in double quotes'             => [ 1, q{my @a = ( "z" .. "a" );} ],
    'letters, in q{}'                       => [ 1, q{my @a = ( q{z} .. q{a} );} ],
    q{upper case letters}                   => [ 1, q{my @a = ( q{Z} .. q{A} );} ],
    q{mixed case letters}                   => [ 1, q{my @a = ( q{Ab} .. q{Aa} );} ],
    q{a string that perl cannot increment}  => [ 1, q{my @a = ( q{~} .. q{!} );} ],
    'the three-dot form'                    => [ 1, q{my @a = ( 10 ... 1 );} ],
    'two ranges, reported twice'            => [ 2, q{my @a = ( 10 .. 1, 'z' .. 'a' );} ],
);

check_table(
    'an expression that counts down to a small number', $critic,
    'the tCMS sitemap index' => [
        1, q{foreach my $page ( $clamped .. 1 ) {   # empty unless $clamped <= 1; with 0 it gives (0,1)
    }}
    ],
    'down to 0'                => [ 1, q{for my $i ( $n .. 0 ) { print $i }} ],
    'the last index down to 0' => [ 1, q{for my $i ( $#a .. 0 ) { print $a[$i] }} ],
    'arithmetic down to 1'     => [ 1, q{my @a = ( $n - 1 .. 1 );} ],
    'a method call down to 1'  => [ 1, q{my @a = ( $self->count .. 1 );} ],
    'a call with parens, to 1' => [ 1, q{my @a = ( length($s) .. 1 );} ],
    'literal arithmetic, to 1' => [ 1, q{my @a = ( 10 - 5 .. 1 );} ],
);

check_table(
    'a range in list context', $critic,
    'an array slice'                      => [ 1, q{my @b = @a[ 5 .. 1 ];} ],
    'a hash slice'                        => [ 1, q{my @b = @h{ 'z' .. 'a' };} ],
    'a key and value slice'               => [ 1, q{my %b = %a[ 5 .. 1 ];} ],
    'a slice of a reference'              => [ 1, q{my @b = @{$r}[ 5 .. 1 ];} ],
    'a postfix slice'                     => [ 1, q{my @b = $r->@[ 5 .. 1 ];} ],
    'an anonymous array'                  => [ 1, q{my $r = [ 5 .. 1 ];} ],
    'the list of map'                     => [ 1, q{my @b = map { $_ * 2 } 5 .. 1;} ],
    'the list of grep, in parens'         => [ 1, q{my @b = grep( { $_ } 5 .. 1 );} ],
    'the block of map'                    => [ 1, q{my @b = map { $_ .. 1 } @a;} ],
    'the args of push'                    => [ 1, q{push @a, 5 .. 1;} ],
    'the args of a sub'                   => [ 1, q{foo( 5 .. 1 );} ],
    'the args of a sub, with no parens'   => [ 1, q{foo 5 .. 1;} ],
    'the args of a method'                => [ 1, q{$o->m( 5 .. 1 );} ],
    'the args of a code reference'        => [ 1, q{$f->( 5 .. 1 );} ],
    'return'                              => [ 1, q{sub f { return 5 .. 1 }} ],
    'return, in parens'                   => [ 1, q{sub f { return( 5 .. 1 ) }} ],
    'a list after other items'            => [ 1, q{my @a = ( 0, 5 .. 1 );} ],
    'an assignment to a list'             => [ 1, q{my ( $x, $y ) = ( 5 .. 1 );} ],
    'an assignment to an array reference' => [ 1, q{@$r = ( 5 .. 1 );} ],
    'an assignment to a hash'             => [ 1, q{my %h = map { $_ => 1 } 'z' .. 'a';} ],
    'a branch of a ternary'               => [ 1, q{my @a = $c ? 5 .. 1 : ();} ],
    'the other branch of a ternary'       => [ 1, q{my @a = $c ? () : 5 .. 1;} ],
    'nested parens'                       => [ 1, q{my @a = ( ( 5 .. 1 ) );} ],
    'a list slice'                        => [ 1, q{my $x = ( 5 .. 1 )[0];} ],
    'a for list after the loop variable'  => [ 1, q{foreach my $x ( 5 .. 1 ) { }} ],
    'a for list with no loop variable'    => [ 1, q{for ( 5 .. 1 ) { }} ],
    'a for modifier, in parens'           => [ 1, q{print for ( 5 .. 1 );} ],
    q{the args of a sub called with &}    => [ 1, q{&foo( 5 .. 1 );} ],
    q{a list op before an if modifier}    => [ 1, q{print 5 .. 1 if $x;} ],
    q{an assignment to a slice}           => [ 1, q{@a[ 0, 1 ] = ( 5 .. 1 );} ],
    q{an assignment to @{...}}            => [ 1, q{@{$r} = ( 5 .. 1 );} ],
    'a list op inside a condition'        => [ 1, q{if ( grep { $_ } 5 .. 1 ) { }} ],
);

check_table(
    'a range that counts up, or that perl cannot count', $critic,
    'numbers'                             => [ 0, q{my @a = 1 .. 10;} ],
    'equal numbers'                       => [ 0, q{my @a = 1 .. 1;} ],
    'negative numbers'                    => [ 0, q{my @a = ( -5 .. -1 );} ],
    'floats that truncate to one number'  => [ 0, q{my @a = ( 1.5 .. 1.2 );} ],
    'a float down to its integer'         => [ 0, q{my @a = ( 2.5 .. 2 );} ],
    'letters'                             => [ 0, q{my @a = ( 'a' .. 'e' );} ],
    'two-letter strings'                  => [ 0, q{my @a = ( 'aa' .. 'ab' );} ],
    'a shorter string than the right end' => [ 0, q{my @a = ( 'b' .. 'aa' );} ],
    'past z, into a longer string'        => [ 0, q{my @a = ( 'zz' .. 'aaa' );} ],
    'a string with a leading zero'        => [ 0, q{my @a = ( '09' .. '10' );} ],
    'upper case to lower case'            => [ 0, q{my @a = ( 'A' .. 'z' );} ],
    'the empty string to a letter'        => [ 0, q{my @a = ( '' .. 'c' );} ],
    'a version string'                    => [ 0, q{my @a = ( v1.2 .. 1 );} ],
    'from 0 to the last index'            => [ 0, q{my @a = ( 0 .. $#b );} ],
    'two expressions'                     => [ 0, q{my @a = ( $hi .. $lo );} ],
    'an expression to a large number'     => [ 0, q{my @a = ( $first .. 10 );} ],
    'an expression to a negative index'   => [ 0, q{my @b = @a[ -$n .. -1 ];} ],
    'an expression to -1'                 => [ 0, q{my @b = ( $n .. -1 );} ],
    'an expression to 2'                  => [ 0, q{my @a = ( $first .. 2 );} ],
    'a literal to an expression'          => [ 0, q{my @a = ( 10 .. $n );} ],
    'a literal to arithmetic'             => [ 0, q{my @a = ( 10 .. 1 + $n );} ],
    'a literal to arithmetic on literals' => [ 0, q{my @a = ( 10 .. 1 * 20 );} ],
    'the yada yada statement'             => [ 0, q{sub f { ... }} ],
    'the tCMS fix'                        => [ 0, q{foreach my $page ( reverse( 1 .. $clamped ) ) { }} ],
    q{an expression to a numeric string}  => [ 0, q{my @a = ( $n .. q{1} );} ],
    q{a word and a number}                => [ 0, q{my @a = ( q{a} .. 3 );} ],
    q{an interpolated string to a string} => [ 0, q{my @a = ( "$hi" .. "a" );} ],
);

check_table(
    'the flip-flop operator, in scalar context', $critic,
    'two patterns in an if'                  => [ 0, q{if ( /start/ .. /end/ ) { print }} ],
    'two numbers after an if modifier'       => [ 0, q{while (<$fh>) { print if 3 .. 5 }} ],
    'two numbers that count down, after if'  => [ 0, q{while (<$fh>) { print if 5 .. 3 }} ],
    'two numbers that count down, in an if'  => [ 0, q{if ( 10 .. 1 ) { print }} ],
    'in an unless'                           => [ 0, q{unless ( 10 .. 1 ) { print }} ],
    'in a while'                             => [ 0, q{while ( 10 .. 1 ) { print }} ],
    'after a while modifier'                 => [ 0, q{print while 10 .. 1;} ],
    'after an unless modifier'               => [ 0, q{print unless 10 .. 1;} ],
    'an elsif'                               => [ 0, q{if ($x) { } elsif ( 10 .. 1 ) { }} ],
    'an expression to a small number'        => [ 0, q{print if $n .. 1;} ],
    'an assignment to a scalar'              => [ 0, q{my $x = 10 .. 1;} ],
    'scalar()'                               => [ 0, q{my @a = scalar( 10 .. 1 );} ],
    'the condition of a ternary'             => [ 0, q{my @a = 10 .. 1 ? 'in' : 'out';} ],
    q{a group as the condition of a ternary} => [ 0, q{my @a = ( 10 .. 1 ) ? q{in} : q{out};} ],
    'beside &&, in an if'                    => [ 0, q{if ( $x && 10 .. 1 ) { }} ],
    'before and'                             => [ 0, q{10 .. 1 and print;} ],
    'after or'                               => [ 0, q{$x or 10 .. 1;} ],
    'a statement on its own'                 => [ 0, q{10 .. 1;} ],
    'an element of an array'                 => [ 0, q{my $x = $a[ 10 .. 1 ];} ],
    'an element of a hash'                   => [ 0, q{my $x = $h{ 'z' .. 'a' };} ],
    'an element through a reference'         => [ 0, q{my $x = $r->[ 10 .. 1 ];} ],
    'the three-dot form, in an if'           => [ 0, q{if ( /start/ ... /end/ ) { print }} ],
    'the three-dot form, after if'           => [ 0, q{print if 5 ... 3;} ],
    'the condition of a c-style for'         => [ 0, q{for ( my $i = 0; 10 .. 1; $i++ ) { }} ],
    'the block of grep'                      => [ 0, q{my @b = grep { 10 .. 1 } @a;} ],
);

check_table(
    'largest_end set to 10', critic_with( largest_end => 10 ),
    'an expression to 10' => [ 1, q{my @a = ( $first .. 10 );} ],
    'an expression to 11' => [ 0, q{my @a = ( $first .. 11 );} ],
);

check_table(
    'largest_end set to -1', critic_with( largest_end => -1 ),
    'the tCMS sitemap index'       => [ 0, q{foreach my $page ( $clamped .. 1 ) { }} ],
    'two literals that count down' => [ 1, q{my @a = 10 .. 1;} ],
);

sub message_of {
    my ($source)    = @_;
    my ($violation) = $critic->critique( \$source );
    return $violation ? ( $violation->description, $violation->explanation ) : ( q{}, q{} );
}

# The whole description, so that a change to what a message says is a change
# to this table.
my %said = (
    q{my @a = 10 .. 1;}                      => q{10 .. 1 gives an empty list},
    q{my @a = ( 'aa' .. 'b' );}              => q{'aa' .. 'b' gives an empty list},
    q{my @a = ( 'z' .. 'a' );}               => q{'z' .. 'a' gives only ('z')},
    q{my @a = ( 'a3' .. 'a1' );}             => q{'a3' .. 'a1' gives every string from 'a3' up to 'z9', and never reaches 'a1'},
    q{my @a = ( q{Ab} .. q{Aa} );}           => q{q{Ab} .. q{Aa} gives every string from 'Ab' up to 'Zz', and never reaches 'Aa'},
    q{my @a = ( q{~} .. q{!} );}             => q{q{~} .. q{!} gives only ('~')},
    q{foreach my $page ( $clamped .. 1 ) {}} => q{$clamped .. 1 gives an empty list when $clamped is more than 1},
);
my $EXPLANATION = q{Perl's .. counts only up, so a range whose left end is greater than its right end gives an empty list.  To count down, write reverse( LOW .. HIGH )};
foreach my $source ( sort keys %said ) {
    my ( $description, $explanation ) = message_of($source);
    is( $description, $said{$source}, "the message for $source" );
    is( $explanation, $EXPLANATION,   "the explanation for $source" );
}

is_deeply( [ warnings { $critic->critique( \q{my @a = ( 10 .. 1, 'z' .. 'a', $n .. 0 ); print if 5 .. 3;} ) } ], [], q{and no warnings on the way} );

done_testing();
