use strict;
use warnings;
use Net::Drizzle ':constants';
use IO::Socket::INET;
use Test::TCP;
use Test::More tests => 3;
use xt::Server;

test_tcp(
    client => sub {
        my $port = shift;

        my $con = Net::Drizzle::Connection->new()
                                          ->set_tcp('127.0.0.1', $port)
                                          ->add_options(DRIZZLE_CON_MYSQL)
                                          ->set_db("information_schema");
        my $res = $con->query_str("SELECT table_schema,table_name FROM tables");

        do {
            my @column_names;
            while (my $col = $res->column_read) {
                push @column_names, $col->name;
            }
            is join(',', @column_names), "test_column_1,test_column_2";
        };

        do {
            my @got;
            while ((my $row = $res->row_read) != 0) {
                my @row;
                FIELD_LOOP:
                while (1) {
                    my ($ret, $field) = $res->field_buffer();
                    if ($ret == DRIZZLE_RETURN_ROW_END) {
                        last FIELD_LOOP;
                    }
                    push @row, $field;
                }
                push @got, \@row;
            }
            is($res->error_code, 0);
            is_deeply(\@got, server_rows());
        };
    },
    server => sub {
        xt::Server->run(shift);
    },
);

