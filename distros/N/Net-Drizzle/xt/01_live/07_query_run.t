use strict;
use warnings;
use Test::More;
use Net::Drizzle ':constants';
use Devel::Peek;

my $cons = 10;
plan tests => ($cons) * 6;

&main;exit;

sub main {
    my $dr = Net::Drizzle->new
                        ->add_options(DRIZZLE_NON_BLOCKING);

    printf "%X\n", $$dr;
    setup($dr);
    aggregate($dr);
}

sub setup {
    my $dr = shift;

    my $query = "SELECT table_schema,table_name FROM tables";
    my $c1 = $dr->con_create
                ->add_options(DRIZZLE_CON_MYSQL)
                ->set_db("information_schema");
    for (1..$cons) {
        my $q = $c1->clone->query_add($query);
        isa_ok $q->con, 'Net::Drizzle::Connection';
    }
}

sub aggregate {
    my $dr = shift;

    my $queries = $cons;
    while (1) {
        my ($ret, $query) = $dr->query_run();
        if ($query) {
            $queries--;
            is $query->string, 'SELECT table_schema,table_name FROM tables', 'query';
            my $result = $query->result;
            check_result($result);
            $query->con->close;
            if ($queries == 0) {
                return;
            }
        }
        $dr->con_wait();
    }
}

sub check_result {
    my $s = shift;
    is $s->error_code, 0;
    is $s->error, '';
    is $s->info, '';
    is $s->column_count, 2;
}

