package SQL::Schema::Versioned;

our $DATE = '2018-05-10'; # DATE
our $VERSION = '0.235'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Exporter qw(import);
our @EXPORT_OK = qw(
                       create_or_update_db_schema
               );

our %SPEC;

sub _sv_key {
    my $comp = $_[0] // 'main';
    $comp =~ /\A\w+\z/
        or die "Invalid component '$comp', please stick to ".
        "letters/numbers/underscores";
    "schema_version" . ($comp eq 'main' ? '' : ".$comp");
}

sub _extract_created_tables_from_sql_statements {
    my @sql = @_;

    my @res;
    for my $sql (@sql) {
        if ($sql =~ /\A\s*
                     create\s+table(?:\s+if\s+not\s+exists)?\s+
                     (?:
                         `([^`]+)` |
                         "([^"]+)" |
                         (\S+)
                     )
                    /isx) {
            push @res, ($1 // $2 // $3);
        }
    }
    @res;
}

sub _get_provides_from_db {
    my ($dbh) = @_;

    my %provides;

    my $sth = $dbh->prepare(
        "SELECT name, value FROM meta WHERE name LIKE 'table.%'");
    $sth->execute;
    while (my @row = $sth->fetchrow_array) {
        my ($table) = $row[0] =~ /table\.(.+)/;
        my ($provcomp, $provver) = $row[1] =~ /\A(\w+):(\d*)\z/
            or return [500, "Corrupt information in `meta` table: $row[0] -> $row[1]"];
        $provides{$table} = [$provcomp, $provver];
    }
    %provides;
}

$SPEC{create_or_update_db_schema} = {
    v => 1.1,
    summary => 'Routine and convention to create/update '.
        'your application\'s DB schema',
    description => <<'_',

With this routine (and some convention) you can easily create and update
database schema for your application in a simple way using pure SQL.

*Version*: version is an integer and starts from 1. Each software release with
schema change will bump the version number by 1. Version information is stored
in a special table called `meta` (SELECT value FROM meta WHERE
name='schema_version').

You supply the SQL statements in `spec`. `spec` is a hash which at least must
contain the key `latest_v` (an integer) and `install` (a series of SQL
statements to create the schema from nothing to the latest version).

There should also be zero or more `upgrade_to_v$VERSION` keys, the value of each
is a series of SQL statements to upgrade from ($VERSION-1) to $VERSION. So there
could be `upgrade_to_v2`, `upgrade_to_v3`, and so on up the latest version. This
is used to upgrade an existing database from earlier version to the latest.

For testing purposes, you can also add one or more `install_v<VERSION>` key,
where `XXX` is an integer, the lowest version number that you still want to
support. So, for example, if `latest_v` is 5 and you still want to support from
version 2, you can have an `install_v2` key containing a series of SQL
statements to create the schema at version 2, and `upgrade_to_v3`,
`upgrade_to_v4`, `upgrade_to_v5` keys. This way migrations from v2 to v3, v3 to
v4, and v4 to v5 can be tested.

You can name `install_v1` key as `upgrade_to_v1` (to upgrade from 'nothing'
a.k.a. v0 to v1), which is basically the same thing.

This routine will check the existence of the `meta` table and the current schema
version. If `meta` table does not exist yet, the SQL statements in `install`
will be executed. The `meta` table will also be created and a row
`('schema_version', 1)` is added.

If `meta` table already exists, schema version will be read from it and one or
more series of SQL statements from `upgrade_to_v$VERSION` will be executed to
bring the schema to the latest version.

Aside from SQL statement, the series can also contain coderefs for more complex
upgrade process. Each coderef will be called with `$dbh` as argument and must
not die (so to signify failure, you can die from inside the coderef).

Currently only tested on MySQL, Postgres, and SQLite. Postgres is recommended
because it can do transactional DDL (a failed upgrade in the middle will not
cause the database schema state to be inconsistent, e.g. in-between two
versions).

### Modular schema (components)

This routine supports so-called modular schema, where you can separate your
database schema into several *components* (sets of tables) and then declare
dependencies among them.

For example, say you are writing a stock management application. You divide your
application into several components: `quote` (component that deals with
importing stock quotes and querying stock prices), `portfolio` (component that
deals with computing the market value of your portfolio, calculating
gains/losses), `trade` (component that connects to your broker API and perform
trading by submitting buy/sell orders).

The `quote` application component manages these tables: `daily_price`,
`spot_price`. The `portfolio` application component manages these tables:
`account` (list of accounts in stock brokerages), `balance` (list of balances),
`tx` (list of transactions). The `trade` application component manages these
tables: `order` (list of buy/sell orders).

The `portfolio` application component requires price information to be able to
calculate unrealized gains/losses. The `trade` component also needs information
from the `daily_price` e.g. to calculate 52-week momentum, and writes to the
`spot_price` to record intraday prices, and reads/writes from the `account` and
`balance` tables. Here are the `spec`s for each component:

    # spec for the price application component
    {
        component_name => 'price',
        latest_v => 1,
        provides => ['daily_price', 'spot_price'],
        install => [...],
        ...
    }

    # spec for the portfolio application component
    {
        component_name => 'portfolio',
        latest_v => 1,
        provides => ['account', 'balance', 'tx'],
        deps => {
            'daily_price' => 1,
            'spot_price'  => 1,
        },
        install => [...],
        ...
    }

    # spec for the trade application component
    {
        component_name => 'trade',
        latest_v => 1,
        provides => ['order'],
        deps => {
            'daily_price' => 1,
            'spot_price'  => 1,
            'account'     => 1,
            'balance'     => 1,
        },
        install => [...],
        ...
    }

You'll notice that the three keys new here are the `component_name`, `provides`,
and `deps`.

When `component_name` is set, then instead of the `schema_version` key in the
`meta` table, your component will use the `schema_version.<COMPONENT_NAME>` key.
When `component_name` is not set, it is assumed to be `main` and the
`schema_version` key is used in the `meta` table.

`provides` is an array of tables to help this routine know which table(s) your
component create and maintain. If unset, this routine will try to guess from
looking at "CREATE TABLE" SQL statements. It is recommended that you supply
`provides` to makes things easier.

This routine will create `table.<TABLE_NAME>` keys in the `meta` table to record
which components currently maintain which tables. The value of the key is
`<COMPONENT_NAME>:<VERSION>`. When a component no longer maintain a table in the
newest version, the corresponding `table.<TABLE_NAME>` row in the `meta` will
also be removed.

`deps` is a hash. The keys are table names that your component requires. The
values are integers, meaning the minimum version of the required table (=
component version). In the future, more complex dependency relationship and
version requirement will be supported.

_
    args => {
        spec => {
            schema => ['hash*'], # XXX require 'install' & 'latest_v' keys
            summary => 'Schema specification, e.g. SQL statements '.
                'to create and update the schema',
            req => 1,
            description => <<'_',

Example:

    {
        latest_v => 3,

        # will install version 3 (latest)
        install => [
            'CREATE TABLE IF NOT EXISTS t1 (...)',
            'CREATE TABLE IF NOT EXISTS t2 (...)',
            'CREATE TABLE t3 (...)',
        ],

        upgrade_to_v2 => [
            'ALTER TABLE t1 ADD COLUMN c5 INT NOT NULL',
            sub {
                # this subroutine sets the values of c5 for the whole table
                my $dbh = shift;
                my $sth_sel = $dbh->prepare("SELECT c1 FROM t1");
                my $sth_upd = $dbh->prepare("UPDATE t1 SET c5=? WHERE c1=?");
                $sth_sel->execute;
                while (my ($c1) = $sth_sel->fetchrow_array) {
                    my $c5 = ...; # calculate c5 value for the row
                    $sth_upd->execute($c5, $c1);
                }
            },
            'CREATE UNIQUE INDEX i1 ON t2(c1)',
        ],

        upgrade_to_v3 => [
            'ALTER TABLE t2 DROP COLUMN c2',
            'CREATE TABLE t3 (...)',
        ],

        # provided for testing, so we can test migration from v1->v2, v2->v3
        install_v1 => [
            'CREATE TABLE IF NOT EXISTS t1 (...)',
            'CREATE TABLE IF NOT EXISTS t2 (...)',
        ],
    }

_
        },
        dbh => {
            schema => ['obj*'],
            summary => 'DBI database handle',
            req => 1,
        },
        create_from_version => {
            schema => ['int*'],
            summary => 'Instead of the latest, create from this version',
            description => <<'_',

This can be useful during testing. By default, if given an empty database, this
function will use the `install` key of the spec to create the schema from
nothing to the latest version. However, if this option is given, function wil
use the corresponding `install_v<VERSION>` key in the spec (which must exist)
and then upgrade using the `upgrade_to_v<VERSION>` keys to upgrade to the latest
version.

_
        },
    },
    "x.perinci.sub.wrapper.disable_validate_args" => 1,
};
sub create_or_update_db_schema {
    my %args = @_; no warnings ('void');require Scalar::Util::Numeric;my $arg_err; if (exists($args{'create_from_version'})) { ((defined($args{'create_from_version'})) ? 1 : (($arg_err //= "Required but not specified"),0)) && ((Scalar::Util::Numeric::isint($args{'create_from_version'})) ? 1 : (($arg_err //= "Not of type integer"),0)); if ($arg_err) { return [400, "Invalid argument value for create_from_version: $arg_err"] } }no warnings ('void');require Scalar::Util;if (exists($args{'dbh'})) { ((defined($args{'dbh'})) ? 1 : (($arg_err //= "Required but not specified"),0)) && ((Scalar::Util::blessed($args{'dbh'})) ? 1 : (($arg_err //= "Not of type object"),0)); if ($arg_err) { return [400, "Invalid argument value for dbh: $arg_err"] } }if (!exists($args{'dbh'})) { return [400, "Missing argument: dbh"] } no warnings ('void');if (exists($args{'spec'})) { ((defined($args{'spec'})) ? 1 : (($arg_err //= "Required but not specified"),0)) && ((ref($args{'spec'}) eq 'HASH') ? 1 : (($arg_err //= "Not of type hash"),0)); if ($arg_err) { return [400, "Invalid argument value for spec: $arg_err"] } }if (!exists($args{'spec'})) { return [400, "Missing argument: spec"] } # VALIDATE_ARGS

    my $spec   = $args{spec};
    my $dbh    = $args{dbh};
    my $from_v = $args{create_from_version};

    my $comp   = $spec->{component_name} // 'main';
    my $sv_key = _sv_key($comp);

    local $dbh->{RaiseError};

    # first, check current schema version

    # XXX check spec: latest_v and upgrade_to_v$V must synchronize

    my $current_v;
    my @has_meta_table = $dbh->tables("", undef, "meta");
    if (@has_meta_table) {
        ($current_v) = $dbh->selectrow_array(
            "SELECT value FROM meta WHERE name='$sv_key'");
    }
    $current_v //= 0;

    my %provides; # list of tables provided by all components
    if (@has_meta_table) {
        %provides = _get_provides_from_db($dbh);
    }

    # list of tables provided by this component
    my @provides;
  GET_PROVIDES:
    {
        if ($spec->{provides}) {
            @provides = @{ $spec->{provides} };
        } elsif ($spec->{install}) {
            @provides = _extract_created_tables_from_sql_statements(
                @{ $spec->{install} });
        } else {
            if ($comp ne 'main') {
                return [
                    412, "Both `provides` and `install` spec are not ".
                        "specified, can't get list of tables managed by ".
                        "this component"];
            }
        }
    }

  CHECK_DEPS:
    {
        my $deps = $spec->{deps} or last;

        for my $table (sort keys %$deps) {
            my $reqver = $deps->{$table};
            my $prov = $provides{$table};
            defined $prov or return [
                412,
                "Dependency fails: ".
                    "This component ('$comp') requires table '$table' ".
                    "(version $reqver) which has not been provided by ".
                    "any other component. Perhaps you should install the ".
                    "missing component first."
                ];
            my ($provcomp, $provver) = @$prov;
            $provver >= $reqver or return [
                412,
                "Dependency fails: ".
                    "This component ('$comp') requires table '$table' ".
                    "version $reqver but the database currently only has ".
                    "version $provver (from component '$provcomp'). Perhaps ".
                    "you should upgrade the '$provcomp' component first."
                ];
        }
    } # CHECK_DEPS

  CHECK_PROVIDES:
    {
        for my $t (@provides) {
            my $prov = $provides{$t};
            next unless $prov;
            my ($provcomp, $provver) = @$prov;
            $provcomp eq $comp or return [
                412,
                "Component conflict: ".
                    "This component ('$comp') provides table '$t' ".
                    "but another component ($provcomp version $provver) also ".
                    "provides this table. Perhaps you should update ".
                    "either one or both components first?"
            ];
        }
    } # CHECK_PROVIDES

    my $orig_v = $current_v;

    # perform schema upgrade atomically per version (at least for db that
    # supports atomic DDL like postgres)

    my $latest_v = $spec->{latest_v};
    if (!defined($latest_v)) {
        $latest_v = 1;
        for (keys %$spec) {
            next unless /^upgrade_to_v(\d+)$/;
            $latest_v = $1 if $1 > $latest_v;
        }
    }

    if ($current_v > $latest_v) {
        die "Database schema version ($current_v) is newer than the spec's ".
            "latest version ($latest_v), you probably need to upgrade ".
            "the application first\n";
    }

    my $code_update_provides = sub {
        my @k;
        for my $t (sort keys %provides) {
            my $prov = $provides{$t};
            next unless $prov->[0] eq $comp;
            delete $provides{$t};
            push @k, "table.$t";
        }
        if (@k) {
            $dbh->do("DELETE FROM meta WHERE name IN (".
                         join(",", map { $dbh->quote($_) } @k).")")
                or return $dbh->errstr;
        }
        for my $t (@provides) {
            $provides{$t} = [$comp, $latest_v];
            $dbh->do("INSERT INTO meta (name, value) VALUES (?, ?)",
                     {},
                     "table.$t",
                     "$comp:$latest_v",
                 ) or return $dbh->errstr;
        }
        # success
        "";
    };

    my $begun;
    my $res;

    my $db_state = 'committed';

  SETUP:
    while (1) {
        last if $current_v >= $latest_v;

        # we should only begin writing to the database from this step, because
        # we want to do things atomically (when the database supports it). when
        # we want to bail out, we don't return() directly but set $res and last
        # SETUP so we can rollback.
        $dbh->begin_work;
        $db_state = 'begun';

        # install
        if ($current_v == 0) {
            # create 'meta' table if not exists
            unless (@has_meta_table) {
                $dbh->do("CREATE TABLE meta (name VARCHAR(64) NOT NULL PRIMARY KEY, value VARCHAR(255))")
                    or do { $res = [500, "Couldn't create meta table: ".$dbh->errstr]; last SETUP };
            }
            my $sv_row = $dbh->selectrow_hashref("SELECT * FROM meta WHERE name='$sv_key'");
            unless ($sv_row) {
                $dbh->do("INSERT INTO meta (name,value) VALUES ('$sv_key',0)")
                    or do { $res = [500, "Couldn't insert to meta table: ".$dbh->errstr]; last SETUP };
            }

            if ($from_v) {
                # install from a specific version
                if ($spec->{"install_v$from_v"}) {
                    log_debug("Creating version $from_v of database schema ...");
                    my $i = 0;
                    for my $step (@{ $spec->{"install_v$from_v"} }) {
                        $i++;
                        if (ref($step) eq 'CODE') {
                            eval { $step->($dbh) }; if ($@) { $res = [500, "Died when executing code from install_v$from_v\'s step #$i: $@"]; last SETUP }
                        } else {
                            $dbh->do($step) or do { $res = [500, "Failed executing SQL statement from install_v$from_v\'s step #$i: ".$dbh->errstr." (SQL statement: $step)"]; last SETUP };
                        }
                    }
                    $current_v = $from_v;
                    $dbh->do("UPDATE meta SET value=$from_v WHERE name='$sv_key'")
                        or do { $res = [500, "Couldn't set $sv_key in meta table: ".$dbh->errstr]; last SETUP };

                    if ($current_v == $latest_v) {
                        if (my $up_res = $code_update_provides->()) { $res = [500, "Couldn't update provides information: $up_res"]; last SETUP }
                    }

                    $dbh->commit or do { $res = [500, "Couldn't commit: ".$dbh->errstr]; last SETUP };
                    $db_state = 'committed';

                    next SETUP;
                } else {
                    $res = [400, "Error in spec: Can't find 'install_v$from_v' key in spec"];
                    last SETUP;
                }
            } else {
                # install directly the latest version
                if ($spec->{install}) {
                    log_debug("Creating latest version of database schema ...");
                    my $i = 0;
                    for my $step (@{ $spec->{install} }) {
                        $i++;
                        if (ref($step) eq 'CODE') {
                            eval { $step->($dbh) }; if ($@) { $res = [500, "Died when executing code from install's step #$i: $@"]; last SETUP }
                        } else {
                            $dbh->do($step) or do { $res = [500, "Failed executing SQL statement from install's step #$i: ".$dbh->errstr." (SQL statement: $step)"]; last SETUP };
                        }
                    }
                    $dbh->do("UPDATE meta SET value=$latest_v WHERE name='$sv_key'")
                        or do { $res = [500, "Couldn't update $sv_key in meta table: ".$dbh->errstr]; last SETUP };

                    if (my $up_res = $code_update_provides->()) { $res = [500, "Couldn't update provides information: $up_res"]; last SETUP }

                    $dbh->commit or do { $res = [500, "Couldn't commit: ".$dbh->errstr]; last SETUP };
                    $db_state = 'committed';

                    last SETUP;
                } elsif ($spec->{upgrade_to_v1}) {
                    # there is no 'install' but 'upgrade_to_v1', so we upgrade
                    # from v1 to latest
                    goto UPGRADE;
                } else {
                    $res = [400, "Error in spec: Can't find 'install' key in spec"];
                    last SETUP;
                }
            }
        } # install

      UPGRADE:
        my $next_v = $current_v + 1;
        log_debug("Updating database schema from version $current_v to $next_v ...");
        $spec->{"upgrade_to_v$next_v"}
            or do { $res = [400, "Error in spec: upgrade_to_v$next_v not specified"]; last SETUP };
        my $i = 0;
        for my $step (@{ $spec->{"upgrade_to_v$next_v"} }) {
            $i++;
            if (ref($step) eq 'CODE') {
                eval { $step->($dbh) }; if ($@) { $res = [500, "Died when executing code from upgrade_to_v$next_v\'s step #$i: $@"]; last SETUP }
            } else {
                $dbh->do($step) or do { $res = [500, "Failed executing SQL statement from upgrade_to_v$next_v\'s step #$i: ".$dbh->errstr." (SQL statement: $step)"]; last SETUP };
            }
        }
        $current_v = $next_v;
        $dbh->do("UPDATE meta SET value=$next_v WHERE name='$sv_key'")
            or do { $res = [500, "Couldn't set $sv_key in meta table: ".$dbh->errstr]; last SETUP };

        if ($current_v == $latest_v) {
            if (my $up_res = $code_update_provides->()) { $res = [500, "Couldn't update provides information: $up_res"]; last SETUP }
        }

        $dbh->commit or do { $res = [500, "Couldn't commit: ".$dbh->errstr]; last SETUP };
        $db_state = 'committed';

    } # SETUP

    $res //= [200, "OK (upgraded from version $orig_v to $latest_v)", {version=>$latest_v}];

    if ($res->[0] != 200) {
        log_error("Failed creating/upgrading schema: %s", $res);
        $dbh->rollback unless $db_state eq 'committed';
    } else {
        $dbh->commit unless $db_state eq 'committed';
    }

    $res;
}

1;
# ABSTRACT: Routine and convention to create/update your application's DB schema

__END__

=pod

=encoding UTF-8

=head1 NAME

SQL::Schema::Versioned - Routine and convention to create/update your application's DB schema

=head1 VERSION

This document describes version 0.235 of SQL::Schema::Versioned (from Perl distribution SQL-Schema-Versioned), released on 2018-05-10.

=head1 DESCRIPTION

To use this module, you typically run the L</"create_or_update_db_schema">()
routine at the start of your program/script, e.g.:

 use DBI;
 use SQL::Schema::Versioned qw(create_or_update_db_schema);
 my $spec = {...}; # the schema specification
 my $dbh = DBI->connect(...);
 my $res = create_or_update_db_schema(dbh=>$dbh, spec=>$spec);
 die "Cannot run the application: cannot create/upgrade database schema: $res->[1]"
     unless $res->[0] == 200;

This way, your program automatically creates/updates database schema when run.
Users need not know anything.

=head1 BEST PRACTICES

It is recommended that after you create the second and subsequent version
(C<upgrade_to_v2>, C<upgrade_to_v3>, and so on) you create and keep
C<install_v1> so you can test migration from v1->v2, v2->v3, and so on.

=head1 FUNCTIONS


=head2 create_or_update_db_schema

Usage:

 create_or_update_db_schema(%args) -> [status, msg, result, meta]

Routine and convention to create/update your application's DB schema.

With this routine (and some convention) you can easily create and update
database schema for your application in a simple way using pure SQL.

I<Version>: version is an integer and starts from 1. Each software release with
schema change will bump the version number by 1. Version information is stored
in a special table called C<meta> (SELECT value FROM meta WHERE
name='schema_version').

You supply the SQL statements in C<spec>. C<spec> is a hash which at least must
contain the key C<latest_v> (an integer) and C<install> (a series of SQL
statements to create the schema from nothing to the latest version).

There should also be zero or more C<upgrade_to_v$VERSION> keys, the value of each
is a series of SQL statements to upgrade from ($VERSION-1) to $VERSION. So there
could be C<upgrade_to_v2>, C<upgrade_to_v3>, and so on up the latest version. This
is used to upgrade an existing database from earlier version to the latest.

For testing purposes, you can also add one or more C<< install_vE<lt>VERSIONE<gt> >> key,
where C<XXX> is an integer, the lowest version number that you still want to
support. So, for example, if C<latest_v> is 5 and you still want to support from
version 2, you can have an C<install_v2> key containing a series of SQL
statements to create the schema at version 2, and C<upgrade_to_v3>,
C<upgrade_to_v4>, C<upgrade_to_v5> keys. This way migrations from v2 to v3, v3 to
v4, and v4 to v5 can be tested.

You can name C<install_v1> key as C<upgrade_to_v1> (to upgrade from 'nothing'
a.k.a. v0 to v1), which is basically the same thing.

This routine will check the existence of the C<meta> table and the current schema
version. If C<meta> table does not exist yet, the SQL statements in C<install>
will be executed. The C<meta> table will also be created and a row
C<('schema_version', 1)> is added.

If C<meta> table already exists, schema version will be read from it and one or
more series of SQL statements from C<upgrade_to_v$VERSION> will be executed to
bring the schema to the latest version.

Aside from SQL statement, the series can also contain coderefs for more complex
upgrade process. Each coderef will be called with C<$dbh> as argument and must
not die (so to signify failure, you can die from inside the coderef).

Currently only tested on MySQL, Postgres, and SQLite. Postgres is recommended
because it can do transactional DDL (a failed upgrade in the middle will not
cause the database schema state to be inconsistent, e.g. in-between two
versions).

=head3 Modular schema (components)

This routine supports so-called modular schema, where you can separate your
database schema into several I<components> (sets of tables) and then declare
dependencies among them.

For example, say you are writing a stock management application. You divide your
application into several components: C<quote> (component that deals with
importing stock quotes and querying stock prices), C<portfolio> (component that
deals with computing the market value of your portfolio, calculating
gains/losses), C<trade> (component that connects to your broker API and perform
trading by submitting buy/sell orders).

The C<quote> application component manages these tables: C<daily_price>,
C<spot_price>. The C<portfolio> application component manages these tables:
C<account> (list of accounts in stock brokerages), C<balance> (list of balances),
C<tx> (list of transactions). The C<trade> application component manages these
tables: C<order> (list of buy/sell orders).

The C<portfolio> application component requires price information to be able to
calculate unrealized gains/losses. The C<trade> component also needs information
from the C<daily_price> e.g. to calculate 52-week momentum, and writes to the
C<spot_price> to record intraday prices, and reads/writes from the C<account> and
C<balance> tables. Here are the C<spec>s for each component:

 # spec for the price application component
 {
     component_name => 'price',
     latest_v => 1,
     provides => ['daily_price', 'spot_price'],
     install => [...],
     ...
 }
 
 # spec for the portfolio application component
 {
     component_name => 'portfolio',
     latest_v => 1,
     provides => ['account', 'balance', 'tx'],
     deps => {
         'daily_price' => 1,
         'spot_price'  => 1,
     },
     install => [...],
     ...
 }
 
 # spec for the trade application component
 {
     component_name => 'trade',
     latest_v => 1,
     provides => ['order'],
     deps => {
         'daily_price' => 1,
         'spot_price'  => 1,
         'account'     => 1,
         'balance'     => 1,
     },
     install => [...],
     ...
 }

You'll notice that the three keys new here are the C<component_name>, C<provides>,
and C<deps>.

When C<component_name> is set, then instead of the C<schema_version> key in the
C<meta> table, your component will use the C<< schema_version.E<lt>COMPONENT_NAMEE<gt> >> key.
When C<component_name> is not set, it is assumed to be C<main> and the
C<schema_version> key is used in the C<meta> table.

C<provides> is an array of tables to help this routine know which table(s) your
component create and maintain. If unset, this routine will try to guess from
looking at "CREATE TABLE" SQL statements. It is recommended that you supply
C<provides> to makes things easier.

This routine will create C<< table.E<lt>TABLE_NAMEE<gt> >> keys in the C<meta> table to record
which components currently maintain which tables. The value of the key is
C<< E<lt>COMPONENT_NAMEE<gt>:E<lt>VERSIONE<gt> >>. When a component no longer maintain a table in the
newest version, the corresponding C<< table.E<lt>TABLE_NAMEE<gt> >> row in the C<meta> will
also be removed.

C<deps> is a hash. The keys are table names that your component requires. The
values are integers, meaning the minimum version of the required table (=
component version). In the future, more complex dependency relationship and
version requirement will be supported.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<create_from_version> => I<int>

Instead of the latest, create from this version.

This can be useful during testing. By default, if given an empty database, this
function will use the C<install> key of the spec to create the schema from
nothing to the latest version. However, if this option is given, function wil
use the corresponding C<< install_vE<lt>VERSIONE<gt> >> key in the spec (which must exist)
and then upgrade using the C<< upgrade_to_vE<lt>VERSIONE<gt> >> keys to upgrade to the latest
version.

=item * B<dbh>* => I<obj>

DBI database handle.

=item * B<spec>* => I<hash>

Schema specification, e.g. SQL statements to create and update the schema.

Example:

 {
     latest_v => 3,
 
     # will install version 3 (latest)
     install => [
         'CREATE TABLE IF NOT EXISTS t1 (...)',
         'CREATE TABLE IF NOT EXISTS t2 (...)',
         'CREATE TABLE t3 (...)',
     ],
 
     upgrade_to_v2 => [
         'ALTER TABLE t1 ADD COLUMN c5 INT NOT NULL',
         sub {
             # this subroutine sets the values of c5 for the whole table
             my $dbh = shift;
             my $sth_sel = $dbh->prepare("SELECT c1 FROM t1");
             my $sth_upd = $dbh->prepare("UPDATE t1 SET c5=? WHERE c1=?");
             $sth_sel->execute;
             while (my ($c1) = $sth_sel->fetchrow_array) {
                 my $c5 = ...; # calculate c5 value for the row
                 $sth_upd->execute($c5, $c1);
             }
         },
         'CREATE UNIQUE INDEX i1 ON t2(c1)',
     ],
 
     upgrade_to_v3 => [
         'ALTER TABLE t2 DROP COLUMN c2',
         'CREATE TABLE t3 (...)',
     ],
 
     # provided for testing, so we can test migration from v1->v2, v2->v3
     install_v1 => [
         'CREATE TABLE IF NOT EXISTS t1 (...)',
         'CREATE TABLE IF NOT EXISTS t2 (...)',
     ],
 }

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 FAQ

=head2 Why use this module instead of other similar solution?

Mainly simplicity. I write simple application which is often self-contained in a
single module/script. This module works with embedded SQL statements instead of
having to put SQL in separate files/subdirectory.

=head2 How do I see each SQL statement as it is being executed?

Try using L<Log::ger::DBI::Query>, e.g.:

 % perl -MLog::ger::DBI::Query -MLog::ger::Output=Screen -MLog::ger::Level::trace yourapp.pl ...

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/SQL-Schema-Versioned>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-SQL-Schema-Versioned>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=SQL-Schema-Versioned>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

Some other database migration tools on CPAN:

=over

=item * L<DBIx::Migration>

Pretty much similar to this module, with support for downgrades. OO style, SQL
in separate files/subdirectory.

=item * L<Database::Migrator>

Pretty much similar. OO style, SQL in separate files/subdirectory. Perl scripts
can also be executed for each version upgrade. Meta table is configurable
(default recommended is 'AppliedMigrations').

=item * L<sqitch>

A more proper database change management tool with dependency resolution and VCS
awareness. No numbering. Command-line script and Perl library provided. Looks
pretty awesome and something which I hope to use for more complex applications.

=back

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018, 2017, 2015, 2014, 2013 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
