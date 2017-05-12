use strict;
use warnings;
use Net::Drizzle;
use Benchmark ':all';
use Devel::Peek;
use DBI;
use DBD::mysql;

print "Net::Drizzle: $Net::Drizzle::VERSION\n";
print "DBD::mysql:   $DBD::mysql::VERSION\n";
print "DBI: $DBI::VERSION\n";

my $limit = 20;

cmpthese(
    1000 => {
        concurrent  => \&concurrent,
        serial      => \&serial,
        dbd_mysql   => \&dbd_mysql,
  #     dbd_drizzle => \&dbd_drizzle,
    },
);

sub dbd_mysql {
    for my $i (0..$limit) {
        my $dbh = DBI->connect('dbi:mysql:database=information_schema', 'root', '') or die;
        my $sth = $dbh->prepare("SELECT table_schema,table_name FROM tables");
        $sth->execute or die;
        while (my $row = $sth->fetchrow_arrayref) {
            # nop
        }
    }
}

# DBD::Drizzle is not works :(
sub dbd_drizzle {
    for my $i (0..$limit) {
        my $dbh = DBI->connect('dbi:drizzle:database=information_schema;host=localhost', undef, undef, {PrintError => 1, RaiseError => 1}) or die;
        my $sth = $dbh->prepare("SELECT table_schema,table_name FROM tables");
        $sth->execute or die;
        while (my $row = $sth->fetchrow_arrayref) {
            # nop
        }
    }
}

sub serial {
    for my $i (0..$limit) {
        my $con = Net::Drizzle::Connection->new;
        $con->add_options(Net::Drizzle::DRIZZLE_CON_MYSQL);
        $con->set_db("information_schema");
        my $s = $con->query_str("SELECT table_schema,table_name FROM tables");
        $s->buffer;

        die if $s->error_code != 0;
        while (my $row = $s->row_next) {
            # nop
        }
    }
}

sub concurrent {
    my @s;
    my $dr = Net::Drizzle->new;
    my $c1 = $dr->con_create;
    $c1->add_options(Net::Drizzle::DRIZZLE_CON_MYSQL);
    $c1->set_db("information_schema");
    for (0..$limit) {
        my $c = $c1->clone;
        push @s, $c->query_add("SELECT table_schema,table_name FROM tables");
    }

    $dr->query_run_all();

    for my $i (0..$limit) {
        my $s = $s[$i];

        die if $s->error_code != 0;
        while (my $row = $s->row_next) {
            # nop
        }
    }
}
