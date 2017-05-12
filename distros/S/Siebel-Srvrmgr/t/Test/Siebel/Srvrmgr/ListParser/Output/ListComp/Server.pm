package Test::Siebel::Srvrmgr::ListParser::Output::ListComp::Server;

use Test::Most;
use Test::Moose qw(has_attribute_ok);
use parent 'Test::Siebel::Srvrmgr';
use Siebel::Srvrmgr::ListParser::Output::Tabular::ListComp;

# :TODO:11-01-2014:: refactor the method below because Tabular does the same (maybe a Role?)
sub get_structure_type {
    my $test = shift;
    return $test->{structure_type};
}

# :TODO:11-01-2014:: refactor the method below because Tabular does the same (maybe a Role?)
sub get_col_sep {
    my $test = shift;
    return $test->{col_sep};
}

sub set_timezone : Test(startup) {
    $ENV{SIEBEL_TZ} = 'America/Sao_Paulo';
}

sub unset_timezone : Test(shutdown) {
    delete $ENV{IEBEL_TZ};
}

sub _constructor : Tests(+2) {
    my $test = shift;
    #must parse the output
    my $list_comp;
# :TODO:11-01-2014:: refactor the method below because Tabular does the same (maybe a Role?)
    if ( $test->get_col_sep() ) {
        $list_comp =
          Siebel::Srvrmgr::ListParser::Output::Tabular::ListComp->new(
            {
                data_type      => 'list_comp',
                raw_data       => $test->get_my_data(),
                cmd_line       => 'list comp',
                structure_type => $test->get_structure_type,
                col_sep        => $test->get_col_sep()
            }
          );
    }
    else {
        $list_comp =
          Siebel::Srvrmgr::ListParser::Output::Tabular::ListComp->new(
            {
                data_type      => 'list_comp',
                raw_data       => $test->get_my_data(),
                cmd_line       => 'list comp',
                structure_type => $test->get_structure_type
            }
          );
    }

    $test->{server} = $list_comp->get_server('siebel1');
    ok( $test->{server}, 'the constructor should succeed' );
    isa_ok( $test->{server}, $test->class() );
}

# :TODO:11-01-2014:: refactor the method below because Tabular does the same (maybe a Role?)
sub get_my_data {
    my $test = shift;
    my $data_ref = $test->SUPER::get_my_data();
    shift( @{$data_ref} );    #command
    shift( @{$data_ref} );    #new line
    return $data_ref;
}

sub class_methods : Tests(4) {
    my $test = shift;
    can_ok( $test->{server},
        qw(new get_data get_name store get_comps get_comp) );
    is( $test->{server}->get_name(),
        'siebel1', 'get_name returns the correct value' );
    isa_ok(
        $test->{server}->get_comp('ServerMgr'),
        'Siebel::Srvrmgr::ListParser::Output::ListComp::Comp',
        'get_comp("ServerMgr") returns a Comp object'
    );
    isa_ok( $test->{server}->get_comps(),
        'ARRAY', 'get_comps returns an array reference' );
}

sub class_attributes : Tests(no_plan) {
    my $test = shift;
    my @attribs = qw(name data comp_attribs);
    $test->num_tests( scalar(@attribs) );

    foreach my $attrib (@attribs) {
        has_attribute_ok( $test->{server}, $attrib );
    }
}

1;

