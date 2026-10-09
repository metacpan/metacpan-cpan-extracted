#!/usr/bin/env perl
use strict;
use warnings FATAL => 'all';

use re '/aa';

use 5.014;

=head1 NAME

t/main.t - which calls the policy reads as a grep used for truth or for its
first element, one call away, and which it leaves alone

=head1 DESCRIPTION

Tables of snippets that must be reported and a table that must not.

A reported call is of a sub in the same file that returns a C<grep>, and the
caller uses only whether the result is empty, or only its first element.  The
edges are the ways of returning a C<grep>, the ways of testing for truth, and
the calls that look the same and are not.

=cut

use Test::More;
use File::Path ();
use File::Temp ();
use PPI        ();
use Perl::Critic;
use Perl::Critic::Distribution ();

# Loaded so that a syntax error in it is a compile failure here rather than
# Perl::Critic reporting no such policy.
use Perl::Critic::Policy::BuiltinFunctions::ProhibitIndirectBooleanGrep ();

# -profile => q{} because Perl::Critic otherwise walks up from cwd looking for a
# .perlcriticrc, finds this dist's own, and runs every policy in it against
# these snippets.  The anchored long name because -single-policy is a pattern.
my $POLICY = '^Perl::Critic::Policy::BuiltinFunctions::ProhibitIndirectBooleanGrep$';

my $critic = Perl::Critic->new( -profile => q{}, '-single-policy' => $POLICY, -severity => 1 );

my $check_table = sub {
    my ( $label, %cases ) = @_;
    foreach my $case ( sort keys %cases ) {
        my ( $expected, $source ) = @{ $cases{$case} };
        is( scalar $critic->critique( \$source ), $expected, "$label: $case" ) or diag $source;
    }
    return;
};

my $SUB = q{sub hits { return grep { $_ > 1 } @_ } };

$check_table->(
    'a sub that returns a grep',
    'with return'               => [ 1, $SUB . q{if ( hits(@x) ) { 1 }} ],
    'as its last statement'     => [ 1, q{sub hits { grep { $_ > 1 } @_ } if ( hits(@x) ) { 1 }} ],
    'a lexical sub'             => [ 1, q{my sub hits { return grep { $_ > 1 } @_ } if ( hits(@x) ) { 1 }} ],
    'a state sub'               => [ 1, q{state sub hits { return grep { $_ > 1 } @_ } if ( hits(@x) ) { 1 }} ],
    'on one of its paths'       => [ 1, q{sub hits { return () unless @_; return grep { $_ > 1 } @_ } if ( hits(@x) ) { 1 }} ],
    'called before its body'    => [ 1, q{if ( hits(@x) ) { 1 } sub hits { return grep { $_ > 1 } @_ }} ],
    'called without parens'     => [ 1, $SUB . q{if ( hits ) { 1 }} ],
    'called once in each place' => [ 2, $SUB . q{if ( hits(@x) ) { 1 } die unless hits(@y);} ],
);

$check_table->(
    'tested for truth',
    'the condition of an if'      => [ 1, $SUB . q{if ( hits(@x) ) { 1 }} ],
    'of an unless'                => [ 1, $SUB . q{unless ( hits(@x) ) { 1 }} ],
    'of an elsif'                 => [ 1, $SUB . q{if ($y) { 1 } elsif ( hits(@x) ) { 2 }} ],
    'of a while'                  => [ 1, $SUB . q{while ( hits(@x) ) { shift @x }} ],
    'negated'                     => [ 1, $SUB . q{my $none = !hits(@x);} ],
    'negated with not'            => [ 1, $SUB . q{my $none = not hits(@x);} ],
    'in a postfix if'             => [ 1, $SUB . q{print 'yes' if hits(@x);} ],
    'in a postfix unless'         => [ 1, $SUB . q{print 'no' unless hits(@x);} ],
    'the condition of a ternary'  => [ 1, $SUB . q{my $say = hits(@x) ? 'yes' : 'no';} ],
    'a ternary that is returned'  => [ 1, $SUB . q{sub say { return hits(@x) ? 'yes' : 'no' }} ],
    'a postfix if on a new line'  => [ 1, $SUB . qq{print 'a long line', 'that goes on'\n    if hits(\@x);} ],
    'one side of && in an if'     => [ 1, $SUB . q{if ( $y && hits(@x) ) { 1 }} ],
    'one side of or in an unless' => [ 1, $SUB . q{unless ( hits(@x) or $y ) { 1 }} ],
    'the left of or, alone'       => [ 1, $SUB . q{hits(@x) or die;} ],
    'grep through a lexical sub'  => [ 1, q{my sub left { return grep { !$out{$_} } @found } while ( left() ) { last }} ],
);

$check_table->(
    'its first element',
    'one variable in a list' => [ 1, $SUB . q{my ($first) = hits(@x);} ],
    'assigned, not declared' => [ 1, $SUB . q{($first) = hits(@x);} ],
);

$check_table->(
    'allowed',
    'in list context'               => [ 0, $SUB . q{my @all = hits(@x);} ],
    'looped over'                   => [ 0, $SUB . q{foreach my $h ( hits(@x) ) { print $h }} ],
    'counted'                       => [ 0, $SUB . q{my $count = hits(@x);} ],
    'counted with scalar'           => [ 0, $SUB . q{if ( scalar( hits(@x) ) > 2 ) { 1 }} ],
    'compared'                      => [ 0, $SUB . q{if ( hits(@x) > 2 ) { 1 }} ],
    'two variables in a list'       => [ 0, $SUB . q{my ( $a1, $a2 ) = hits(@x);} ],
    'a sub that returns a list'     => [ 0, q{sub hits { return @_ } if ( hits(@x) ) { 1 }} ],
    'a sub that returns any'        => [ 0, q{sub hits { return any { $_ > 1 } @_ } if ( hits(@x) ) { 1 }} ],
    'a sub that asks wantarray'     => [ 0, q{sub hits { return wantarray ? grep { $_ } @_ : 0 } if ( hits(@x) ) { 1 }} ],
    'a grep through a variable'     => [ 0, q{sub hits { my @h = grep { $_ } @_; return @h } if ( hits(@x) ) { 1 }} ],
    'a grep inside an inner sub'    => [ 0, q{sub hits { my $f = sub { return grep { $_ } @_ }; return 1 } if ( hits(@x) ) { 1 }} ],
    'a grep in the block of a grep' => [ 0, q{sub hits { return scalar grep { $_ } @_ } if ( hits(@x) ) { 1 }} ],
    'a sub defined elsewhere'       => [ 0, q{if ( hits(@x) ) { 1 }} ],
    'the right of or, alone'        => [ 0, $SUB . q{$y or hits(@x);} ],
    'before a postfix if'           => [ 0, $SUB . q{print hits(@x) if $y;} ],
    'before a postfix if, wrapped'  => [ 0, $SUB . qq{print \$y || hits(\@x)\n    if \$z;} ],
);

$check_table->(
    'the same spelling, another thing',
    'a method'                => [ 0, $SUB . q{if ( $obj->hits(@x) ) { 1 }} ],
    'a hash key'              => [ 0, $SUB . q{if ( $h{hits} ) { 1 }} ],
    'the left of a fat comma' => [ 0, $SUB . q{my %h = ( hits => 1 ); if ( $h{x} ) { 1 }} ],
    'the name of the sub'     => [ 0, $SUB ],
);

# The package of a call is how a bare name from another file is matched.
{
    my $ppi      = PPI::Document->new( \"package A;\nfoo();\npackage B { bar() }\nbaz();\npackage C;\nqux();\n" );
    my %word     = map { ( $_->content => $_ ) } @{ $ppi->find('PPI::Token::Word') };
    my $packages = Perl::Critic::Policy::BuiltinFunctions::ProhibitIndirectBooleanGrep::packages_in($ppi);
    my $at       = sub { return Perl::Critic::Policy::BuiltinFunctions::ProhibitIndirectBooleanGrep::package_at( $word{ $_[0] }, $packages ) };

    is( $at->('foo'), 'A', 'package_at: after a package statement' );
    is( $at->('bar'), 'B', 'package_at: inside the block of a package' );
    is( $at->('baz'), 'A', 'package_at: after that block, the statement before it again' );
    is( $at->('qux'), 'C', 'package_at: after a later statement' );
}

# A sub in one file of a distribution, and calls of it in another.  Through
# Perl::Critic::Distribution, which needs files on disk under lib/.
{
    local %Perl::Critic::Distribution::FOR;
    local $ENV{XDG_CACHE_HOME} = File::Temp::tempdir( CLEANUP => 1 );

    my $root = File::Temp::tempdir( CLEANUP => 1 );
    File::Path::make_path("$root/lib/Some");
    my %files = (
        'dist.ini'          => "name = Some\n",
        'lib/Some.pm'       => "package Some;\nsub hits { return grep { \$_ > 1 } \@_ }\nsub all { return \@_ }\n1;\n",
        'lib/Some/Same.pm'  => "package Some;\nsub check { return hits(\@_) ? 1 : 0 }\n1;\n",
        'lib/Some/Other.pm' => "package Some::Other;\nsub one { return Some::hits(\@_) ? 1 : 0 }\nsub two { return hits(\@_) ? 1 : 0 }\nsub three { my (\$x) = Some::hits(\@_); return \$x }\n1;\n",
        'lib/Some/Lists.pm' => "package Some::Lists;\nsub one { my \@h = Some::hits(\@_); return Some::all(\@_) ? 1 : 0 }\nsub two { return Some->hits(\@_) ? 1 : 0 }\n1;\n",
    );
    foreach my $name ( keys %files ) {
        open( my $fh, '>', "$root/$name" ) or die "$root/$name: $!";
        print {$fh} $files{$name};
        close($fh) or die "$root/$name: $!";
    }

    my $found = sub {
        my ($file) = @_;
        return [ map { $_->line_number . q{ } . $_->description } $critic->critique("$root/$file") ];
    };

    is_deeply( $found->('lib/Some/Same.pm'), ['2 A sub that returns a grep, tested for truth'], 'another file: a bare call in the package of the sub' );
    is_deeply(
        $found->('lib/Some/Other.pm'),
        [ '2 A sub that returns a grep, tested for truth', '4 A sub that returns a grep, for its first element' ],
        'another file: a qualified call, and not a bare one from another package, whose import is not known'
    );
    is_deeply( $found->('lib/Some/Lists.pm'), [], 'another file: a list, a sub that returns a list, and a method' );
}

done_testing;
