use 5.006;
use strict;
use warnings;
use Test::More 0.92;
use File::Temp;
use Test::Deep qw/cmp_deeply/;

use lib 't/pir/lib';
use PCNTest;

use Path::Tiny::Rule;

#--------------------------------------------------------------------------#

my @tree = qw(
  aaaa.txt
  bbbb.txt
);

my $td = make_tree(@tree);

{
    my $rule = Path::Tiny::Rule->new->and( sub { die "Evil here" } );
    eval { $rule->all($td) };
    like( $@, qr/^\Q$td\E: Evil here/, "default error handler dies" );
}

{
    my @msg;
    my $handler = sub { push @msg, [@_]; };
    my $rule = Path::Tiny::Rule->new->and( sub { die "Evil here" } );
    eval { $rule->all( $td, { error_handler => $handler } ) };
    is( $@,          '', "error handler catches fatalities" );
    is( scalar @msg, 3,  "saw correct number of errors" );
    my ( $file, $text ) = @{ $msg[0] };
    is( $file, $td, "object has file path of error" );
    like( $text, qr/^Evil here/, "handler gets message" );
}

done_testing;
# COPYRIGHT
