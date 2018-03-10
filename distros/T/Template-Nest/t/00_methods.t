use strict;
use warnings;
use lib '../lib';

use Test::More;
BEGIN { use_ok('Template::Nest') };

my $nest = new_ok( 'Template::Nest' );
can_ok( $nest, qw(new template_dir template_hash token_delims comment_delims show_labels template_ext name_label render) );


foreach my $type ( qw(comment token) ){
    my $method = $type.'_delims';
    my $delims = $nest->$method;
    test_delims($delims,$type,'default');
    $delims = $nest->$method("(",")");
    test_delims($delims,$method,'set');
    is( $delims->[0], "(", "first set $method correct" );
    is( $delims->[1], ")", "second set $method correct" );
}


$nest->show_labels(1);
is( $nest->show_labels, 1, "set show_labels correct" );

$nest->template_hash({
    param1 => 'val1'
});

is( ref( $nest->template_hash ), ref {}, "template_hash is a hashref");
is( $nest->template_hash->{param1}, 'val1', "template_hash sets correctly");

foreach my $method ( qw(name_label template_ext template_dir) ){
    my $default_value = $nest->$method;
    test_scalar( $method,'default',$default_value );
    my $set_value = $nest->$method('HELLO');
    test_scalar( $method,'set',$set_value );
    is($set_value,'HELLO',"set $method is correct");
}

done_testing();


sub test_delims{
    my ($delims,$type,$mode) = @_;

    my $method = $type.'_delims';
    ok( $delims, "$mode $type is defined");
    like( ref($delims), qr/^array/i, "$mode $type is an arrayref" );
    is( scalar(@$delims), 2, "$mode $type has 2 values" );
    is( ref( $delims->[0] ), '', "first $mode $type is a scalar" );
    is( ref( $delims->[1] ), '', "second $mode $type is a scalar" );

}

sub test_scalar{
    my ($method,$type,$value) = @_;

    ok( defined $value, "$type $method is defined" );
    is( ref($value), '', "$type $method is a scalar");

}
