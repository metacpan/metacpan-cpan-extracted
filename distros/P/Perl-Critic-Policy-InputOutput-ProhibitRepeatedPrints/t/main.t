use strict;
use warnings FATAL => 'all';

use re '/aa';

use 5.014;

=head1 NAME

t/main.t - which runs of prints the policy reports, and which it leaves alone

=head1 DESCRIPTION

A table of snippets that must be reported and a table that must not, under the
default configuration and under ones naming a threshold and an allowed handle.

The cases that matter are the ones a naive "two prints in a row" rule gets
wrong: a print to one handle beside a print to another, a statement that prints
many lines by itself, and a run broken by something that is not a print.

=cut

use Test::More;
use Test::Warnings qw{warnings};

use Perl::Critic;

# Loaded so that a syntax error in it is a compile failure here rather than
# Perl::Critic reporting no such policy.  Named as a string below, which is
# what ProhibitUnusedImports cannot see.
use Perl::Critic::Policy::InputOutput::ProhibitRepeatedPrints;    ## no critic (ProhibitUnusedImports)

# -profile => q{} because Perl::Critic otherwise walks up from cwd looking for a
# .perlcriticrc, finds this dist's own, and runs every policy in it against
# these snippets.  The anchored long name because -single-policy is a pattern.
my $POLICY = '^Perl::Critic::Policy::InputOutput::ProhibitRepeatedPrints$';

sub critic_with {
    my ($profile) = @_;
    return Perl::Critic->new( -profile => $profile, '-single-policy' => $POLICY, -severity => 1 );
}

sub violations {
    my ( $critic, $source ) = @_;
    return scalar $critic->critique( \$source );
}

sub check_table {
    my ( $critic, $label, %cases ) = @_;
    foreach my $case ( sort keys %cases ) {
        my ( $expected, $source ) = @{ $cases{$case} };
        is( violations( $critic, $source ), $expected, "$label: $case" );
    }
    return;
}

my $default = critic_with(q{});

check_table(
    $default,
    'reported',
    'two prints to stdout'      => [ 1, qq{print "one\\n";\nprint "two\\n";\n} ],
    'two to the same block'     => [ 1, qq{print {*STDERR} "one\\n";\nprint {*STDERR} "two\\n";\n} ],
    'two to the same lexical'   => [ 1, qq{print \$fh "one\\n";\nprint \$fh "two\\n";\n} ],
    'printf beside print'       => [ 1, qq{printf "%s\\n", \$a;\nprint "and\\n";\n} ],
    'say beside print'          => [ 1, qq{say "one";\nprint "two\\n";\n} ],
    'a modifier does not split' => [ 1, qq{print "one\\n";\nprint "two\\n" if \$why;\n} ],

    # One finding for the whole run: twelve prints are one message written
    # twelve ways, and a violation per line is a wall nobody reads.
    'a long run is one finding' => [ 1, join( q{}, map { qq{print "$_\\n";\n} } 1 .. 12 ) ],

    # Two runs, separated by something that is not a print.
    'two runs are two findings' => [ 2, qq{print "a\\n";\nprint "b\\n";\n\$x->go;\nprint "c\\n";\nprint "d\\n";\n} ],
);

check_table(
    $default,
    'left alone',
    'one print'              => [ 0, qq{print "one\\n";\n} ],
    'different handles'      => [ 0, qq{print "one\\n";\nprint {*STDERR} "two\\n";\n} ],
    'stderr then stdout'     => [ 0, qq{print {*STDERR} "one\\n";\nprint "two\\n";\n} ],
    'different lexicals'     => [ 0, qq{print \$out "one\\n";\nprint \$err "two\\n";\n} ],
    'separated by a call'    => [ 0, qq{print "one\\n";\n\$thing->go;\nprint "two\\n";\n} ],
    'a for modifier is one'  => [ 0, qq{print "\$_\\n" for \@lines;\n} ],
    'two commas are not two' => [ 0, qq{print \$x, \$y;\n} ],

    # A block boundary the run never crossed in the source.
    'across a block' => [ 0, qq{print "one\\n";\nif (\$x) {\n    print "two\\n";\n}\n} ],
);

# Where every real run is.  A table of document-level snippets would pass while
# the policy missed every case in the code it was written against: the run that
# prompted it is twelve prints inside a sub.
check_table(
    $default,
    'inside a block',
    'a run in a sub'     => [ 1, qq{sub say_it {\n    print "one\\n";\n    print "two\\n";\n}\n} ],
    'a run in an if'     => [ 1, qq{if (\$x) {\n    print "one\\n";\n    print "two\\n";\n}\n} ],
    'a run in a foreach' => [ 1, qq{foreach my \$i (\@l) {\n    print "one\\n";\n    print "two\\n";\n}\n} ],
    'two blocks, two'    => [ 2, qq{sub a {\n    print "one\\n";\n    print "two\\n";\n}\nsub b {\n    print "three\\n";\n    print "four\\n";\n}\n} ],
    'nested is one each' => [ 2, qq{sub a {\n    print "one\\n";\n    print "two\\n";\n    if (\$x) {\n        print "three\\n";\n        print "four\\n";\n    }\n}\n} ],
);

# print $x, $y is two things printed to STDOUT rather than a handle and a thing,
# and the comma is the whole of the difference.
check_table(
    $default,
    'the comma decides',
    'handle then string' => [ 1, qq{print \$fh "one\\n";\nprint \$fh "two\\n";\n} ],
    'list to stdout'     => [ 1, qq{print \$x, "one\\n";\nprint \$y, "two\\n";\n} ],
);

my $threshold = critic_with( \qq{[InputOutput::ProhibitRepeatedPrints]\nminimum_violations = 3\n} );

check_table(
    $threshold,
    'minimum_violations = 3',
    'two is allowed'    => [ 0, qq{print "one\\n";\nprint "two\\n";\n} ],
    'three is reported' => [ 1, qq{print "one\\n";\nprint "two\\n";\nprint "three\\n";\n} ],
);

my $allowed = critic_with( \qq{[InputOutput::ProhibitRepeatedPrints]\nallow = {*STDERR}\n} );

check_table(
    $allowed,
    'an allowed handle',
    'stderr is exempt'    => [ 0, qq{print {*STDERR} "one\\n";\nprint {*STDERR} "two\\n";\n} ],
    'stdout still counts' => [ 1, qq{print "one\\n";\nprint "two\\n";\n} ],
);

is( scalar( () = warnings { critic_with(q{}) } ), 0, 'nothing warns on construction' );

done_testing();
