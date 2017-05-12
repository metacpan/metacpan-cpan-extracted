use strict;
use Data::Dumper;
use Test;


# use a BEGIN block so we print our plan before modules are loaded
BEGIN { plan tests => 7 }

# load modules
use Net::LibLO;

# Create objects
my $lo = new Net::LibLO();
ok( $lo );

# Add methods
$lo->add_method( '/integer', 'i', \&integer_handler );
$lo->add_method( '/string', 's', \&string_handler );
$lo->add_method( '/double', 'd', \&double_handler );
$lo->add_method( '/char', 'c', \&char_handler );
ok( 1 );

# Send messages
fork_client( $lo->get_url() );

# Wait for four messages
foreach(1..4) {
	my $result = $lo->recv_noblock( 1000 );
	if ($result <= 0) {
		warn "Timed out waiting for message.";
	}
}


# Destroy the LibLO object
undef $lo;
ok( 1 );

exit;





sub string_handler {
	my ($serv, $mesg, $path, $typespec, $userdata, @params) = @_;
	print "# $path '$typespec' ".join(', ',@params)."\n";
	ok( $params[0] eq 'ABCDEFG' );
}

sub integer_handler {
	my ($serv, $mesg, $path, $typespec, $userdata, @params) = @_;
	print "# $path '$typespec' ".join(', ',@params)."\n";
	ok( $params[0] == 1287 );
}

sub double_handler {
	my ($serv, $mesg, $path, $typespec, $userdata, @params) = @_;
	print "# $path '$typespec' ".join(', ',@params)."\n";
	ok( $params[0] == 87.7 );
}

sub char_handler {
	my ($serv, $mesg, $path, $typespec, $userdata, @params) = @_;
	print "# $path '$typespec' ".join(', ',@params)."\n";
	ok( $params[0] eq 'K' );
}


sub fork_client {
	my ($url) = @_;
	
	# Send messages from a seperate process
	if (fork()==0) {
		my $lo = new Net::LibLO();
		$lo->send( $url, '/integer', 'i', 1287 );
		$lo->send( $url, '/string', 's', 'ABCDEFG' );
		$lo->send( $url, '/double', 'd', 87.7 );
		$lo->send( $url, '/char', 'c', 'K' );
		exit;
	}
}

