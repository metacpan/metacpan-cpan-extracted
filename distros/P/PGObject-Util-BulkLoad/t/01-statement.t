use PGObject::Util::BulkLoad;
use Test::More tests => 12;

sub normalize_whitespace {
    my $string = shift;
    $string =~ s/\s+/ /g;
    $string;
}

my $convert1 = {
   insert_cols => [qw(foo bar baz)], 
   update_cols => [qw(foo bar)],
   key_cols    => ['baz'],
group_stats_by => ['foo'],
   table       => 'foo',
   tempname    => 'tfoo',
   stmt        => {
           copy => 'COPY "foo"("foo", "bar", "baz") FROM STDIN WITH CSV',
           temp => 'CREATE TEMPORARY TABLE "tfoo" ( LIKE "foo" )',
         upsert => 'WITH UP AS (
                       UPDATE "foo" SET "foo" = "tfoo"."foo", "bar" = "tfoo"."bar"
                         FROM "tfoo"
                        WHERE "foo"."baz" = "tfoo"."baz"
                    RETURNING "foo"."baz"
                  )
                  INSERT INTO "foo" ("foo", "bar", "baz")
                  SELECT "foo", "bar", "baz" FROM "tfoo"
                  WHERE ROW("tfoo"."baz") NOT IN (SELECT UP."baz" FROM UP)',
           stats => 
                   'SELECT "tfoo"."foo", 
                     SUM(CASE WHEN ROW("foo"."baz") IS NULL THEN 1 ELSE 0 END)
                          AS pgobject_bulkload_inserts,
                     SUM(CASE WHEN ROW("foo"."baz") IS NULL THEN 0 ELSE 1 END)
                          AS pgobject_bulkload_updates
                     FROM "tfoo"
                LEFT JOIN "foo" USING ("baz")
                 GROUP BY "tfoo"."foo"',
                   
                  },
};

my $convert2 = {
   insert_cols => [qw(foo bar baz)],
   update_cols => [qw(foo)],
   key_cols    => [qw(bar baz)],
group_stats_by => ['foo', 'bar'],
   table       => 'foo',
   tempname    => 'tfoo',
   stmt        => {
           copy => 'COPY "foo"("foo", "bar", "baz") FROM STDIN WITH CSV',
           temp => 'CREATE TEMPORARY TABLE "tfoo" ( LIKE "foo" )',
         upsert => 'WITH UP AS (
                       UPDATE "foo" SET "foo" = "tfoo"."foo"
                         FROM "tfoo"
                        WHERE "foo"."bar" = "tfoo"."bar" AND "foo"."baz" = "tfoo"."baz"
                    RETURNING "foo"."bar", "foo"."baz"
                  )
                  INSERT INTO "foo" ("foo", "bar", "baz")
                  SELECT "foo", "bar", "baz" FROM "tfoo"
                  WHERE ROW("tfoo"."bar", "tfoo"."baz") NOT IN (SELECT UP."bar", UP."baz" FROM UP)',
           stats => 
                   'SELECT "tfoo"."foo", "tfoo"."bar",
                     SUM(CASE WHEN ROW("foo"."bar", "foo"."baz") IS NULL THEN 1 ELSE 0 END)
                          AS pgobject_bulkload_inserts,
                     SUM(CASE WHEN ROW("foo"."bar", "foo"."baz") IS NULL THEN 0 ELSE 1 END)
                          AS pgobject_bulkload_updates
                     FROM "tfoo"
                LEFT JOIN "foo" USING ("bar", "baz")
                 GROUP BY "tfoo"."foo", "tfoo"."bar"',
                  },
};

my $convert3 = {
   insert_cols => [qw(fo"o" bar b"a"z)],
   update_cols => [qw(fo"o" bar)],
   key_cols    => [qw(b"a"z)],
group_stats_by => [qw(b"a"z)],
   table       => 'foo',
   tempname    => 'tfoo',
   stmt        => {
           copy => 'COPY "foo"("fo""o""", "bar", "b""a""z") FROM STDIN WITH CSV',
           temp => 'CREATE TEMPORARY TABLE "tfoo" ( LIKE "foo" )',
         upsert => 'WITH UP AS (
                       UPDATE "foo" SET "fo""o""" = "tfoo"."fo""o""", "bar" = "tfoo"."bar"
                         FROM "tfoo"
                        WHERE "foo"."b""a""z" = "tfoo"."b""a""z"
                    RETURNING "foo"."b""a""z"
                  )
                  INSERT INTO "foo" ("fo""o""", "bar", "b""a""z")
                  SELECT "fo""o""", "bar", "b""a""z" FROM "tfoo"
                  WHERE ROW("tfoo"."b""a""z") NOT IN (SELECT UP."b""a""z" FROM UP)',
           stats => 
                   'SELECT "tfoo"."b""a""z",
                     SUM(CASE WHEN ROW("foo"."b""a""z") IS NULL THEN 1 ELSE 0 END)
                          AS pgobject_bulkload_inserts,
                     SUM(CASE WHEN ROW("foo"."b""a""z") IS NULL THEN 0 ELSE 1 END)
                          AS pgobject_bulkload_updates
                     FROM "tfoo"
                LEFT JOIN "foo" USING ("b""a""z")
                 GROUP BY "tfoo"."b""a""z"',
                  },
};

for my $stype (qw(temp copy upsert stats)){
    my $iter = 0;
    is(normalize_whitespace(PGObject::Util::BulkLoad::statement(%$_)), 
       normalize_whitespace($_->{stmt}->{$stype}),
       "$stype for convert$_->{iter}")
        for map {
          { (%$_, type => $stype, iter => ++$iter) }
        } ($convert1, $convert2, $convert3);
}
