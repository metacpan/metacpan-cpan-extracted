#!perl

use strict;
use Test::More;
use Test::Exception;
use Test::Deep;
use File::Basename;
use autodie;
use FindBin;
use Pg::Explain;

our $data_dir = sprintf '%s/%s.d', $FindBin::Bin, basename( $0, '.t' );

opendir my $dir, $data_dir;
my @plans = sort grep { s/^(plan-\d+)\.text$/$1/ } readdir $dir;
closedir $dir;

# tests * formats * plans
plan 'tests' => 3 * 3 * scalar @plans;

for my $plan ( @plans ) {
    my $text = Pg::Explain->new( 'source' => load_file( $plan . '.text' ) );
    $text->parse_source();

    for my $format ( qw( json xml yaml ) ) {
        my $explain = Pg::Explain->new( 'source' => load_file( $plan . '.' . $format ) );
        lives_ok( sub { $explain->parse_source(); }, "(${plan}/${format}) Parsing lives" );
        is( $explain->top_node->type, $text->top_node->type, "(${plan}/${format}) Top node is of correct type: " . $text->top_node->type );
        cmp_deeply(
            $explain->top_node->extra_info,
            $text->top_node->extra_info,
            "(${plan}/${format}) Top node extra info is OK",
        );
    }

}

exit;

sub load_file {
    my $filename = shift;
    open my $fh, '<', sprintf( "%s/%s", $data_dir, $filename );
    local $/ = undef;
    my $file_content = <$fh>;
    close $fh;

    $file_content =~ s/\s*\z//;

    return $file_content;
}

