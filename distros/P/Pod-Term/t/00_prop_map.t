use Test::More;

BEGIN{ use_ok('Pod::Term') };

my $parser = Pod::Term->new;

isa_ok( $parser, 'Pod::Term',  "->new returns a Pod::Term" );


my $prop_map = $parser->prop_map;

is( ref $prop_map, ref {}, "->prop_map returns a hashref" );

my @el_names = (
    'head1',
    'head2',
    'head3',
    'head4',
    'over-text',
    'over-number',
    'over-bullet',
    'item-text',
    'item-number',
    'item-bullet',
    'B',
    'C',
    'I',
    'L',
    'E',
    'F',
    'S',
    'Para',
    'Verbatim',
    'Document'
);

my %test_props = (
    indent => 5,
    after_indent => 2,
    color => 'green',
    top_spacing => 3,
    bottom_spacing => 4,
    prepend => { text => 'prepend' },
    append => { text => 'append' }
);


my $test_set_props = {
    Document => {
        indent => 2,
        after_indent => 6,
        color => 'blue',
        top_spacing => 4,
        bottom_spacing => 6,
        prepend => { text => 'doc_pre' },
        append => { text => 'doc_app' }
    },
    head1 => {    
        indent => 1,
        after_indent => 3,
        color => 'white',
        top_spacing => 4,
        bottom_spacing => 2,
        prepend => { text => 'head1_pre' },
        append => { text => 'head1_ap' }
    }
};


foreach my $el_name ( @el_names ){

    my $prop_hash = $prop_map->{$el_name};

    is( ref ( $prop_hash ), ref {}, "->prop_map->{$el_name} is a hashref");
    like( $prop_hash->{display}, qr/^(block|inline)$/, "$el_name has a valid display attribute");

    if ( $prop_hash->{display} eq 'block' ){

        my $stacking = $prop_hash->{stacking};

        like( $prop_hash->{stacking}, qr/^(nest|revert|spot)$/, "$el_name has valid stacking" );

    }

    foreach my $prop_name (keys %test_props){
        $parser->set_prop($el_name,$prop_name, $test_props{$prop_name});
        is_deeply( 
            $test_props{$prop_name}, 
            $parser->prop_map->{$el_name}->{$prop_name},
            "->set_prop sets property $prop_name correctly for element $el_name"
        );
    }    

}


$parser->set_props( $test_set_props );
foreach my $el_name ( keys %$test_set_props ){
    foreach my $prop_name (keys %{$test_set_props->{$el_name}}){
        is_deeply( 
            $parser->prop_map->{$el_name}->{$prop_name},
            $test_set_props->{$el_name}->{$prop_name},
            "->set_props set property $prop_name correctly for element $el_name"
        );
    }
}

    

my $globals = $parser->globals;
is( ref $globals, ref {}, '->globals returns a hashref' );

my $max_cols = $globals->{max_cols};
like( $max_cols, qr/^\d+/, "max_cols is numeric" );
cmp_ok( $max_cols, ">", 0, "max_cols is positive" );

done_testing();
