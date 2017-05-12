use Test::More tests => 1;
use strict;
use t::Bar;

my $bar = Regexp::Log::Bar->new;
my $before =  $bar->{_test};
my $re = $bar->regexp;
is( $bar->{_test}, $before + 1, 'postprocessing code executed');

