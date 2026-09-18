use strict;
use warnings FATAL => 'all';

use re '/aa';

use 5.014;

=head1 NAME

t/main.t - which uses of defined and length the policy reports, and which it leaves alone

=head1 DESCRIPTION

Tables of snippets that must be reported and a table that must not.

A defined before a length on the same value is reported anywhere, and a length
whose value is only tested for truth is reported.  The cases that matter are
the edges of a boolean context: a length that is compared, returned, assigned,
passed to a call, or used in a branch of a ternary is a value, not a test.

=cut

use Test::More;
use Test::Warnings qw{warnings};

use Perl::Critic;

# Loaded so that a syntax error in it is a compile failure here rather than
# Perl::Critic reporting no such policy.  Named as a string below, which is
# what ProhibitUnusedImports cannot see.
use Perl::Critic::Policy::ValuesAndExpressions::ProhibitDefinedBeforeLength;    ## no critic (ProhibitUnusedImports)

# -profile => q{} because Perl::Critic otherwise walks up from cwd looking for a
# .perlcriticrc, finds this dist's own, and runs every policy in it against
# these snippets.  The anchored long name because -single-policy is a pattern.
my $POLICY = '^Perl::Critic::Policy::ValuesAndExpressions::ProhibitDefinedBeforeLength$';

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
    'a pair, anywhere',
    'scalar'                => [ 1, q{return unless defined $x && length $x;} ],
    'with parens'           => [ 1, q{die unless defined($x) and length($x);} ],
    'parens on one side'    => [ 1, q{f() if defined $x && length($x);} ],
    'hash element'          => [ 1, q{f() if defined $h->{k} && length $h->{k};} ],
    'bare hash element'     => [ 1, q{f() if defined $h{k} && length $h{k};} ],
    'nested subscripts'     => [ 1, q{f() if defined $h->{a}[0] && length $h->{a}[0];} ],
    'method call'           => [ 1, q{f() if defined $o->name && length $o->name;} ],
    'deref'                 => [ 1, q{f() if defined $$r && length $$r;} ],
    'topic in a grep'       => [ 1, q{my @t = grep { defined $_ && length $_ } @x;} ],
    'bare topic'            => [ 1, q{my @t = grep { defined && length } @x;} ],
    'in a condition'        => [ 1, q{if ( defined $x && length $x ) { f() }} ],
    'followed by more'      => [ 1, q{f() if defined $x && length $x && $y;} ],
    'in a ternary'          => [ 1, q{my $v = defined $x && length $x ? 1 : 0;} ],
    'as a value'            => [ 1, q{my $ok = defined $x && length $x;} ],
    'length compared'       => [ 1, q{return if defined $uri && length $uri > 2048;} ],
    'length in arithmetic'  => [ 1, q{my $n = defined $x && length $x + 1;} ],
    'negated'               => [ 1, q{next if !defined $p || !length $p;} ],
    'negated with not'      => [ 1, q{next if not defined $p or not length $p;} ],
    'spacing does not hide' => [ 1, q{f() if defined $h->{ k } && length $h->{k};} ],
    'two in one statement'  => [ 2, q{f() if defined $x && length $x && defined $y && length $y;} ],
);

check_table(
    'length in a boolean context',
    'unless modifier'      => [ 1, q{return unless length $uri;} ],
    'if modifier'          => [ 1, q{f() if length $x;} ],
    'while modifier'       => [ 1, q{f() while length $x;} ],
    'if block'             => [ 1, q{if ( length $x ) { f() }} ],
    'unless block'         => [ 1, q{unless ( length $x ) { f() }} ],
    'elsif'                => [ 1, q{if ($y) { f() } elsif ( length $x ) { g() }} ],
    'while block'          => [ 1, q{while ( length $x ) { f() }} ],
    'with parens'          => [ 1, q{f() if length($x);} ],
    'negated'              => [ 1, q{f() if !length $x;} ],
    'negated with not'     => [ 1, q{f() if not length $x;} ],
    'negated as a value'   => [ 1, q{my $empty = !length $x;} ],
    'ternary condition'    => [ 1, q{my $v = length $x ? $x : undef;} ],
    'parenthesised cond'   => [ 1, q{my $v = ( length $x ) ? $x : undef;} ],
    'in a chain'           => [ 1, q{f() if $y && length $x;} ],
    'first in a chain'     => [ 1, q{f() if length $x && $y;} ],
    'or chain'             => [ 1, q{f() unless $y || length $x;} ],
    'in a chain in a cond' => [ 1, q{if ( $y && length $x ) { f() }} ],
    'grep block'           => [ 1, q{my @t = grep { length } @x;} ],
    'grep with topic'      => [ 1, q{my @t = grep { length $_ } @x;} ],
    'first block'          => [ 1, q{my $t = first { length $_->{name} } @x;} ],
    'a call as operand'    => [ 1, q{f() if length g($x);} ],
    'a method as operand'  => [ 1, q{f() if length $o->name;} ],
    'two in one condition' => [ 2, q{f() if length $x && length $y;} ],
);

check_table(
    'left alone',
    'the value alone'        => [ 0, q{return unless $uri;} ],
    'shaped, then compared'  => [ 0, q{$uri //= q{}; return if length $uri > 2048;} ],
    'length compared'        => [ 0, q{f() if length $x > 3;} ],
    'compared in a block'    => [ 0, q{if ( length($x) > 666 ) { f() }} ],
    'length in arithmetic'   => [ 0, q{my $n = length $x + 1;} ],
    'assigned'               => [ 0, q{my $size = length $x;} ],
    'returned'               => [ 0, q{return length $x;} ],
    'returned in a chain'    => [ 0, q{return length $x && $y;} ],
    'an argument'            => [ 0, q{f( length $x );} ],
    'an argument in a cond'  => [ 0, q{g() if f( length $x );} ],
    'printed'                => [ 0, q{print length $x if $y;} ],
    'a ternary branch'       => [ 0, q{my $v = $y ? length $x : 0;} ],
    'two values'             => [ 0, q{my $n = defined $x && length $y;} ],
    'different elements'     => [ 0, q{my $n = defined $h->{a} && length $h->{b};} ],
    'not equal empty'        => [ 0, q{f() if defined $x && $x ne q{};} ],
    'map block'              => [ 0, q{my @n = map { length } @x;} ],
    'not the last in a grep' => [ 0, q{my @t = grep { my $n = length $_; $n > 3 } @x;} ],
    'a method named length'  => [ 0, q{f() if $o->length;} ],
    'a hash key'             => [ 0, q{f() if $h{length};} ],
    'a method named define'  => [ 0, q{my $n = $o->defined && $x;} ],
    'defined of a call'      => [ 0, q{my $n = defined g($x) && length g($y);} ],
);

is( scalar( () = warnings { Perl::Critic->new( -profile => q{}, '-single-policy' => $POLICY ) } ), 0, 'nothing warns on construction' );

done_testing();
