#   -*- perl -*-

#  Kill two birds with one stone; re-org and reschema

use lib "t/musicstore";
use Prerequisites;
use strict;

use Test::More tests => 4;
use Tangram::Storage;

my $old_schema = MusicStore->schema;
my $new_schema = MusicStore->new_schema;


DBConfig->dialect->deploy($new_schema, DBConfig->cparm);
pass("deployed new schema successfully");

{
    my $storage_old = DBConfig->dialect->connect($old_schema, DBConfig->cparm);
    pass("connected to old schema");

    my $storage_new = DBConfig->dialect->connect($new_schema, DBConfig->cparm);
    pass("connected to new schema");

    my @oids = $storage_new->insert($storage_old->select("CD::Artist"));
    pass("inserted data into database (new oids: @oids)");

}

__END__
