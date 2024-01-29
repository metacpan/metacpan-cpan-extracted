#!perl

use strict;
use Test::More;
use Test::Deep;
use File::Basename;
use autodie;
use FindBin;
use Pg::Explain;

our $data_dir = sprintf '%s/%s.d', $FindBin::Bin, basename( $0, '.t' );

opendir my $dir, $data_dir;
my @plans = sort grep { /\.plan$/ } readdir $dir;
closedir $dir;

plan 'tests' => 2 * scalar @plans;

for my $plan ( @plans ) {
    my $expected_timings = load_timings( $plan );
    my $expected_text    = load_text( $plan );

    my $explain = Pg::Explain->new( 'source' => load_file( $plan ) );
    $explain->parse_source();

    is( $explain->as_text, $expected_text, "$plan has expected text represenation" );

    my $timings = $explain->top_node->buffers->get_struct->{ 'timings' };
    cmp_deeply( $timings, $expected_timings, "$plan has expected timings info" );
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

sub load_timings {
    my $plan         = shift;
    my $timings_file = $plan;
    $timings_file =~ s/\.plan\z/.timings/;
    my $content = load_file( $timings_file );
    return eval $content;
}

sub load_text {
    my $plan      = shift;
    my $text_file = $plan;
    $text_file =~ s/\.plan\z/.txt/;
    my $content = load_file( $text_file );
    $content =~ s/\s*\z/\n/;
    return $content;
}
