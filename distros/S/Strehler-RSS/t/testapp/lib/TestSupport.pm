package TestSupport;

use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/testapp/lib";
use JSON;
use Dancer2;
use Dancer2::Plugin::DBIC;
use HTTP::Request;
use HTTP::Request::Common;
use Strehler::Meta::Category;

sub reset_database
{
    my $schema = config->{'Strehler'}->{'schema'} ? schema config->{'Strehler'}->{'schema'} : schema;
    $schema->resultset('Rsschannel')->delete_all();
    $schema->resultset('RsschannelHeader')->delete_all();
}

1;

