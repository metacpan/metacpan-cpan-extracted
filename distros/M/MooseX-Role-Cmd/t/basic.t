use strict;
use warnings;

use Test::More tests => 7;

use lib 't/lib';

BEGIN {
    use_ok('Test::Cmd::Perl');
}

isa_ok( my $wrapper = Test::Cmd::Perl->new, 'Test::Cmd::Perl' );

is( Test::Cmd::Perl->build_bin_name, 'perl' );
is( $wrapper->bin_name, 'perl' );

$wrapper->e(q{print( join "/", @ARGV ), "\n"});
my @data = $wrapper->output();
ok( !@data );

my @args = qw/foo/;
@data = $wrapper->output(@args);
is_deeply( \@data, \@args );

@args = qw/foo bar/;
@data = $wrapper->output(@args);
is_deeply( \@data, \@args );
