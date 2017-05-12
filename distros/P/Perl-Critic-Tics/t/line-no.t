
use strict;
use warnings;

use Perl::Critic::TestUtils qw(pcritique pcritique_with_violations);
use Test::More;

my $snippet = '$xy; ';    # 5 chars long
my $count   = 5;
my $code = join( "\n", ( ( $snippet x 20 ) x 5 ), ($snippet) x 100 );

plan tests => 11;

my $policy = 'Tics::ProhibitLongLines';

my @violations = pcritique_with_violations( $policy, \$code );

is( scalar @violations, $count, "\$code is no good (" . @violations . " violations)" );

for my $v_no ( 0 .. $#violations ) {

    my $v      = $violations[$v_no];
    my $v_line = $v_no + 1;

    is( $v->line_number, $v_line,         "violation $v_no on line $v_line" );
    is( $v->logical_line_number, $v_line, "violation $v_no on logical line $v_line" );

}
