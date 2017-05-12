# Example application: order/inventory database.
# This is intended as an example, not as anything useful.

use SQL::Interpolate FILTER => 1, qw(:all);
use DBIx::Interpolate;
use Data::Dumper;

my $dsn  = "dbi:SQLite:dbname=test.sqlt";
my $user = "";
my $pass = "";

unlink('test.sqlt');

my $dbh = &connect();
&create_db($dbh);
&fill_inventory($dbh);
&modify_inventory($dbh);
&display_inventory1($dbh, 0);
&display_inventory1($dbh, 1);


sub connect
{
    my $dbx = DBIx::Interpolate->connect(
        $dsn, $user, $pass,
        {RaiseError => 1, AutoCommit => 1}
    );
}

sub create_db
{
    my($dbx) = @_;
    $dbx->do( sql[
        CREATE TABLE customer(
            id      INTEGER PRIMARY KEY,
            name    STRING,
            company STRING  INTEGER,
            email   STRING
        )
    ] );

    $dbx->do( sql[
        CREATE TABLE inventory(
            partnum INTEGER PRIMARY KEY,
            desc    STRING,
            price   DOUBLE,
            stock   INTEGER
        )
    ] );
}

sub fill_inventory
{
    my($dbx) = @_;

    my $item = {
        desc  => 'thing',
        price => 1.00,
        stock => 10
    };
    for(my $idx = 0; $idx < 10; $idx++) {
        $$item{price}++;
        $$item{desc} = 'thing-' . chr(ord('a') + $idx);
        
        $dbx->do(sql[
            INSERT INTO inventory $item
        ]);
    }
}

sub modify_inventory
{
    my($dbx) = @_;

    my @others = ('thing-e', 'thing-g');
    $dbx->do( sql[
        UPDATE inventory
        SET {stock => 2*4}
        WHERE desc IN ['thing-a', @others]
    ]);
}

sub display_inventory1
{
    my($dbx, $show_all) = @_;
    my $price = 3.00;
    my $stocks = [0, 8];
    # Example: combining two sql fragments.
    my $items = $dbx->selectall_arrayref(
        sql[
            SELECT partnum, desc, price, stock
            FROM inventory
        ],
        $show_all
            ? ()
            : sql[WHERE price > $price AND stock IN $stocks]
    );

    print Dumper($items);
}
