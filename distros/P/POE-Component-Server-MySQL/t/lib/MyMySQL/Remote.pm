package MyMySQL::Remote;

use MooseX::MethodAttributes::Role;

use Data::Dumper;
use DBI;

my $local_dbh;

sub remote : Regexp('qr{(((INSERT INTO (.*)|(.*)))SELECT REMOTE (.*?)(?:$|\)|ON (.*)))}io') { #'
   my ($self, $query, @placeholders) = @_;


}

1;
