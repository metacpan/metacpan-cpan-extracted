use strict;
use warnings;
use lib '../lib';

use Test::More;
BEGIN { use_ok('Template::Nest') };

my $nest = new_ok( 'Template::Nest' );
can_ok( $nest, qw(
    new 
    template_dir 
    template_hash 
    token_delims 
    comment_delims 
    show_labels 
    template_ext 
    name_label 
    render
    defaults
    defaults_namespace_char
    fixed_indent
    die_on_bad_params
    escape_char
) );


#delim type fields
foreach my $type ( qw(comment token) ){
    my $method = $type.'_delims';
    my $delims = $nest->$method;
    test_delims($delims,$type,'default');
    $delims = $nest->$method("(",")");
    test_delims($delims,$method,'set');
    is( $delims->[0], "(", "first set $method" );
    is( $delims->[1], ")", "second set $method" );
}


# booleans
foreach my $method ( qw(fixed_indent show_labels die_on_bad_params) ){
    $nest->$method(1);
    is( $nest->$method, 1, "set $method" );
    $nest->$method(0);
    is( $nest->$method, 0, "unset $method" );
    eval{ $nest->$method(2) };
    ok( defined $@, "Non-boolean error");
}


# 1 char fields
foreach my $method( qw( defaults_namespace_char escape_char) ){
    $nest->$method('');
    is( $nest->$method, '', "$method: set as empty string");
    $nest->$method('A');
    is( $nest->$method, 'A', "$method: set as single char");
    eval{ $nest->$method('AB') };
    ok( defined $@, "$method: Non-single char error" );
}



foreach my $method ( qw(template_hash defaults ) ){
    $nest->$method({
        param1 => 'val1'
    });

    is( ref( $nest->$method ), ref {}, "$method is a hashref");
    is( $nest->$method->{param1}, 'val1', "$method sets correctly");
}


foreach my $method ( qw(name_label template_ext template_dir) ){
    my $default_value = $nest->$method;
    test_scalar( $method,'default',$default_value );
    my $set_value = $nest->$method('HELLO');
    test_scalar( $method,'set',$set_value );
    is($set_value,'HELLO',"set $method");
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
