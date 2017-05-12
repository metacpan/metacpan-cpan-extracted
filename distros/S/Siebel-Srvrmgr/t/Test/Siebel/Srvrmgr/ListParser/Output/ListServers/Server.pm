package Test::Siebel::Srvrmgr::ListParser::Output::ListServers::Server;

use Test::Most;
use Test::Moose;
use parent 'Test::Siebel::Srvrmgr';
use Siebel::Srvrmgr::ListParser::Output::Tabular::ListServers;
use Regexp::Common 0.07 qw(time);

sub get_struct {
    my $test = shift;
    return $test->{structure_type};
}

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

# :TODO:11-01-2014:: should refactor this because behavior is the same for other classes (maybe a Role?)
# overriding parent's because the files will have the command itself followed by the output of it
sub get_my_data {
    my $test     = shift;
    my $data_ref = $test->SUPER::get_my_data();
    shift( @{$data_ref} );    #command
    shift( @{$data_ref} );    #new line
    return $data_ref;
}

sub _constructor : Tests(2) {
    my $test = shift;
    my $list;
    note('creating an instance with real data');
    if ( ( $test->get_struct eq 'delimited' ) and ( $test->get_col_sep ) ) {
        $list = Siebel::Srvrmgr::ListParser::Output::Tabular::ListServers->new(
            {
                data_type      => 'list_servers',
                raw_data       => $test->get_my_data(),
                cmd_line       => 'list server',
                structure_type => $test->get_struct(),
                col_sep        => $test->get_col_sep()
            }
        );
    }
    else {
        $list = Siebel::Srvrmgr::ListParser::Output::Tabular::ListServers->new(
            {
                data_type      => 'list_servers',
                raw_data       => $test->get_my_data(),
                cmd_line       => 'list server',
                structure_type => $test->get_struct()
            }
        );
    }

    my $iterator = $list->get_servers_iter;
    $test->{server} = $iterator->();
    isa_ok( $test->{server}, $test->class(),
        'the object is a instance of the correct class' );
}

sub class_attributes : Tests(9) {
    my $test = shift;
    my @attribs =
      (qw(name group host install_dir pid disp_state state status id));

    foreach my $attrib (@attribs) {
        has_attribute_ok( $test->{server}, $attrib );
    }
}

sub class_methods : Tests(3) {
    my $test = shift;
    can_ok(
        $test->{server},
        (
            qw(get_name get_group get_host get_install_dir get_pid get_disp_state get_state get_status get_id)
        )
    );
    does_ok(
        $test->{server},
        'Siebel::Srvrmgr::ListParser::Output::ToString',
        'instance does ToString role'
    );
    does_ok(
        $test->{server},
        'Siebel::Srvrmgr::ListParser::Output::Duration',
        'instance does Duration role'
    );

}

1;

