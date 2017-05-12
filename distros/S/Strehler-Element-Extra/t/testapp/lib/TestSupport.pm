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
    $schema->resultset('Artwork')->delete_all();
    $schema->resultset('Artdescription')->delete_all();
}

1;

