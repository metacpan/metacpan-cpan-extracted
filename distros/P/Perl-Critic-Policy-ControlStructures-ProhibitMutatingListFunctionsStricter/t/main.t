#!/usr/bin/env perl
use strict;
use warnings FATAL => 'all';

use re '/aa';

use 5.014;

=head1 NAME

t/main.t - which list function blocks the policy reads as changing their
source list, directly or through a sub, and which it leaves alone

=head1 DESCRIPTION

Tables of snippets that must be reported and a table that must not.

A block is reported when it changes C<$_> itself, as the core policy reports,
or when it calls a sub that changes C<$_> without making it its own.  The edges
are the ways a sub can change C<$_>, and the ways it can have a C<$_> of its own.

With C<report_unresolved_calls>, a block is also reported when it calls a sub or
method that the policy cannot read, and with C<report_postfix_for_calls>, so is
a statement with a postfix C<for>.  The edges there are what counts as a call,
which list functions alias C<$_>, where C<$_> belongs to some other construct
inside the block, and where a C<local $_> covers a call.

=cut

use Test::More;
use File::Path ();
use File::Temp ();
use Perl::Critic;
use Perl::Critic::Distribution ();

# Loaded so that a syntax error in it is a compile failure here rather than
# Perl::Critic reporting no such policy.  Named as a string below, which is
# what ProhibitUnusedImports cannot see.
use Perl::Critic::Policy::ControlStructures::ProhibitMutatingListFunctionsStricter ();    ## no critic (ProhibitUnusedImports)

# -profile => q{} because Perl::Critic otherwise walks up from cwd looking for a
# .perlcriticrc, finds this dist's own, and runs every policy in it against
# these snippets.  The anchored long name because -single-policy is a pattern.
my $POLICY = '^Perl::Critic::Policy::ControlStructures::ProhibitMutatingListFunctionsStricter$';

my $critic = Perl::Critic->new( -profile => q{}, '-single-policy' => $POLICY, -severity => 1 );

my $check_table = sub {
    my ( $label, %cases ) = @_;
    foreach my $case ( sort keys %cases ) {
        my ( $expected, $source ) = @{ $cases{$case} };
        is( scalar $critic->critique( \$source ), $expected, "$label: $case" ) or diag $source;
    }
    return;
};

my $TRIM = q{sub trim { s/\s+\z//; return } };

$check_table->(
    'what the core policy reports',
    'a substitution in map'      => [ 1, q{my @t = map { s/x//; $_ } @lines;} ],
    'an assignment in grep'      => [ 1, q{my @t = grep { $_ = 1 } @lines;} ],
    'chomp in List::Util::first' => [ 1, q{my $t = List::Util::first { chomp } @lines;} ],
);

# The core policy misses chomp and chop that end their statement, because
# first_arg takes the semicolon for an argument.
$check_table->(
    'what the core policy misses',
    'chomp; in grep'      => [ 1, q{my @t = grep { chomp; 1 } @lines;} ],
    'chop; in map'        => [ 1, q{my @t = map { chop; $_ } @lines;} ],
    'chomp of a variable' => [ 0, q{my @t = map { my $x = $_; chomp $x; $x } @lines;} ],
);

$check_table->(
    'a sub that changes $_, called in the block',
    'a substitution'         => [ 1, $TRIM . q{my @t = map { trim(); $_ } @lines;} ],
    'chomp'                  => [ 1, q{sub c { chomp; return } my @t = grep { c() } @lines;} ],
    'an assignment'          => [ 1, q{sub z { $_ = 0; return } my @t = map { z(); $_ } @lines;} ],
    'a transliteration'      => [ 1, q{sub up { tr/a-z/A-Z/; return } my @t = map { up(); $_ } @lines;} ],
    'a lexical sub'          => [ 1, q{my sub trim { s/\s+\z//; return } my @t = map { trim(); $_ } @lines;} ],
    'defined after the call' => [ 1, q{my @t = map { trim(); $_ } @lines; } . $TRIM ],
    'in List::Util::first'   => [ 1, $TRIM . q{my $t = List::Util::first { trim(); 1 } @lines;} ],
    'without parens'         => [ 1, $TRIM . q{my @t = map { trim; $_ } @lines;} ],
    'twice in one block'     => [ 1, $TRIM . q{my @t = map { trim(); trim(); $_ } @lines;} ],
    'in two blocks'          => [ 2, $TRIM . q{my @t = map { trim(); $_ } @lines; my @u = grep { trim() } @lines;} ],

    # The list of a loop is evaluated before $_ is aliased to its elements.
    'in the list of its foreach'     => [ 1, q{sub t { foreach ( s/x// ) { 1 } return } my @t = map { t(); $_ } @lines;} ],
    'in the list of its postfix for' => [ 1, q{sub t { my @q; push @q, $_ for s/x//; return } my @t = map { t(); $_ } @lines;} ],
);

$check_table->(
    'allowed',
    'a sub with local $_'               => [ 0, q{sub trim { local $_ = shift; s/\s+\z//; return $_ } my @t = map { trim($_) } @lines;} ],
    'a sub that changes its own loop'   => [ 0, q{sub t { for (@_) { s/x// } return } my @t = map { t(); $_ } @lines;} ],
    'a sub with a postfix loop'         => [ 0, q{sub t { my @c = @_; s/x// for @c; return @c } my @t = map { t(); $_ } @lines;} ],
    'a sub with s///r'                  => [ 0, q{sub t { return s/x//r } my @t = map { t() } @lines;} ],
    'a sub that changes a variable'     => [ 0, q{sub t { my $x = shift; $x =~ s/x//; return $x } my @t = map { t($_) } @lines;} ],
    'a sub whose own map changes $_'    => [ 1, q{sub t { my @y = map { s/x//; $_ } @_; return @y } my @t = map { t($_) } @lines;} ],
    'a sub with an inner anonymous sub' => [ 0, q{sub t { my $f = sub { s/x// }; return 1 } my @t = map { t(); $_ } @lines;} ],
    'a method of the same name'         => [ 0, $TRIM . q{my @t = map { $obj->trim(); $_ } @lines;} ],
    'the sub called outside a block'    => [ 0, $TRIM . q{trim(); my @t = map { $_ } @lines;} ],
    'a sub that only reads $_'          => [ 0, q{sub has_x { return /x/ } my @t = grep { has_x() } @lines;} ],
    'a sub defined nowhere'             => [ 0, q{my @t = map { trim(); $_ } @lines;} ],
);

# The forms of an inner sub that PPI parses differently, each of which
# is_sub_header or PPI::Statement::Sub must find.  On perl 5.44, under
# use 5.040, no case here with 0 changes @lines.
my %INNER_SUB = (
    'an anonymous sub with a signature'      => q{my $f = sub ($y) { s/x// };},
    'an anonymous sub with two parameters'   => q{my $f = sub ($y, $z = 1) { s/x// };},
    'an anonymous sub with a prototype'      => q{my $f = sub ($) { s/x// };},
    'an anonymous sub with an attribute'     => q{my $f = sub :lvalue { s/x// };},
    'an anonymous sub with :prototype'       => q{my $f = sub :prototype($) { s/x// };},
    'an anonymous sub, attribute, signature' => q{my $f = sub :lvalue ($y) { s/x// };},
    'an anonymous sub returned'              => q{return sub ($y) { s/x// };},
    'an anonymous sub as an argument'        => q{g(sub ($y) { s/x// });},
    'a named sub with a signature'           => q{sub g ($y) { s/x// }},
    'a named sub with an attribute'          => q{sub g :lvalue { s/x// }},
    'a lexical sub with a signature'         => q{my sub g ($y) { s/x// }},
);
my %PRELUDE = (
    'no feature'                => q{},
    q{use feature 'signatures'} => q{use feature 'signatures'; },
    'use 5.040'                 => q{use 5.040; },
);
foreach my $prelude ( sort keys %PRELUDE ) {
    $check_table->(
        "a sub whose inner sub changes \$_, $prelude",
        map {
            (
                "$_, not called"          => [ 0, $PRELUDE{$prelude} . "sub t { $INNER_SUB{$_} return 1 } my \@t = map { t(); \$_ } \@lines;" ],
                "$_, and the sub's own s" => [ 1, $PRELUDE{$prelude} . "sub t { $INNER_SUB{$_} s/x//; return 1 } my \@t = map { t(); \$_ } \@lines;" ],
            )
        } keys %INNER_SUB
    );
    $check_table->(
        "a sub that changes \$_ and carries a signature or attribute, $prelude",
        'a signature'                    => [ 1, $PRELUDE{$prelude} . q{sub t ($y) { s/x//; return 1 } my @t = map { t(1); $_ } @lines;} ],
        'a prototype'                    => [ 1, $PRELUDE{$prelude} . q{sub t ($) { s/x//; return 1 } my @t = map { t(1); $_ } @lines;} ],
        'an attribute'                   => [ 1, $PRELUDE{$prelude} . q{sub t :lvalue { s/x//; my $z } my @t = map { t(); $_ } @lines;} ],
        'a lexical sub with a signature' => [ 1, $PRELUDE{$prelude} . q{my sub t ($y) { s/x//; return 1 } my @t = map { t(1); $_ } @lines;} ],
    );
}

# A local $_ gives the block a $_ of its own, so a sub called after it changes
# a copy.  On perl 5.44 each case with 0 leaves @lines as it was.
$check_table->(
    'a local $_ at the top of the block',
    'local ($_) = $_ first'        => [ 0, $TRIM . q{my @t = map { local ($_) = $_; trim(); $_ } @lines;} ],
    'a copy, then local $_'        => [ 0, $TRIM . q{my @t = map { my $y = $_; local $_; trim(); $y } @lines;} ],
    'local after other statements' => [ 0, $TRIM . q{my @t = map { my $n = 1; local ($_) = $_; trim(); $n } @lines;} ],
    'the call before the local'    => [ 1, $TRIM . q{my @t = map { trim(); local ($_) = $_; $_ } @lines;} ],
    'the call in the local'        => [ 1, $TRIM . q{my @t = map { local ($_) = trim(); $_ } @lines;} ],
    'a local in an inner block'    => [ 1, $TRIM . q{my @t = map { if ($x) { local $_ = 1 } trim(); $_ } @lines;} ],
    'a local of another variable'  => [ 1, $TRIM . q{my @t = map { local $/; trim(); $_ } @lines;} ],
);

# On perl 5.44 each case with 0 leaves @lines as it was, and each with 1
# changes it, or changes the list of the inner block that is reported.
$check_table->(
    'a sub that changes $_, called where $_ is not the caller\'s',
    'in an anonymous sub'                       => [ 0, $TRIM . q{my @t = map { my $c = sub { trim() }; $_ } @lines;} ],
    'in an anonymous sub with a signature'      => [ 0, q{use 5.040; } . $TRIM . q{my @t = map { my $c = sub ($y) { trim() }; $_ } @lines;} ],
    'in an anonymous sub with a prototype'      => [ 0, $TRIM . q{my @t = map { my $c = sub ($) { trim() }; $_ } @lines;} ],
    'in an anonymous sub with an attribute'     => [ 0, $TRIM . q{my @t = map { my $c = sub :lvalue { trim() }; $_ } @lines;} ],
    'in an anonymous sub, attribute, signature' => [ 0, q{use 5.040; } . $TRIM . q{my @t = map { my $c = sub :lvalue ($y) { trim() }; $_ } @lines;} ],
    'in a named sub'                            => [ 0, $TRIM . q{my @t = map { sub g { trim() } $_ } @lines;} ],
    'in a named sub with a signature'           => [ 0, q{use 5.040; } . $TRIM . q{my @t = map { sub g ($y) { trim() } $_ } @lines;} ],
    'in a lexical sub with a signature'         => [ 0, q{use 5.040; } . $TRIM . q{my @t = map { my sub g ($y) { trim() } $_ } @lines;} ],
    'in the body of a foreach, no variable'     => [ 0, $TRIM . q{my @t = map { for (@y) { trim() } $_ } @lines;} ],
    'before a postfix for'                      => [ 0, $TRIM . q{my @t = map { trim() for @y; $_ } @lines;} ],
    'in a nested map, reported once'            => [ 1, $TRIM . q{my @t = map { my @z = map { trim(); $_ } @y; $_ } @lines;} ],
    'in a nested grep, reported once'           => [ 1, $TRIM . q{my @t = map { my @z = grep { trim() } @y; $_ } @lines;} ],
    'in a nested List::Util::first, once'       => [ 1, $TRIM . q{my @t = map { my $z = List::Util::first { trim() } @y; $_ } @lines;} ],
    'in the body of a for my'                   => [ 1, $TRIM . q{my @t = map { for my $x (@y) { trim() } $_ } @lines;} ],
    'in the list of a foreach, no variable'     => [ 1, $TRIM . q{my @t = map { for ( trim() ) { 1 } $_ } @lines;} ],
    'in the list of a postfix for'              => [ 1, $TRIM . q{my @t = map { my @q; push @q, $_ for trim(); $_ } @lines;} ],
    'in the list of a nested map'               => [ 1, $TRIM . q{my @t = map { my @z = map { $_ } trim(); $_ } @lines;} ],
);

# map EXPR, LIST and grep EXPR, LIST alias $_ as the block forms do.  On perl
# 5.44 each case with 1 changes @y, and each with 0 leaves it as it was.
$check_table->(
    'map EXPR and grep EXPR',
    'a sub that changes $_, in map EXPR'  => [ 1, $TRIM . q{my @z = map trim(), @y;} ],
    'a sub that changes $_, in grep EXPR' => [ 1, $TRIM . q{my @z = grep trim(), @y;} ],
    'map(EXPR, LIST)'                     => [ 1, $TRIM . q{my @z = map(trim(), @y);} ],
    'a substitution in map EXPR'          => [ 1, q{my @z = map s/x//, @y;} ],
    'chomp in map EXPR'                   => [ 1, q{my @z = map chomp, @y;} ],
    's///r in map EXPR'                   => [ 0, q{my @z = map s/x//r, @y;} ],
    'a sub that only reads $_'            => [ 0, q{sub has_x { return /x/ } my @z = grep has_x(), @y;} ],
    'a sub in the list, outside'          => [ 0, $TRIM . q{my @z = map lc, trim();} ],
);

# Each is reported once, on the line of the list function whose list perl
# 5.44 changes.
my %EXPR_LINES = (
    'nested in a map block'            => [ [2], $TRIM . qq{my \@r = map {\n    my \@z = map trim(), \@y;\n    \$_;\n} \@l;\n} ],
    'in a sub that a map block calls'  => [ [2], $TRIM . qq{sub t {\n    my \@z = map trim(), \@y;\n    return 1;\n}\nmy \@r = map { t() } \@l;\n} ],
    'a substitution, in a sub called'  => [ [2], qq{sub u {\n    my \@z = map s/x//, \@_;\n    return 1;\n}\nmy \@r = map { u() } \@l;\n} ],
    'in the list of a nested map EXPR' => [ [1], $TRIM . qq{my \@r = map {\n    my \@z = map \$_, trim();\n    \$_;\n} \@l;\n} ],
);
foreach my $case ( sort keys %EXPR_LINES ) {
    my ( $lines, $source ) = @{ $EXPR_LINES{$case} };
    is_deeply( [ map { $_->line_number } $critic->critique( \$source ) ], $lines, "map EXPR, reported where its list changes: $case" ) or diag $source;
}

# report_unresolved_calls and report_postfix_for_calls, which are off unless a
# profile turns them on.
my $ALIASED_PROFILE = "[ControlStructures::ProhibitMutatingListFunctionsStricter]\nreport_unresolved_calls = 1\nreport_postfix_for_calls = 1\n";
my $aliased         = Perl::Critic->new( -profile => \$ALIASED_PROFILE, -only => 1, -severity => 1 );

my $check_aliased = sub {
    my ( $label, %cases ) = @_;
    foreach my $case ( sort keys %cases ) {
        my ( $expected, $source ) = @{ $cases{$case} };
        is( scalar $aliased->critique( \$source ), $expected, "$label: $case" ) or diag $source;
    }
    return;
};

$check_table->(
    'off by default',
    'a sub defined nowhere'       => [ 0, q{my @r = map { f($_) } @x;} ],
    'a method'                    => [ 0, q{my @r = grep { $_->is_ok } @x;} ],
    'map EXPR'                    => [ 0, q{my @r = map f($_), @x;} ],
    'a bare list function'        => [ 0, $TRIM . q{my $r = any { trim() } @lines;} ],
    'a postfix for of a method'   => [ 0, q{$_->save for @objects;} ],
    'a postfix for of a sub here' => [ 0, $TRIM . q{trim() for @lines;} ],
);

# On perl 5.44, a callee that assigns to $_ changed the elements of each of
# these, and of none of the list functions that are not reported.
$check_aliased->(
    'a call that cannot be read, in a list function block',
    'a sub'                                             => [ 1, q{my @r = map { f($_) } @x;} ],
    'a sub without parens'                              => [ 1, q{my @r = map { f } @x;} ],
    'a qualified sub'                                   => [ 1, q{my @r = map { Some::Where::f($_) } @x;} ],
    'a method of $_'                                    => [ 1, q{my @r = grep { $_->is_ok } @x;} ],
    'a class method'                                    => [ 1, q{my @r = map { Some::Class->new($_) } @x;} ],
    'a dynamic method'                                  => [ 1, q{my @r = map { $o->$name($_) } @x;} ],
    'a code reference'                                  => [ 1, q{my @r = map { $code->($_) } @x;} ],
    'a code reference in a hash'                        => [ 1, q{my @r = map { $dispatch{$_}->() } @x;} ],
    'an ampersand cast'                                 => [ 1, q{my @r = map { &$code } @x;} ],
    'an ampersand sub'                                  => [ 1, q{my @r = map { &f } @x;} ],
    'a constant, which is a sub'                        => [ 1, q{my @r = map { $_ * PI } @x;} ],
    'in a condition'                                    => [ 1, q{my @r = grep { f($_) && $_ } @x;} ],
    'in a statement modifier'                           => [ 1, q{my @r = map { $n++ if f(); $_ } @x;} ],
    'in a nested for my loop'                           => [ 1, q{my @r = map { for my $y (@y) { f($y) } $_ } @x;} ],
    'in the list of a for my loop'                      => [ 1, q{my @r = map { for my $y ( f() ) { } $_ } @x;} ],
    'in the list of an inner topic loop'                => [ 1, q{my @r = map { for ( f() ) { } $_ } @x;} ],
    'in the list of an inner postfix for'               => [ 1, q{my @r = map { push @q, $_ for f(); $_ } @x;} ],
    'in a nested if block'                              => [ 1, q{my @r = map { if ($_) { f() } $_ } @x;} ],
    'the argument of a builtin'                         => [ 1, q{my @r = map { lc f($_) } @x;} ],
    'two calls, once'                                   => [ 1, q{my @r = map { f($_) . g($_) } @x;} ],
    'a copy is not a fix'                               => [ 1, q{my @r = map { my $y = $_; f($y) } @x;} ],
    'a method named like a sub'                         => [ 1, $TRIM . q{my @r = map { $_->trim } @lines;} ],
    'map EXPR'                                          => [ 1, q{my @r = map f($_), @x;} ],
    'grep EXPR'                                         => [ 1, q{my @r = grep f($_), @x;} ],
    'List::Util::first'                                 => [ 1, q{my $r = List::Util::first { f($_) } @x;} ],
    'first, imported'                                   => [ 1, q{my $r = first { f($_) } @x;} ],
    'any, imported'                                     => [ 1, q{my $r = any { f($_) } @x;} ],
    'all, imported'                                     => [ 1, q{my $r = all { f($_) } @x;} ],
    'none, imported'                                    => [ 1, q{my $r = none { f($_) } @x;} ],
    'notall, imported'                                  => [ 1, q{my $r = notall { f($_) } @x;} ],
    'List::MoreUtils::firstval'                         => [ 1, q{my $r = List::MoreUtils::firstval { f($_) } @x;} ],
    'List::SomeUtils::part'                             => [ 1, q{my @r = List::SomeUtils::part { f($_) } @x;} ],
    'firstidx, imported'                                => [ 1, q{my $r = firstidx { f($_) } @x;} ],
    'insert_after, imported'                            => [ 1, q{insert_after { f($_) } $v => @x;} ],
    'max_by, imported'                                  => [ 1, q{my $r = max_by { f($_) } @x;} ],
    'List::UtilsBy::min_by'                             => [ 1, q{my $r = List::UtilsBy::min_by { f($_) } @x;} ],
    'a call before the local'                           => [ 1, q{my @r = map { f(); local ($_) = $_; g() } @x;} ],
    'a call in the local'                               => [ 1, q{my @r = map { local ($_) = f($_); $_ } @x;} ],
    'a local in an inner block'                         => [ 1, q{my @r = map { if ($y) { local $_ = 1 } f() } @x;} ],
    'a local of another variable'                       => [ 1, q{my @r = map { local $/; f() } @x;} ],
    'a sub here that changes $_, and one of none, once' => [ 1, $TRIM . q{my @r = map { trim(); f() } @lines;} ],
    'a bare list function, through a sub here'          => [ 1, $TRIM . q{my $r = any { trim() } @lines;} ],
    'a change in a bare list function'                  => [ 1, q{my $r = any { s/x// } @lines;} ],
    'a sub here that changes $_, in map EXPR'           => [ 1, $TRIM . q{my @r = map trim(), @lines;} ],
    'beside an anonymous sub with a signature'          => [ 1, q{use 5.040; my @r = map { my $c = sub ($y) { 1 }; f($_) } @x;} ],

    # Perl reads sub : at the start of a statement as the label sub:, and the
    # rest as a call, so f runs here, and PPI reads it as perl does.
    'sub :lvalue, first in its statement' => [ 1, q{my @r = map { my $s = $_; sub :lvalue { f($s) } } @x;} ],
);

$check_aliased->(
    'a call that can be read, or not while $_ is an alias',
    'builtins'                                        => [ 0, q{my @r = map { lc } grep { defined && length } @x;} ],
    'a builtin through CORE::'                        => [ 0, q{my @r = map { CORE::lc($_) } @x;} ],
    'no call at all'                                  => [ 0, q{my @r = map { $_ * 2 } @x;} ],
    'a hash key'                                      => [ 0, q{my @r = map { $h{key} } @x;} ],
    'a fat comma key'                                 => [ 0, q{my @r = map { { name => $_ } } @x;} ],
    'a subscript after an arrow'                      => [ 0, q{my @r = map { $_->{name} } @x;} ],
    'a method of UNIVERSAL'                           => [ 0, q{my @r = grep { $_->isa('Some::Class') && $_->can('m') } @x;} ],
    'local ($_) = $_ first'                           => [ 0, q{my @r = map { local ($_) = $_; f() } @x;} ],
    'a copy and local $_'                             => [ 0, q{my @r = map { my $y = $_; local $_; f($y) } @x;} ],
    'a sub here that reads $_'                        => [ 0, q{sub f { return /x/ } my @r = map { f($_) } @x;} ],
    'a sub here, defined later'                       => [ 0, q{my @r = map { f($_) } @x; sub f { return 1 }} ],
    'a qualified sub here'                            => [ 0, q{package Here; sub f { return 1 } my @r = map { Here::f($_) } @x;} ],
    'a lexical sub'                                   => [ 0, q{my sub f { return 1 } my @r = map { f($_) } @x;} ],
    'in an anonymous sub'                             => [ 0, q{my @r = map { my $s = $_; sub { f($s) } } @x;} ],
    'in an anonymous sub with a signature'            => [ 0, q{use 5.040; my @r = map { my $s = $_; sub ($y) { f($s) } } @x;} ],
    'in an anonymous sub with a prototype'            => [ 0, q{my @r = map { my $s = $_; sub ($) { f($s) } } @x;} ],
    'in an anonymous sub with an attribute'           => [ 0, q{my @r = map { my $s = $_; my $c = sub :lvalue { f($s) }; $c } @x;} ],
    'in an anonymous sub, attribute, signature'       => [ 0, q{use 5.040; my @r = map { my $s = $_; my $c = sub :lvalue ($y) { f($s) }; $c } @x;} ],
    'in a named sub with a signature'                 => [ 0, q{use 5.040; my @r = map { sub g ($y) { f($y) } $_ } @x;} ],
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

$check_aliased->(
    'a call in a statement with a postfix for',
    'a sub of none'              => [ 1, q{f() for @x;} ],
    'foreach'                    => [ 1, q{f() foreach @x;} ],
    'a method of $_'             => [ 1, q{$_->save for @objects;} ],
    'the argument of a builtin'  => [ 1, q{push @r, $_->name for @objects;} ],
    'a sub here that changes $_' => [ 1, $TRIM . q{trim() for @lines;} ],
    'a do block'                 => [ 1, q{do { f() } for @x;} ],
    'inside a list function'     => [ 1, q{my @r = map { f() for @y; $_ } @x;} ],
    'a local is no cover'        => [ 1, q{do { local ($_) = $_; f() } for @x;} ],
);

$check_aliased->(
    'a postfix for with no such call, or another statement',
    'builtins'                    => [ 0, q{print for @x;} ],
    'a substitution'              => [ 0, q{s/\s+\z// for @x;} ],
    'chomp'                       => [ 0, q{chomp for @x;} ],
    'a sub here that reads $_'    => [ 0, q{sub f { return /x/ } f() for @x;} ],
    'a method of UNIVERSAL'       => [ 0, q{print $_->isa('Some::Class') for @x;} ],
    'a call in the list'          => [ 0, q{print for f(@x);} ],
    'a postfix if'                => [ 0, q{f() if $x;} ],
    'a postfix while'             => [ 0, q{f() while $x;} ],
    'an anonymous sub, signature' => [ 0, q{use 5.040; push @r, sub ($y) { f($y) } for @x;} ],
    'a block for, no name'        => [ 0, q{for (@x) { f() }} ],
    'a block for my'              => [ 0, q{for my $y (@x) { f($y) }} ],
    'a C-style for'               => [ 0, q{for ( my $i = 0; $i < 9; $i++ ) { f($i) }} ],
);

$check_aliased->(
    'each construct reports its own calls once',
    'a map in a map'            => [ 2, q{my @r = map { g(); map { f() } @y } @x;} ],
    'a map in a postfix for'    => [ 1, q{print map { f() } @y for @x;} ],
    'a postfix for, then a map' => [ 2, q{f() for @x; my @r = map { g() } @x;} ],
);

my ($first) = $aliased->critique( \qq{my \@r = map {\n    lc \$_;\n    f(\$_);\n} \@x;\n} );
is( $first ? $first->line_number : undef, 3, 'a call that cannot be read is reported on its own line' );

my %explains = (
    q{my @r = map { f($_) } @x;} => q{local ($_) = $_;},
    q{f() for @x;}               => q{for my},
);
foreach my $source ( sort keys %explains ) {
    my ($violation) = $aliased->critique( \$source );
    my $explanation = $violation ? $violation->explanation : q{};
    ok( index( $explanation, $explains{$source} ) >= 0, "the explanation of $source says $explains{$source}" ) or diag $explanation;
}

my $allow_profile = $ALIASED_PROFILE . "allow_calls = f Some::g name\n";
my $allowing      = Perl::Critic->new( -profile => \$allow_profile, -only => 1, -severity => 1 );
foreach my $source ( q{my @r = map { f($_) } @x;}, q{my @r = map { Some::g($_) } @x;}, q{my @r = map { $_->name } @x;}, q{$_->name for @x;} ) {
    is( scalar $allowing->critique( \$source ), 0, "a name in allow_calls: $source" );
}
is( scalar $allowing->critique( \q{my @r = map { g($_) } @x;} ),              1, 'allow_calls names Some::g, which is not g' );
is( scalar $allowing->critique( \( $TRIM . q{my @r = map { trim() } @x;} ) ), 1, 'allow_calls does not cover a sub that changes $_' );

my $funcs_profile = $ALIASED_PROFILE . "add_list_funcs = each_item\n";
my $funcs         = Perl::Critic->new( -profile => \$funcs_profile, -only => 1, -severity => 1 );
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
        'dist.ini'          => "name = Some\n",
        'lib/Some.pm'       => "package Some;\nsub trim { s/\\s+\\z//; return }\nsub has_x { return /x/ }\n1;\n",
        'lib/Some/Same.pm'  => "package Some;\nsub tidy { my \@t = map { trim(); \$_ } \@_; return \@t }\n1;\n",
        'lib/Some/Other.pm' => "package Some::Other;\nsub one { my \@t = map { Some::trim(); \$_ } \@_; return \@t }\nsub two { my \@t = map { trim(); \$_ } \@_; return \@t }\n1;\n",
        'lib/Some/Reads.pm' => "package Some::Reads;\nsub one { my \@t = grep { Some::has_x() } \@_; return \@t }\n1;\n",
        'lib/Some/Calls.pm' => join(
            q{},
            "package Some::Calls;\n",
            "sub one { my \@t = map { Some::has_x(); \$_ } \@_; return \@t }\n",
            "sub two { my \@t = map { elsewhere(); \$_ } \@_; return \@t }\n",
            "sub three { my \@t = map { has_x(); \$_ } \@_; return \@t }\n",
            "sub four { Some::has_x() for \@_; return }\n",
            "sub five { Some::trim() for \@_; return }\n",
            "1;\n"
        ),
    );
    foreach my $name ( keys %files ) {
        open( my $fh, '>', "$root/$name" ) or die "$root/$name: $!";
        print {$fh} $files{$name};
        close($fh) or die "$root/$name: $!";
    }

    my $found = sub {
        my ( $file, $by ) = @_;
        return [ map { $_->line_number } ( $by // $critic )->critique("$root/$file") ];
    };

    is_deeply( $found->('lib/Some/Same.pm'),  [2], 'another file: a bare call in the package of the sub' );
    is_deeply( $found->('lib/Some/Other.pm'), [2], 'another file: a qualified call, and not a bare one from another package, whose import is not known' );
    is_deeply( $found->('lib/Some/Reads.pm'), [],  'another file: a sub that only reads $_' );
    is_deeply( $found->('lib/Some/Calls.pm'), [],  'another file: no call is reported by default' );

    is_deeply( $found->( 'lib/Some/Calls.pm', $aliased ), [ 3, 4, 6 ], 'another file, with both reports: a sub of none, a bare call from another package, and a postfix for of a sub that changes $_, but not one that only reads it' );
    is_deeply( $found->( 'lib/Some/Other.pm', $aliased ), [ 2, 3 ], 'another file, with both reports: a sub that changes $_ once, and a bare call from another package as a call that cannot be read' );
}

done_testing;
