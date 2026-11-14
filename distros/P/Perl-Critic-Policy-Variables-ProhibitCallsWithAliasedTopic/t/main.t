#!/usr/bin/env perl
use strict;
use warnings FATAL => 'all';

use re '/aa';

use 5.014;

=head1 NAME

t/main.t - which calls the policy reads as made while $_ is an alias to the caller's data

=head1 DESCRIPTION

Tables of snippets that must be reported and tables that must not.

A reported snippet calls a sub or method in the block of a list function that
aliases C<$_>, with no C<local $_> before the call, or in a statement with a
postfix C<for>.  The edges are what counts as a call, which list functions
alias C<$_>, where C<$_> belongs to some other construct inside the block,
where a C<local $_> covers a call, and which subs are left to
C<ControlStructures::ProhibitMutatingListFunctionsStricter>.

=cut

use Test::More;
use Test::Warnings qw{warnings};
use File::Path     ();
use File::Temp     ();

use Perl::Critic;
use Perl::Critic::Distribution ();

# Loaded so that a syntax error in it is a compile failure here rather than
# Perl::Critic reporting no such policy.  Named as a string below, which is
# what ProhibitUnusedImports cannot see.
use Perl::Critic::Policy::Variables::ProhibitCallsWithAliasedTopic ();    ## no critic (ProhibitUnusedImports)

# -profile => q{} because Perl::Critic otherwise walks up from cwd looking for a
# .perlcriticrc, finds this dist's own, and runs every policy in it against
# these snippets.  The anchored long name because -single-policy is a pattern.
my $POLICY = '^Perl::Critic::Policy::Variables::ProhibitCallsWithAliasedTopic$';

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
    'a call in a list function block',
    'a sub'                      => [ 1, q{my @r = map { f($_) } @x;} ],
    'a sub without parens'       => [ 1, q{my @r = map { f } @x;} ],
    'a qualified sub'            => [ 1, q{my @r = map { Some::Where::f($_) } @x;} ],
    'a method of $_'             => [ 1, q{my @r = grep { $_->is_ok } @x;} ],
    'a class method'             => [ 1, q{my @r = map { Some::Class->new($_) } @x;} ],
    'a dynamic method'           => [ 1, q{my @r = map { $o->$name($_) } @x;} ],
    'a code reference'           => [ 1, q{my @r = map { $code->($_) } @x;} ],
    'a code reference in a hash' => [ 1, q{my @r = map { $dispatch{$_}->() } @x;} ],
    'an ampersand cast'          => [ 1, q{my @r = map { &$code } @x;} ],
    'an ampersand sub'           => [ 1, q{my @r = map { &f } @x;} ],
    'a constant, which is a sub' => [ 1, q{my @r = map { $_ * PI } @x;} ],
    'in a condition'             => [ 1, q{my @r = grep { f($_) && $_ } @x;} ],
    'in a statement modifier'    => [ 1, q{my @r = map { $n++ if f(); $_ } @x;} ],
    'in a nested for my loop'    => [ 1, q{my @r = map { for my $y (@y) { f($y) } $_ } @x;} ],
    'in a nested if block'       => [ 1, q{my @r = map { if ($_) { f() } $_ } @x;} ],
    'the argument of a builtin'  => [ 1, q{my @r = map { lc f($_) } @x;} ],
    'two calls, once'            => [ 1, q{my @r = map { f($_) . g($_) } @x;} ],
    'a copy is not a fix'        => [ 1, q{my @r = map { my $y = $_; f($y) } @x;} ],
    'a sub defined nowhere here' => [ 1, q{my @r = map { trim() } @lines;} ],
    'a method named like a sub'  => [ 1, q{sub trim { return } my @r = map { $_->trim } @lines;} ],
    'map EXPR'                   => [ 1, q{my @r = map f($_), @x;} ],
    'grep EXPR'                  => [ 1, q{my @r = grep f($_), @x;} ],
    'List::Util::first'          => [ 1, q{my $r = List::Util::first { f($_) } @x;} ],
    'first, imported'            => [ 1, q{my $r = first { f($_) } @x;} ],
    'any, imported'              => [ 1, q{my $r = any { f($_) } @x;} ],
    'all, imported'              => [ 1, q{my $r = all { f($_) } @x;} ],
    'none, imported'             => [ 1, q{my $r = none { f($_) } @x;} ],
    'notall, imported'           => [ 1, q{my $r = notall { f($_) } @x;} ],
    'List::MoreUtils::firstval'  => [ 1, q{my $r = List::MoreUtils::firstval { f($_) } @x;} ],
    'List::SomeUtils::part'      => [ 1, q{my @r = List::SomeUtils::part { f($_) } @x;} ],
    'firstidx, imported'         => [ 1, q{my $r = firstidx { f($_) } @x;} ],
    'insert_after, imported'     => [ 1, q{insert_after { f($_) } $v => @x;} ],
    'max_by, imported'           => [ 1, q{my $r = max_by { f($_) } @x;} ],
    'List::UtilsBy::min_by'      => [ 1, q{my $r = List::UtilsBy::min_by { f($_) } @x;} ],
    'a call before the local'    => [ 1, q{my @r = map { f(); local ($_) = $_; g() } @x;} ],
    'a call in the local'        => [ 1, q{my @r = map { local ($_) = f($_); $_ } @x;} ],
    'a local in an inner block'  => [ 1, q{my @r = map { if ($y) { local $_ = 1 } f() } @x;} ],
    'a local of something else'  => [ 1, q{my @r = map { local $/; f() } @x;} ],
    'a call in an inner list'    => [ 1, q{my @r = map { for my $y ( f() ) { } $_ } @x;} ],
    'the list of an inner loop'  => [ 1, q{my @r = map { for ( f() ) { } $_ } @x;} ],
);

check_table(
    'not a call, or not while $_ is an alias',
    'builtins'                                        => [ 0, q{my @r = map { lc } grep { defined && length } @x;} ],
    'a builtin through CORE::'                        => [ 0, q{my @r = map { CORE::lc($_) } @x;} ],
    'no call at all'                                  => [ 0, q{my @r = map { $_ * 2 } @x;} ],
    'a hash key'                                      => [ 0, q{my @r = map { $h{key} } @x;} ],
    'a fat comma key'                                 => [ 0, q{my @r = map { { name => $_ } } @x;} ],
    'a subscript after an arrow'                      => [ 0, q{my @r = map { $_->{name} } @x;} ],
    'a method of UNIVERSAL'                           => [ 0, q{my @r = grep { $_->isa('Some::Class') && $_->can('m') } @x;} ],
    'local ($_) = $_ first'                           => [ 0, q{my @r = map { local ($_) = $_; f() } @x;} ],
    'local $_ = $_ first'                             => [ 0, q{my @r = map { local $_ = $_; f() } @x;} ],
    'a copy and local $_'                             => [ 0, q{my @r = map { my $y = $_; local $_; f($y) } @x;} ],
    'a sub of this file'                              => [ 0, q{sub f { return 1 } my @r = map { f($_) } @x;} ],
    'a sub of this file, later'                       => [ 0, q{my @r = map { f($_) } @x; sub f { return 1 }} ],
    'a qualified sub of this file'                    => [ 0, q{package Here; sub f { return 1 } my @r = map { Here::f($_) } @x;} ],
    'a lexical sub'                                   => [ 0, q{my sub f { return 1 } my @r = map { f($_) } @x;} ],
    'in an anonymous sub'                             => [ 0, q{my @r = map { my $s = $_; sub { f($s) } } @x;} ],
    'in an anonymous sub with a signature'            => [ 0, q{my @r = map { my $s = $_; sub ($y) { f($y) } } @x;} ],
    'in an inner topic loop'                          => [ 0, q{my @r = map { for (@y) { f() } $_ } @x;} ],
    'in the list, outside'                            => [ 0, q{my @r = map { $_ } f(@x);} ],
    'the list of map EXPR'                            => [ 0, q{my @r = map lc, f(@x);} ],
    'map EXPR of a builtin'                           => [ 0, q{my @r = map lc($_), @x;} ],
    'sort, which does not set $_'                     => [ 0, q{my @r = sort { f($a) <=> f($b) } @x;} ],
    'reduce, which sets $a and $b'                    => [ 0, q{my $r = reduce { f($a, $b) } @x;} ],
    'sort_by, which copies'                           => [ 0, q{my @r = sort_by { f($_) } @x;} ],
    'apply, which copies'                             => [ 0, q{my @r = apply { f($_) } @x;} ],
    'insert_after_string'                             => [ 0, q{insert_after_string 'a', $v => @x;} ],
    'a sub named like a list function, with no block' => [ 0, q{my $r = first(@x);} ],
    'a call outside any block'                        => [ 0, q{f($_);} ],
);

check_table(
    'a call in a statement with a postfix for',
    'a sub'                     => [ 1, q{f() for @x;} ],
    'foreach'                   => [ 1, q{f() foreach @x;} ],
    'a method of $_'            => [ 1, q{$_->save for @objects;} ],
    'the argument of a builtin' => [ 1, q{push @r, $_->name for @objects;} ],
    'a sub of this file'        => [ 1, q{sub f { return 1 } f() for @x;} ],
    'a do block'                => [ 1, q{do { f() } for @x;} ],
    'inside a list function'    => [ 1, q{my @r = map { f() for @y; $_ } @x;} ],
    'a local is no cover'       => [ 1, q{do { local ($_) = $_; f() } for @x;} ],
);

check_table(
    'a postfix for with no call, or another statement',
    'builtins'             => [ 0, q{print for @x;} ],
    'a substitution'       => [ 0, q{s/\s+\z// for @x;} ],
    'chomp'                => [ 0, q{chomp for @x;} ],
    'a call in the list'   => [ 0, q{print for f(@x);} ],
    'a postfix if'         => [ 0, q{f() if $x;} ],
    'a postfix while'      => [ 0, q{f() while $x;} ],
    'a block for, no name' => [ 0, q{for (@x) { f() }} ],
    'a block for my'       => [ 0, q{for my $y (@x) { f($y) }} ],
    'a C-style for'        => [ 0, q{for ( my $i = 0; $i < 9; $i++ ) { f($i) }} ],
);

check_table(
    'each construct reports its own calls once',
    'a map in a map'            => [ 2, q{my @r = map { g(); map { f() } @y } @x;} ],
    'a map in a postfix for'    => [ 1, q{print map { f() } @y for @x;} ],
    'a postfix for, then a map' => [ 2, q{f() for @x; my @r = map { g() } @x;} ],
);

my ($first) = $critic->critique( \qq{my \@r = map {\n    lc \$_;\n    f(\$_);\n} \@x;\n} );
is( $first ? $first->line_number : undef, 3, 'the violation is on the line of the call' );

my %explains = (
    q{my @r = map { f($_) } @x;} => q{local ($_) = $_;},
    q{f() for @x;}               => q{for my},
);
foreach my $source ( sort keys %explains ) {
    my ($violation) = $critic->critique( \$source );
    my $explanation = $violation ? $violation->explanation : q{};
    ok( index( $explanation, $explains{$source} ) >= 0, "the explanation of $source says $explains{$source}" ) or diag $explanation;
}

my $allow_profile = "[Variables::ProhibitCallsWithAliasedTopic]\nallow = f Some::g name\n";
my $allowing      = Perl::Critic->new( -profile => \$allow_profile, '-single-policy' => $POLICY, -severity => 1 );
foreach my $source ( q{my @r = map { f($_) } @x;}, q{my @r = map { Some::g($_) } @x;}, q{my @r = map { $_->name } @x;}, q{$_->name for @x;} ) {
    is( scalar $allowing->critique( \$source ), 0, "a name in allow: $source" );
}
is( scalar $allowing->critique( \q{my @r = map { g($_) } @x;} ), 1, 'allow names Some::g, which is not g' );

my $funcs_profile = "[Variables::ProhibitCallsWithAliasedTopic]\nadd_list_funcs = each_item\n";
my $funcs         = Perl::Critic->new( -profile => \$funcs_profile, '-single-policy' => $POLICY, -severity => 1 );
is( scalar $funcs->critique( \q{each_item { f($_) } @x;} ),   1, 'a function in add_list_funcs' );
is( scalar $funcs->critique( \q{my @r = map { f($_) } @x;} ), 1, 'and the default list functions as well' );

# A sub in one file of a distribution, and calls of it in another.  Through
# Perl::Critic::Distribution, which needs files on disk under lib/.
{
    local %Perl::Critic::Distribution::FOR;
    local $ENV{XDG_CACHE_HOME} = File::Temp::tempdir( CLEANUP => 1 );

    my $root = File::Temp::tempdir( CLEANUP => 1 );
    File::Path::make_path("$root/lib/Some");
    my %files = (
        'dist.ini'         => "name = Some\n",
        'lib/Some.pm'      => "package Some;\nsub trim { s/\\s+\\z//; return }\n1;\n",
        'lib/Some/Uses.pm' => join(
            q{},
            "package Some::Uses;\n",
            "sub one { my \@t = map { Some::trim(); \$_ } \@_; return \@t }\n",
            "sub two { my \@t = map { trim(); \$_ } \@_; return \@t }\n",
            "sub three { my \@t = map { elsewhere(); \$_ } \@_; return \@t }\n",
            "sub four { Some::trim() for \@_; return }\n",
            "1;\n"
        ),
    );
    foreach my $name ( keys %files ) {
        open( my $fh, '>', "$root/$name" ) or die "$root/$name: $!";
        print {$fh} $files{$name};
        close($fh) or die "$root/$name: $!";
    }

    my @lines = map { $_->line_number } $critic->critique("$root/lib/Some/Uses.pm");
    is_deeply( \@lines, [ 4, 5 ], 'another file: a sub of the distribution is left alone in a block, a sub of none is not, and a postfix for counts both' );
}

# The same snippets under ProhibitMutatingListFunctionsStricter as well: what
# that policy reports, this one does not.
SKIP: {
    my $stricter = 'Perl::Critic::Policy::ControlStructures::ProhibitMutatingListFunctionsStricter';
    skip "$stricter is not installed", 2 if !eval "require $stricter; 1";    ## no critic (ProhibitStringyEval)

    my $both_profile = "[Variables::ProhibitCallsWithAliasedTopic]\n[ControlStructures::ProhibitMutatingListFunctionsStricter]\n";
    my $both         = Perl::Critic->new( -profile => \$both_profile, -only => 1, -severity => 1 );
    my @seen         = map { $_->policy } $both->critique( \q{sub trim { s/\s+\z//; return } my @t = map { trim(); $_ } @lines;} );
    is_deeply( \@seen, [$stricter], 'a sub of this file that changes $_ is reported by that policy alone' );
    @seen = map { $_->policy } $both->critique( \q{my @t = map { trim(); $_ } @lines;} );
    is_deeply( \@seen, ['Perl::Critic::Policy::Variables::ProhibitCallsWithAliasedTopic'], 'a sub that neither can read is reported by this one alone' );
}

is( scalar( () = warnings { Perl::Critic->new( -profile => q{}, '-single-policy' => $POLICY ) } ), 0, 'nothing warns on construction' );

done_testing();
