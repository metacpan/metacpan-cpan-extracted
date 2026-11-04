#!/usr/bin/env perl
use strict;
use warnings FATAL => 'all';

use re '/aa';

use 5.014;

=head1 NAME

t/main.t - which dereferences the policy reads as creating a level by accident, and where a no autovivification covers them

=head1 DESCRIPTION

Tables of snippets that must be reported and tables that must not.

A reported expression reads through an element: a subscript, a slice, or
C<keys> or C<values> of what an element refers to, such as C<$h{a}{b}>,
C<exists $h{a}{b}> or C<keys %{ $h{a} }>, where no C<no autovivification> with
the category it needs is in scope.  The edges are one level against two, the
spellings of a nested dereference, the contexts where perl vivifies on purpose
and the pragma does not stop it, and the lexical scope and the categories of
the pragma.

=cut

use Test::More;
use Test::Warnings qw{warnings};

use Perl::Critic;

# Loaded so that a syntax error in it is a compile failure here rather than
# Perl::Critic reporting no such policy.  Named as a string below, which is
# what ProhibitUnusedImports cannot see.
use Perl::Critic::Policy::Variables::RequireNoAutovivification;    ## no critic (ProhibitUnusedImports)

# -profile => q{} because Perl::Critic otherwise walks up from cwd looking for a
# .perlcriticrc, finds this dist's own, and runs every policy in it against
# these snippets.  The anchored long name because -single-policy is a pattern.
my $POLICY = '^Perl::Critic::Policy::Variables::RequireNoAutovivification$';

my $critic = Perl::Critic->new( -profile => q{}, '-single-policy' => $POLICY, -severity => 1 );

sub check_table {
    my ( $label, %cases ) = @_;
    foreach my $case ( sort keys %cases ) {
        my ( $expected, $source ) = @{ $cases{$case} };
        is( scalar $critic->critique( \$source ), $expected, "$label: $case" ) or diag $source;
    }
    return;
}

check_table(
    'a read through an element',
    'two hash levels'              => [ 1, q{my $x = $h{a}{b};} ],
    'an arrow between'             => [ 1, q{my $x = $h{a}->{b};} ],
    'a reference, then two levels' => [ 1, q{my $x = $r->{a}[0];} ],
    'an array element'             => [ 1, q{my $x = $x[0]{k};} ],
    'an element of @_'             => [ 1, q{my $x = $_[0]{a};} ],
    'a dollar cast'                => [ 1, q{my $x = $$r{a}{b};} ],
    'a block cast of an element'   => [ 1, q{my $x = ${ $h{a} }{b};} ],
    'a slice of an element'        => [ 1, q{my @x = @{ $h{a} }{qw(b c)};} ],
    'a postfix slice'              => [ 1, q{my @x = $h{a}->@{qw(b c)};} ],
    'after a method call'          => [ 1, q{my $x = $o->m->{a}{b};} ],
    'after a sub call'             => [ 1, q{my $x = f()->{a}{b};} ],
    'three levels, once'           => [ 1, q{my $x = $h{a}{b}{c};} ],
    'two in one statement'         => [ 2, q{my $x = $h{a}{b} . $h{c}{d};} ],
    'a cast of a nested read'      => [ 1, q{my $x = ${ $h{a}{b} }{c};} ],
    'an array of a nested read'    => [ 1, q{my @x = @{ $h{a}{b} };} ],
    'keys of an element'           => [ 1, q{my @k = keys %{ $h{a} };} ],
    'values of an element'         => [ 1, q{my @v = values %{ $r->{a} };} ],
    'keys of a postfix cast'       => [ 1, q{my @k = keys $h{a}->%*;} ],
    'keys in parens'               => [ 1, q{my @k = keys( %{ $h{a} } );} ],
    'a statement modifier'         => [ 1, q{f() if $h{a}{b};} ],
    'defined'                      => [ 1, q{if ( defined $h{a}{b} ) { f() }} ],
    'return'                       => [ 1, q{sub r { return $h{a}{b} }} ],
    'the last value of a sub'      => [ 1, q{sub r { $h{a}{b} }} ],
    'an operand inside sub args'   => [ 1, q{f( $y || $h{a}{b} );} ],
    'an anonymous array'           => [ 1, q{my $x = [ $h{a}{b} ];} ],
    'an anonymous hash'            => [ 1, q{my $x = { k => $h{a}{b} };} ],
    'print'                        => [ 1, q{print {$fh} $h{a}{b};} ],
    'join'                         => [ 1, q{my $x = join q{,}, $h{a}{b};} ],
    'a builtin in parens'          => [ 1, q{my $x = lc( $h{a}{b} );} ],
    'a match'                      => [ 1, q{my $x = $h{a}{b} =~ m/x/;} ],
    'a map block'                  => [ 1, q{my %s = map { $_->{a}{b} => 1 } @l;} ],
    'inside a subscript'           => [ 1, q{my $x = $h{ $g{a}{b} };} ],
    'pushed, not pushed onto'      => [ 1, q{push @a, $h{a}{b};} ],
    'exists'                       => [ 1, q{my $x = exists $h{a}{b};} ],
    'exists in parens'             => [ 1, q{my $x = exists( $h{a}{b} );} ],
    'delete'                       => [ 1, q{delete $h{a}{b};} ],
    'delete in parens'             => [ 1, q{delete( $r->{a}[0] );} ],
    'parens that group'            => [ 1, q{my @x = ( $h{a}{b} );} ],
    'grouped inside exists'        => [ 1, q{my $x = exists( ( $h{a}{b} ) );} ],
);

check_table(
    'one level, which creates nothing in a hash',
    'a hash element'          => [ 0, q{my $x = $h{a};} ],
    'through a reference'     => [ 0, q{my $x = $r->{a};} ],
    'an array element'        => [ 0, q{my $x = $r->[0];} ],
    'a dollar cast'           => [ 0, q{my $x = $$r{a};} ],
    'a block cast of a name'  => [ 0, q{my $x = ${$r}{a};} ],
    'a slice'                 => [ 0, q{my @x = @h{qw(a b)};} ],
    'an array of an element'  => [ 0, q{my @x = @{ $h{a} };} ],
    'keys of a name'          => [ 0, q{my @k = keys %{$r};} ],
    'exists'                  => [ 0, q{my $x = exists $h{a};} ],
    'delete'                  => [ 0, q{delete $r->{a};} ],
    'a call, then a level'    => [ 0, q{my $x = f()->{a};} ],
    'a method, then a level'  => [ 0, q{my $x = $o->m->{a};} ],
    'a list slice'            => [ 0, q{my $x = ( f() )[0]{k};} ],
    'a string, not parsed'    => [ 0, q{my $x = "$h{a}{b}";} ],
    'no dereference anywhere' => [ 0, q{my $x = 1 + 2;} ],
);

check_table(
    'an lvalue, which vivifies on purpose or which the pragma does not stop',
    'assigned'                  => [ 0, q{$h{a}{b} = 1;} ],
    'assigned with //='         => [ 0, q{$h{a}{b} //= 1;} ],
    'appended to'               => [ 0, q{$h{a}{b} .= q{x};} ],
    'incremented after'         => [ 0, q{$h{a}{b}++;} ],
    'incremented before'        => [ 0, q{++$h{a}{b};} ],
    'a list assignment'         => [ 0, q{( $h{a}{b} ) = f();} ],
    'an array assigned'         => [ 0, q{@{ $h{a}{b} } = ();} ],
    'pushed onto'               => [ 0, q{push @{ $h{a}{b} }, 1;} ],
    'one level, pushed onto'    => [ 0, q{push @{ $h{a} }, 1;} ],
    'popped'                    => [ 0, q{my $x = pop @{ $h{a}{b} };} ],
    'a reference taken'         => [ 0, q{my $ref = \$h{a}{b};} ],
    'local'                     => [ 0, q{local $h{a}{b} = 1;} ],
    'a sub argument'            => [ 0, q{f( $h{a}{b} );} ],
    'a sub argument, no parens' => [ 0, q{f $h{a}{b}, 1;} ],
    'a method argument'         => [ 0, q{$o->m( $h{a}{b} );} ],
    'a code reference argument' => [ 0, q{$code->( $h{a}{b} );} ],
    'an ampersand call'         => [ 0, q{&f( $h{a}{b} );} ],
    'the invocant'              => [ 0, q{$h{a}{b}->m;} ],
    'scalar as a sub argument'  => [ 0, q{f( scalar $h{a}{b} );} ],
    'a foreach list'            => [ 0, q{for my $e ( @{ $h{a}{b} } ) { f($e) }} ],
    'a foreach of one'          => [ 0, q{for ( $h{a}{b} ) { f($_) }} ],
    'a foreach modifier'        => [ 0, q{f($_) for @{ $h{a}{b} };} ],
    'a map list'                => [ 0, q{my @x = map { $_ } @{ $h{a}{b} };} ],
    'a grep list'               => [ 0, q{my @x = grep { $_ } $h{a}{b};} ],
    'a substitution'            => [ 0, q{$h{a}{b} =~ s/x//;} ],
    'a transliteration'         => [ 0, q{$h{a}{b} =~ tr/a-z//;} ],
    'chomp'                     => [ 0, q{chomp $h{a}{b};} ],
    'undef'                     => [ 0, q{undef $h{a}{b};} ],
    'sprintf'                   => [ 0, q{my $x = sprintf q{%s}, $h{a}{b};} ],
    'each of an element'        => [ 0, q{my ( $k, $v ) = each %{ $h{a} };} ],
);

check_table(
    'the lexical scope of the pragma',
    'in scope'                          => [ 0, q{no autovivification; my $x = $h{a}{b};} ],
    'exists in scope'                   => [ 0, q{no autovivification; my $x = exists $h{a}{b};} ],
    'delete in scope'                   => [ 0, q{no autovivification; delete $h{a}{b};} ],
    'keys in scope'                     => [ 0, q{no autovivification; my @k = keys %{ $h{a} };} ],
    'after the read'                    => [ 1, q{my $x = $h{a}{b}; no autovivification;} ],
    'in an inner block only'            => [ 1, q{{ no autovivification; } my $x = $h{a}{b};} ],
    'in the same inner block'           => [ 0, q{{ no autovivification; my $x = $h{a}{b}; }} ],
    'in the other sub'                  => [ 1, q{sub f { no autovivification; return $h{a}{b} } sub g { return $h{a}{b} }} ],
    'outside a sub'                     => [ 0, q{no autovivification; sub f { return $h{a}{b} }} ],
    'in a package block'                => [ 1, q{package Foo { no autovivification; } my $x = $h{a}{b};} ],
    'a block within the scope'          => [ 0, q{no autovivification; if ($c) { my $x = $h{a}{b}; }} ],
    'use autovivification after'        => [ 1, q{no autovivification; use autovivification; my $x = $h{a}{b};} ],
    'use autovivification inner'        => [ 1, q{no autovivification; { use autovivification; my $x = $h{a}{b}; }} ],
    'use autovivification inner, ended' => [ 0, q{no autovivification; { use autovivification; } my $x = $h{a}{b};} ],
    'require only'                      => [ 1, q{require autovivification; my $x = $h{a}{b};} ],
    'a version'                         => [ 0, q{no autovivification 0.18; my $x = $h{a}{b};} ],
);

check_table(
    'the categories of the pragma',
    'store only'                     => [ 1, q{no autovivification qw(store); my $x = $h{a}{b};} ],
    'fetch'                          => [ 0, q{no autovivification qw(fetch); my $x = $h{a}{b};} ],
    'fetch, for exists'              => [ 1, q{no autovivification qw(fetch); my $x = exists $h{a}{b};} ],
    'fetch, for keys'                => [ 0, q{no autovivification qw(fetch); my @k = keys %{ $h{a} };} ],
    'exists'                         => [ 0, q{no autovivification qw(exists); my $x = exists $h{a}{b};} ],
    'exists, for a fetch'            => [ 1, q{no autovivification qw(exists); my $x = $h{a}{b};} ],
    'delete'                         => [ 0, q{no autovivification qw(delete); delete $h{a}{b};} ],
    'delete, for exists'             => [ 1, q{no autovivification qw(delete); my $x = exists $h{a}{b};} ],
    'warn alone'                     => [ 1, q{no autovivification 'warn'; my $x = $h{a}{b};} ],
    'strict alone'                   => [ 1, q{no autovivification qw(strict); my $x = $h{a}{b};} ],
    'strict with fetch'              => [ 0, q{no autovivification strict => 'fetch'; my $x = $h{a}{b};} ],
    'warn with all three'            => [ 0, q{no autovivification warn => qw(fetch exists delete); delete $h{a}{b};} ],
    'empty parens'                   => [ 1, q{no autovivification (); my $x = $h{a}{b};} ],
    'empty qw'                       => [ 1, q{no autovivification qw(); my $x = $h{a}{b};} ],
    'in parens'                      => [ 0, q{no autovivification ('fetch'); my $x = $h{a}{b};} ],
    'double quotes'                  => [ 0, q{no autovivification "fetch"; my $x = $h{a}{b};} ],
    'interpolated, as no arguments'  => [ 0, q{no autovivification "$category"; my $x = $h{a}{b};} ],
    'grouped inside exists, covered' => [ 0, q{no autovivification qw(exists); my $x = exists( ( $h{a}{b} ) );} ],
    'added by a second'              => [ 0, q{no autovivification qw(fetch); no autovivification qw(exists); my $x = exists $h{a}{b};} ],
    'one taken away, the other'      => [ 0, q{no autovivification; use autovivification qw(fetch); my $x = exists $h{a}{b};} ],
    'one taken away, that one'       => [ 1, q{no autovivification; use autovivification qw(fetch); my $x = $h{a}{b};} ],
    'unreadable, as no arguments'    => [ 0, q{no autovivification @categories; my $x = $h{a}{b};} ],
    'unreadable use, as everything'  => [ 1, q{no autovivification; use autovivification @categories; my $x = $h{a}{b};} ],
);

# Each category is told which one it needs.  The wording of the explanation is
# the policy's to choose, so only the part that names the category is checked.
my %explains = (
    q{my $x = $h{a}{b};}        => q{fetch},
    q{my @k = keys %{ $h{a} };} => q{fetch},
    q{my $x = exists $h{a}{b};} => q{exists},
    q{delete $h{a}{b};}         => q{delete},
);
foreach my $source ( sort keys %explains ) {
    my ($violation) = $critic->critique( \$source );
    my $explanation = $violation ? $violation->explanation : q{};
    ok( index( $explanation, qq{'$explains{$source}'} ) >= 0, "the explanation of $source names $explains{$source}" ) or diag $explanation;
}

my $source = qq{my \$x = 1;\nmy \$y = \$h{a}{b};\n};
my ($violation) = $critic->critique( \$source );
is( $violation ? $violation->line_number : undef, 2, 'the violation is on the line of the read' );

my $equivalent_profile = "[Variables::RequireNoAutovivification]\nequivalent_modules = Bogus::Kit\n";
my $equivalent         = Perl::Critic->new( -profile => \$equivalent_profile, '-single-policy' => $POLICY, -severity => 1 );
my $kit_source         = q{use Bogus::Kit; my $x = exists $h{a}{b};};
is( scalar $equivalent->critique( \$kit_source ), 0, 'a module named by equivalent_modules counts as no autovivification' );
is( scalar $critic->critique( \$kit_source ),     1, 'and without the setting it does not' );

is( scalar( () = warnings { Perl::Critic->new( -profile => q{}, '-single-policy' => $POLICY ) } ), 0, 'nothing warns on construction' );

done_testing();
