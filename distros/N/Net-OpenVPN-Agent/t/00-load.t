use Test::More tests => 1;

BEGIN {
    use_ok( 'Net::OpenVPN::Agent' ) || print "Bail out!\n";
}

diag( "Testing Net::OpenVPN::Agent $Net::OpenVPN::Agent::VERSION, Perl $], $^X" );
