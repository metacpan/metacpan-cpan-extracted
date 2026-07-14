#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;
BEGIN {
   eval { require Devel::MAT; Devel::MAT->VERSION( '0.49' ) } or
      plan skip_all => "No Devel::MAT version 0.49";

   require Devel::MAT::Dumper;
}

use Scalar::ValueTags;
skip_all "Scalar::ValueTags is not available" unless value_tags_enabled;

my $vt_type = register_value_tags_type(SVTAGS_UNIQUE_REF_ARRAY);

my $var = 123;
add_value_tag( $vt_type, \$var, my $datum = { data => "here" } );

( my $file = __FILE__ ) =~ s/\.t$/.pmat/;
Devel::MAT::Dumper::dump( $file );
END { unlink $file if -f $file }

my $pmat = Devel::MAT->load( $file );
my $df = $pmat->dumpfile;

# Main vtbl root
my $vtbl_at = eval { $df->root_at( "the Scalar::ValueTags VTBL" ) || $df->root_at( "the Scalar::ValueTags Hook" ) };
ok( defined $vtbl_at, 'Dumpfile records address of Scalar::ValueTags VTBL or Hook' );

# $var has value tags
{
    my $main_cv = $df->main_cv;
    ok( my $var_sv = $main_cv->maybe_lexvar( '$var' ), 'main_cv has $var' );

    my @magics = $var_sv->magic;
    ok( scalar @magics, 'main_cv $var has some magic' );

    my ( $value_tags_magic ) = grep { $_->vtbl == $vtbl_at } @magics;
    ok( defined $value_tags_magic, 'main_cv $var has value tags magic' );

    ok( my $obj_sv = $value_tags_magic->obj, 'value tags magic has obj' );
    is( $obj_sv->type, "ARRAY", 'magic obj is ARRAY' );
    is( scalar $obj_sv->elems, 1, 'magic obj array has 1 elem' );

    # TODO: check that elem(0) is a ref to a hash with one key 'data' value is "here".
}

done_testing;
