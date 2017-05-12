use lib 't';
# vim: ts=8 et sw=4 sts=4
use strict;
use warnings;
use ExtUtils::testlib;
use Storable::AMF0 qw(freeze thaw retrieve ref_lost_memory);
use GrianUtils;
my $directory = qw(t/AMF0);
my @item ;
@item = GrianUtils->my_items($directory);

my $total = @item*1;
eval "use Test::More tests=>$total;";
warn $@ if $@;

TEST_LOOP: 
for my $item (@item) {
    my ( $name, $obj, $image_amf0 ) = @$item{qw(name obj amf0)};
    my $new_obj;
    if ( ref_lost_memory($obj) ) {
        ok( !defined( thaw( $image_amf0, 1 ) ), "thaw(strict) recurrent $name" );
    }
    else {
        if ( defined($obj) ) {
            ok( defined( thaw( $image_amf0, 1 ) ), "thaw(strict) non-recurrent $name" );
        }
        else {
            ok(1);
        }
    }
}


