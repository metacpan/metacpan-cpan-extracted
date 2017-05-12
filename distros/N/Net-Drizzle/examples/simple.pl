use strict;
use warnings;
use Net::Drizzle ':constants';

my $con = Net::Drizzle::Connection->new
                                  ->set_tcp('127.0.0.1', 9495)
                                  ->add_options(DRIZZLE_CON_MYSQL)
                                  ->set_db("information_schema");
my $s = $con->query_str("SELECT table_schema,table_name FROM tables");
$s->buffer;

die if $s->error_code != 0;
while (my $row = $s->row_next) {
    print "@$row\n";
}

