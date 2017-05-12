package Test::Siebel::Srvrmgr::Daemon::Action::Dumper;

use parent qw(Test::Siebel::Srvrmgr::Daemon::Action);
use Test::More;

sub class_methods : Test(+1) {

    my $test = shift;

    {

        local *STDOUT;

        open( STDOUT, '>', \$test_data )
          or die "Failed to redirect STDOUT to in-memory file: $!";

     	$test->{action}->do( $test->get_my_data() );

        like(
            $test_data,
            qr/Siebel::Srvrmgr::ListParser::Output::Tabular::ListComp/,
            'Dumper output matches expected regular expression'
        );

    }

}

1;
