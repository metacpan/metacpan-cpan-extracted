use strict;
use warnings;
use Net::Drizzle;

my @s;
my $limit = 10;

my $dr = Net::Drizzle->new;
my $c1 = $dr->con_create()
            ->add_options(Net::Drizzle::DRIZZLE_CON_MYSQL)
            ->set_db("information_schema");
for (0..$limit) {
    push @s, $c1->clone->query_add("SELECT table_schema,table_name FROM tables");
}

$dr->query_run_all();

for my $i (0..$limit) {
    my $s = $s[$i];

    die if $s->error_code != 0;
    while (my $row = $s->row_next) {
        print "$i:@$row\n";
    }
}

