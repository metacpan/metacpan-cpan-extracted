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
my @plans = sort grep { /\.plan$/ } readdir $dir;
closedir $dir;

plan 'tests' => 3 * scalar @plans;

for my $plan ( @plans ) {
    my $explain = Pg::Explain->new( 'source' => load_file( $plan ) );
    lives_ok( sub { $explain->parse_source(); }, "(${plan}) Parsing lives" );
    is( $explain->top_node->type, 'Aggregate', "(${plan}) Top node is Aggregate" );

    my $got_query = $explain->query;
    $got_query =~ s/\s+/ /g;
    $got_query =~ s/\A\s*//;
    $got_query =~ s/\s*\z//;
    is( $got_query, 'select count(*) from pg_class;', "(${plan}) Query as expected" );
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

