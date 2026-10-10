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
    );
    foreach my $name ( keys %files ) {
        open( my $fh, '>', "$root/$name" ) or die "$root/$name: $!";
        print {$fh} $files{$name};
        close($fh) or die "$root/$name: $!";
    }

    my $found = sub {
        my ($file) = @_;
        return [ map { $_->line_number } $critic->critique("$root/$file") ];
    };

    is_deeply( $found->('lib/Some/Same.pm'),  [2], 'another file: a bare call in the package of the sub' );
    is_deeply( $found->('lib/Some/Other.pm'), [2], 'another file: a qualified call, and not a bare one from another package, whose import is not known' );
    is_deeply( $found->('lib/Some/Reads.pm'), [],  'another file: a sub that only reads $_' );
}

done_testing;
