package DummyT;

use strict;
use warnings;

use Test::DataDriven::Plugin -base;
use Test::Differences;

use Dummy;
use File::Path;

BEGIN {
    rmtree( 't/dummy' );
    mkpath( 't/dummy' );
}

__PACKAGE__->register;

sub run_mkpath : Run(mkpath) {
    my( $block, $section, @v ) = @_;

    Dummy::mkpath( @v );
}

sub run_touch : Run(touch) {
    my( $block, $section, @v ) = @_;

    Dummy::touch( @v );
}

my @orig;
my $directory;

sub pre_directory : Begin(directory) {
    my( $block, $section, @v ) = @_;
    $directory = $v[0];
}

sub pre_created : Begin(created) {
    my( $block, $section, @v ) = @_;
    @orig = Dummy::ls( $directory . '/*' );
}

sub _lsd {
    my( $block, $section, @v ) = @_;
    my %final = map { ( $_ => 1 ) } Dummy::ls( $directory . '/*' );

    delete $final{$_} foreach @orig;

    my @final = sort map { s{^$directory/}//; $_ } keys %final;
}

sub post_created : End(created) {
    my( $block, $section, @v ) = @_;

    my @final = _lsd( @_ );
    eq_or_diff( \@final, \@v, test_name );
}

sub post_createdc : Endc(created) {
    my( $block, $section, @v ) = @_;

    my @final = _lsd( @_ );
    $block->original_values->{$section} = join "\n", @final, '';
}

# Test::DataDriven is not made for this; but this is just a test...

sub my_filter : Filter(my_filter) {
    return map { $_ . ' my_filter' } @_;
}

sub my_filter2 : Filter(my_filter2) {
    return map { $_ . ' my_filter2' } @_;
}

my @data;

sub data : Begin(data) {
    my( $block, $section, @v ) = @_;

    @data = @v;
}

sub dataf : Begin(dataf) : Filter(lines) : Filter(chomp) : Filter(my_filter) {
    my( $block, $section, @v ) = @_;

    @data = @v;
}

sub filtered : End(filtered) {
    my( $block, $section, @v ) = @_;

    eq_or_diff( \@data, \@v, test_name );
}

1;
