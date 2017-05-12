use strict;
use warnings FATAL => 'all';
use Supervisord::Client;
use Data::Dumper::Concise;
#my $client = Supervisord::Client->new( path_to_supervisor_config => $ARGV[0] );
my $client = Supervisord::Client->new( path_to_supervisor_config => $ARGV[0], username => 'supervisor_user', password => 'supervisor_password' );
print Dumper( $client->getAllProcessInfo );
