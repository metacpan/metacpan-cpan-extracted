use strict;
use warnings;
use Net::Drizzle ':constants';
use IO::Socket::INET;
use Test::TCP;
use Test::More tests => 2;
use xt::Server;

test_tcp(
    client => sub {
        my $port = shift;

        my $con = Net::Drizzle::Connection->new()
                                          ->set_tcp('127.0.0.1', $port)
                                          ->add_options(DRIZZLE_CON_MYSQL)
                                          ->set_db("information_schema");
        my $sth = $con->query_str("SELECT table_schema,table_name FROM tables");
        $sth->buffer();
        is($sth->error_code, 0);
        my @got;
        while (my $row = $sth->row_next) {
            push @got, $row;
        }
        is_deeply(\@got, server_rows());
    },
    server => sub {
        xt::Server->run(shift);
    },
);

