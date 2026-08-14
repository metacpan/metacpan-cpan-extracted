#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;
BEGIN {
   eval { require Devel::MAT; Devel::MAT->VERSION( '0.56' ) } or
      plan skip_all => "No Devel::MAT version 0.56";

   require Devel::MAT::Dumper;
}

use Scalar::ValueTags;

( my $file = __FILE__ ) =~ s/\.t$/.pmat/;
END { unlink $file if -f $file }

skip_all "Scalar::ValueTags is not available" unless value_tags_enabled;

my $vt_type = register_value_tags_type(SVTAGS_UNIQUE_REF_ARRAY);

my $var = 123;
add_value_tag( $vt_type, \$var, my $datum = { data => "here" } );

Devel::MAT::Dumper::dump( $file );

my $pmat = Devel::MAT->load( $file );
my $df = $pmat->dumpfile;

# Main magic funcs
my $funcs_at = eval { $df->root_at( "the Scalar::ValueTags magic funcs" ) };
ok( defined $funcs_at, 'Dumpfile records address of Scalar::ValueTags magic funcs' );

# $var has value tags
{
    my $main_cv = $df->main_cv;
    ok( my $var_sv = $main_cv->maybe_lexvar( '$var' ), 'main_cv has $var' );

    my @magics = $var_sv->magic;
    ok( scalar @magics, 'main_cv $var has some magic' );

    my ( $value_tags_magic ) = grep { $_->ver == 2 and $_->funcs == $funcs_at } @magics;
    ok( defined $value_tags_magic, 'main_cv $var has value tags magic' );

    my $value_tags_userstruct = $value_tags_magic->userstruct;
    ok( defined $value_tags_userstruct, 'value tags has associated userstruct' );

    ok( my $tags_sv = $value_tags_userstruct->field_named( "the tags" ),
       'value tags userstruct has tags' );
    is( $tags_sv->type, "ARRAY", 'magic obj is ARRAY' );
    is( scalar $tags_sv->elems, 1, 'magic obj array has 1 elem' );

    my $tag0 = $tags_sv->elem(0);
    is( $tag0->type, "REF",      'tags[0] is a ref' );
    is( $tag0->rv->type, "HASH", 'tags[0] is a ref to a HASH' );

    my $tag0hv = $tag0->rv;
    is( [ $tag0hv->keys ], [qw( data )], 'keys of tags[0] hash' );
    is( $tag0hv->value( "data" )->pv, "here", 'value of tags[0] value "data" ');
}

done_testing;
