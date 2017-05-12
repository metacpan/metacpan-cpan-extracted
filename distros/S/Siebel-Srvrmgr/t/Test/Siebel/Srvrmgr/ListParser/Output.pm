package Test::Siebel::Srvrmgr::ListParser::Output;

use Test::Most;
use Test::Moose 'has_attribute_ok';
use Hash::Util qw(lock_keys);
use parent 'Test::Siebel::Srvrmgr';

sub get_super {
    return 'Siebel::Srvrmgr::ListParser::Output';
}

sub is_super {
    my $test = shift;
    return ( $test->class() eq $test->get_super() ) ? 1 : 0;
}

sub get_data_type {
    return 'output';
}

sub get_cmd_line {
    return 'undefined';
}

sub get_output {
    my $test = shift;
    return $test->{output};
}

# after setting the Siebel::Srvrgmr::ListParser::Output instance,
# use lock_keys to avoid subclasses to create their own references of instances
sub set_output {
    my ( $test, $value ) = @_;
    die "Invalid parameter for set_output"
      unless ( $value->isa( $test->get_super() ) );
    $test->{output} = $value;
    lock_keys( %{$test} );
    return 1;
}

# forcing to be the first method to be tested
# this predates the usage of setup and startup, but the first is expensive and the second cannot be used due parent class
sub _constructor : Tests(3) {
    my ( $test, $more_params ) = @_;
    my $params_ref = {
        data_type => $test->get_data_type(),
        raw_data  => $test->get_my_data(),
        cmd_line  => $test->get_cmd_line(),
    };

    if ( ( defined($more_params) ) and ( ref($more_params) eq 'HASH' ) ) {

        foreach my $key ( keys( %{$more_params} ) ) {
            $params_ref->{$key} = $more_params->{$key};
        }

    }

  SKIP: {

        skip $test->class()
          . ' is an abstract class and cannot have an instance ', 2
          if ( $test->is_super() );
        ok( $test->set_output( $test->class()->new($params_ref) ),
            'the constructor should succeed' );
        isa_ok( $test->get_output(), $test->class() );

    }

  SKIP: {

        skip $test->class()
          . ' subclass should not cause an exception with new()', 1
          unless ( $test->is_super() );
        dies_ok(
            sub {
                $test->class()->new($params_ref);
            },
            $test->get_super() . ' new() causes an exception'
        );

    }

}

sub class_attributes : Tests {
    my ( $test, $attribs_ref ) = @_;

    my @attribs =
      ( 'data_type', 'raw_data', 'data_parsed', 'cmd_line', 'clear_raw' );

    if ( ( defined($attribs_ref) ) and ( ref($attribs_ref) eq 'ARRAY' ) ) {

        foreach my $attrib ( @{$attribs_ref} ) {
            push( @attribs, $attrib );
        }

    }

    $test->num_tests( scalar(@attribs) );

    foreach my $attrib (@attribs) {
        has_attribute_ok( $test->get_test_item(), $attrib );
    }

}

# this method returns an Siebel::Srvrmgr::ListParser::Output object or the class name
# if the instance does not exists
sub get_test_item {

    my $test = shift;

    if ( defined( $test->get_output() )
        and $test->get_output()->isa( $test->class() ) )
    {

        return $test->get_output();

    }
    else {

        return $test->class();

    }

}

sub class_methods : Tests {
    my ( $test, $methods_ref ) = @_;
    my @methods = (
        'get_data_type',   'get_raw_data',
        'set_raw_data',    'get_data_parsed',
        'set_data_parsed', 'get_cmd_line',
        'parse',           'BUILD',
        'clear_raw',       'set_clear_raw'
    );

    if ( ( defined($methods_ref) ) and ( ref($methods_ref) eq 'ARRAY' ) ) {

        foreach my $method ( @{$methods_ref} ) {
            push( @methods, $method );
        }

    }

    $test->num_tests( ( scalar(@methods) ) + 6 );
    can_ok( $test->get_test_item(), @methods );

  SKIP: {

        skip $test->get_super() . ' does not have instance for those tests', 6
          if ( $test->is_super() );
        is(
            $test->get_output()->get_data_type(),
            $test->get_data_type(),
            'get_data_type() returns the correct value'
        );
        is( ref( $test->get_output()->get_raw_data() ),
            'ARRAY', 'get_raw_data() returns a array reference' );
        ok(
            $test->get_output()->set_raw_data( $test->get_my_data() ),
            'set_raw_data accepts an array reference as parameter'
        );
        is( ref( $test->get_output()->get_data_parsed() ),
            'HASH', 'get_data_parsed returns an hash reference' );
        my $old_ref = $test->get_output()->get_data_parsed();
        ok(
            $test->get_output()
              ->set_data_parsed( { one => 'value', two => 100 } ),
            'set_data_parsed accepts an hash reference as parameter'
        );

        # restore the original value
        $test->get_output()->set_data_parsed($old_ref);
        is( $test->get_output()->get_cmd_line(),
            $test->get_cmd_line(), 'get_cmd_line returns the correct string' );

    }

}

1;
