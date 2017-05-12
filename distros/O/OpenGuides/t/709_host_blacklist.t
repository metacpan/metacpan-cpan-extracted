use strict;

use OpenGuides;
use OpenGuides::Test;
use Test::More;
use Wiki::Toolkit::Setup::SQLite;

eval { require DBD::SQLite; };
if ( $@ ) {
    my ($error) = $@ =~ /^(.*?)\n/;
    plan skip_all => "DBD::SQLite could not be used - no database to test with. ($error)";
}

plan tests => 1;

# Clear out the database from any previous runs.
    OpenGuides::Test::refresh_db();

# Set up a guide which uses a spam detector module.
my $config = OpenGuides::Test->make_basic_config;
$config->host_checker_module( "OpenGuides::Local::HostBlacklist" );
my $guide = OpenGuides->new( config => $config );

# Ensure CGI tells us what we expect to hear.
sub fake {'127.0.0.1'}

use CGI;
{
    no warnings 'once';
    *CGI::remote_host = \&fake;
}

my $output = $guide->display_node(
                                     id            => "Nonesuch",
                                     return_output => 1,
                                 );

like($output, qr/Access denied/, 'host blacklist picks up IP');

package OpenGuides::Local::HostBlacklist;

sub blacklisted_host {
    my ( $class, $host ) = @_;

	if ( $host =~ /^127/ ) {
        return 1;
    }

    return 0;
}
