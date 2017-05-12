package Test::Siebel::Srvrmgr::ListParser::Output::Tabular::Struct;

use Test::Most;
use Test::Moose 'has_attribute_ok';
use Hash::Util qw(lock_keys);
use parent 'Test::Siebel::Srvrmgr';
use Carp;

sub get_super {

    return 'Siebel::Srvrmgr::ListParser::Output::Tabular::Struct';

}

sub is_super {

    my $test = shift;
    return ( $test->class() eq $test->get_super() ) ? 1 : 0;

}

sub get_struct {

    my $test = shift;
    return $test->{struct};

}

sub get_sep {

    return '\s{2,}';

}

sub get_cols {

    return [qw(one two three four five six seven eight nine ten)];

}

# after setting the Siebel::Srvrgmr::ListParser::Output instance,
# use lock_keys to avoid subclasses to create their own references of instances
sub set_struct {

    my $test  = shift;
    my $value = shift;

    confess 'Invalid parameter'
      unless ( $value->isa( $test->get_super() ) );

    $test->{struct} = $value;

    lock_keys( %{$test} );

    return 1;

}

# forcing to be the first method to be tested
# this predates the usage of setup and startup, but the first is expensive and the second cannot be used due parent class
sub _constructor : Tests(2) {

    my $test        = shift;
    my $more_params = shift;

    my $params_ref = { header_cols => $test->get_cols() };

    if ( ( defined($more_params) ) and ( ref($more_params) eq 'HASH' ) ) {

        foreach my $key ( keys( %{$more_params} ) ) {

            $params_ref->{$key} = $more_params->{$key};

        }

    }

    ok( $test->set_struct( $test->class()->new($params_ref) ),
        'the constructor succeed' );
    isa_ok( $test->get_struct(), $test->class() );

}

sub class_attributes : Tests(no_plan) {

    my $test        = shift;
    my $attribs_ref = shift;

    my @attribs = (qw(header_regex col_sep header_cols));

    if ( ( defined($attribs_ref) ) and ( ref($attribs_ref) eq 'ARRAY' ) ) {

        foreach my $attrib ( @{$attribs_ref} ) {

            push( @attribs, $attrib );

        }

    }

    $test->num_tests( scalar(@attribs) );

    foreach my $attrib (@attribs) {

        has_attribute_ok( $test->get_struct(), $attrib );

    }

}

sub get_to_split {

    return 'AAAA  BBBB  CCCC';

}

sub get_fail_split {

    return 'AAAA#BBBB#CCCC';

}

sub class_methods : Tests(no_plan) {

    my $test        = shift;
    my $methods_ref = shift;

    my @methods = (
        qw(get_fields _build_header_regex _set_header_regex get_header_regex _set_col_sep get_col_sep get_header_cols _set_header_cols split_fields define_fields_pattern _build_col_sep)
    );

    if ( ( defined($methods_ref) ) and ( ref($methods_ref) eq 'ARRAY' ) ) {

        foreach my $method ( @{$methods_ref} ) {

            push( @methods, $method );

        }

    }

    $test->num_tests( ( scalar(@methods) ) + 7 );

    can_ok( $test->get_struct(), @methods );

  SKIP: {

        skip 'Superclass would generate an exception in this case', 4
          if ( $test->is_super() );

        is( $test->get_struct()->get_col_sep(),
            $test->get_sep(), 'get_col_sep returns the correct value' );
        is_deeply(
            $test->get_struct()->split_fields( $test->get_to_split() ),
            [qw(AAAA BBBB CCCC)],
            'split_fields returns an array reference with the correct fields'
        );
        is(
            $test->get_struct()->split_fields( $test->get_fail_split() ),
            undef,
            'split_fields returns undef if the separator cannot be matched'
        );

    }

    is_deeply( $test->get_struct()->get_header_cols(),
        $test->get_cols(), 'get_header_cols returns the correct value' );

  SKIP: {

        skip 'Only superclass will generate an exception in this case', 2
          unless ( $test->is_super() );

        dies_ok(
            sub { $test->get_struct()->define_fields_pattern() },
            'define_fields_patterns dies because it is not implemented'
        );

        dies_ok(
            sub { $test->get_struct()->get_fields() },
            'get_fields dies because it is not implemented'
        );

    }

}

1;
