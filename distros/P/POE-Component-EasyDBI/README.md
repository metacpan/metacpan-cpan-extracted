# NAME

POE::Component::EasyDBI - Perl extension for asynchronous non-blocking DBI calls in POE

# SYNOPSIS

    use POE qw(Component::EasyDBI);

    # Set up the DBI
    POE::Component::EasyDBI->spawn( # or new(), witch returns an obj
        alias       => 'EasyDBI',
        dsn         => 'DBI:mysql:database=foobaz;host=192.168.1.100;port=3306',
        username    => 'user',
        password    => 'pass',
        options     => {
            AutoCommit => 0,
        },
    );

    # Create our own session to communicate with EasyDBI
    POE::Session->create(
        inline_states => {
            _start => sub {
                $_[KERNEL]->post('EasyDBI',
                    do => {
                        sql => 'CREATE TABLE users (id INT, username VARCHAR(100))',
                        event => 'table_created',
                    }
                );
            },
            table_created => sub {
                $_[KERNEL]->post('EasyDBI',
                    insert => {
                        # multiple inserts
                        insert => [
                            { id => 1, username => 'foo' },
                            { id => 2, username => 'bar' },
                            { id => 3, username => 'baz' },
                        ],
                        table => 'users',
                        event => 'done',
                    },
                );
                $_[KERNEL]->post('EasyDBI',
                    commit => {
                        event => 'done'
                    }
                );
                $_[KERNEL]->post('EasyDBI' => 'shutdown');
            },
            done => sub {
                my $result = $_[ARG0];
            }
        },
    );

    POE::Kernel->run();

# ABSTRACT

    This module simplifies DBI usage in POE's multitasking world.

    This module is easy to use, you'll have DBI calls in your POE program
    up and running in no time.

    It also works in Windows environments!

# DESCRIPTION

This module works by creating a new session, then spawning a child process
to do the DBI queries. That way, your main POE process can continue servicing
other clients.

The standard way to use this module is to do this:

    use POE;
    use POE::Component::EasyDBI;

    POE::Component::EasyDBI->spawn(...);

    POE::Session->create(...);

    POE::Kernel->run();

## Starting EasyDBI

To start EasyDBI, just call it's spawn method. (or new for an obj)

This one is for Postgresql:

    POE::Component::EasyDBI->spawn(
        alias       => 'EasyDBI',
        dsn         => 'DBI:Pg:dbname=test;host=10.0.1.20',
        username    => 'user',
        password    => 'pass',
    );

This one is for mysql:

    POE::Component::EasyDBI->spawn(
        alias       => 'EasyDBI',
        dsn         => 'DBI:mysql:database=foobaz;host=192.168.1.100;port=3306',
        username    => 'user',
        password    => 'pass',
    );

This method will die on error or return success.

Note the difference between dbname and database, that is dependant on the
driver used, NOT EasyDBI

NOTE: If the SubProcess could not connect to the DB, it will return an error,
causing EasyDBI to croak/die.

NOTE: Starting with version .10, I've changed new() to return a EasyDBI object
and spawn() returns a session reference.  Also, create() is the same as spawn().
See ["OBJECT METHODS"](#object-methods).

This constructor accepts 6 different options.

- `alias`

    This will set the alias EasyDBI uses in the POE Kernel.
    This will default TO "EasyDBI" if undef

    If you do not want to use aliases, specify '' as the ailas.  This helps when
    spawning many EasyDBI objects. See ["OBJECT METHODS"](#object-methods).

- `dsn`

    This is the DSN (Database connection string)

    EasyDBI expects this to contain everything you need to connect to a database
    via DBI, without the username and password.

    For valid DSN strings, contact your DBI driver's manual.

- `username`

    This is the DB username EasyDBI will use when making the call to connect

- `password`

    This is the DB password EasyDBI will use when making the call to connect

- `options`

    Pass a hash ref that normally would be after the $password param on a
    DBI->connect call.

- `max_retries`

    This is the max number of times the database wheel will be restarted, default
    is 5.  Set this to -1 to retry forever.

- `ping_timeout`

    Optional. This is the timeout to ping the database handle.  If set to 0 the
    database will be pinged before every query.  The default is 0.

- `no_connect_failures`

    Optional. If set to a true value, the connect\_error event will be valid, but not
    necessary.  If set to a false value, then connection errors will be fatal.

- `connect_error`

    Optional. Supply a array ref of session\_id or alias and an event.  Any connect
    errors will be posted to this session and event with the query that failed as
    ARG0 or an empty hash ref if no query was in the queue.  The query will be
    retried, so DON'T resend the query.  If this parameter is not supplied, the
    normal behavour will be to drop the subprocess and restart [max\_retries](https://metacpan.org/pod/max_retries) times.

- `reconnect_wait`

    Optional. Defaults to 2 seconds. After a connection failure this is the time
    to wait until another connection is attempted.  Setting this to 0 would not
    be good for your cpu load.

- `connected`

    Optional. Supply a array ref of session\_id or alias and an event.  When
    the component makes a successful connection this event will be called
    with the next query as ARG0 or an empty hash ref if no queries are in the queue.
    DON'T resend the query, it will be processed.

- `no_cache`

    Optional. If true, prepare\_cached won't be called on queries.  Use this when
    using [DBD::AnyData](https://metacpan.org/pod/DBD::AnyData). This can be overridden with each query.

- `alt_fork`

    Optional. If 1, an alternate type of fork will be used for the database
    process. This usually results in lower memory use of the child.
    You can also specify alt\_fork => '/path/to/perl' if you are using POE inside of
    another app like irssi.
    \*Experimental, and WILL NOT work on Windows Platforms\*

- `stopwatch`

    Optional. If true, [Time::Stopwatch](https://metacpan.org/pod/Time::Stopwatch) will be loaded and tied to the 'stopwatch'
    key on every query. Check the stopwatch key in the return event to measure how
    long a query took.

## Events

There is only a few events you can trigger in EasyDBI.
They all share a common argument format, except for the shutdown event.

Note: you can change the session that the query posts back to, it uses $\_\[SENDER\]
as the default.

You can use a postback, or callback (See POE::Session)

For example:

    $kernel->post('EasyDBI',
        quote => {
                sql => 'foo$*@%%sdkf"""',
                event => 'quoted_handler',
                session => 'dbi_helper', # or session id
        }
    );

or

    $kernel->post('EasyDBI',
        quote => {
                sql => 'foo$*@%%sdkf"""',
                event => $_[SESSION]->postback("quoted_handler"),
                session => 'dbi_helper', # or session id
        }
    );

- `quote`

        This sends off a string to be quoted, and gets it back.

        Internally, it does this:

        return $dbh->quote($SQL);

        Here's an example on how to trigger this event:

        $kernel->post('EasyDBI',
            quote => {
                sql => 'foo$*@%%sdkf"""',
                event => 'quoted_handler',
            }
        );

        The Success Event handler will get a hash ref in ARG0:
        {
            sql     =>  Unquoted SQL sent
            result  =>  Quoted SQL
        }

- `do`

        This query is for those queries where you UPDATE/DELETE/etc.

        Internally, it does this:

        $sth = $dbh->prepare_cached($sql);
        $rows_affected = $sth->execute($placeholders);
        return $rows_affected;

        Here's an example on how to trigger this event:

        $kernel->post('EasyDBI',
            do => {
                sql => 'DELETE FROM FooTable WHERE ID = ?',
                placeholders => [qw(38)],
                event => 'deleted_handler',
            }
        );

        The Success Event handler will get a hash in ARG0:
        {
            sql             =>  SQL sent
            result          =>  Scalar value of rows affected
            rows            =>  Same as result
            placeholders    =>  Original placeholders
        }

- `single`

        This query is for those queries where you will get exactly one row and
        column back.

        Internally, it does this:

        $sth = $dbh->prepare_cached($sql);
        $sth->bind_columns(%result);
        $sth->execute($placeholders);
        $sth->fetch();
        return %result;

        Here's an example on how to trigger this event:

        $kernel->post('EasyDBI',
            single => {
                sql => 'Select test_id from FooTable',
                event => 'result_handler',
            }
        );

        The Success Event handler will get a hash in ARG0:
        {
            sql             =>  SQL sent
            result          =>  scalar
            placeholders    =>  Original placeholders
        }

- `arrayhash`

        This query is for those queries where you will get more than one row and
        column back. Also see arrayarray

        Internally, it does this:

        $sth = $dbh->prepare_cached($SQL);
        $sth->execute($PLACEHOLDERS);
        while ($row = $sth->fetchrow_hashref()) {
            push( @results,{ %{ $row } } );
        }
        return @results;

        Here's an example on how to trigger this event:

        $kernel->post('EasyDBI',
            arrayhash => {
                sql => 'SELECT this, that FROM my_table WHERE my_id = ?',
                event => 'result_handler',
                placeholders => [qw(2021)],
            }
        );

        The Success Event handler will get a hash in ARG0:
        {
            sql             =>  SQL sent
            result          =>  Array of hashes of the rows (array of fetchrow_hashref's)
            rows            =>  Scalar value of rows
            placeholders    =>  Original placeholders
            cols            =>  An array of the cols in query order
        }

- `hashhash`

        This query is for those queries where you will get more than one row and
        column back.

        The primary_key should be UNIQUE! If it is not, then use hasharray instead.

        Internally, it does something like this:

        if ($primary_key =~ m/^\d+$/) {
            if ($primary_key} > $sth->{NUM_OF_FIELDS}) {
                die "primary_key is out of bounds";
            }
            $primary_key = $sth->{NAME}->[($primary_key-1)];
        }

        for $i (0..$sth->{NUM_OF_FIELDS}-1) {
            $col{$sth->{NAME}->[$i]} = $i;
            push(@cols, $sth->{NAME}->[$i]);
        }

        $sth = $dbh->prepare_cached($SQL);
        $sth->execute($PLACEHOLDERS);
        while (@row = $sth->fetch_array()) {
            foreach $c (@cols) {
                $results{$row[$col{$primary_key}]}{$c} = $row[$col{$c}];
            }
        }
        return %results;

        Here's an example on how to trigger this event:

        $kernel->post('EasyDBI',
            hashhash => {
                sql => 'SELECT this, that FROM my_table WHERE my_id = ?',
                event => 'result_handler',
                placeholders => [qw(2021)],
                primary_key => "2",  # making 'that' the primary key
            }
        );

        The Success Event handler will get a hash in ARG0:
        {
            sql             =>  SQL sent
            result          =>  Hashes of hashes of the rows
            rows            =>  Scalar value of rows
            placeholders    =>  Original placeholders
            cols            =>  An array of the cols in query order
        }

- `hasharray`

        This query is for those queries where you will get more than one row
        and column back.

        Internally, it does something like this:

        # find the primary key
        if ($primary_key =~ m/^\d+$/) {
            if ($primary_key} > $sth->{NUM_OF_FIELDS}) {
                die "primary_key is out of bounds";
            }
            $primary_key = $sth->{NAME}->[($primary_key-1)];
        }

        for $i (0..$sth->{NUM_OF_FIELDS}-1) {
            $col{$sth->{NAME}->[$i]} = $i;
            push(@cols, $sth->{NAME}->[$i]);
        }

        $sth = $dbh->prepare_cached($SQL);
        $sth->execute($PLACEHOLDERS);
        while (@row = $sth->fetch_array()) {
            push(@{ $results{$row[$col{$primary_key}}]} }, @row);
        }
        return %results;

        Here's an example on how to trigger this event:

        $kernel->post('EasyDBI',
            hasharray => {
                sql => 'SELECT this, that FROM my_table WHERE my_id = ?',
                event => 'result_handler',
                placeholders => [qw(2021)],
                primary_key => "1",  # making 'this' the primary key
            }
        );

        The Success Event handler will get a hash in ARG0:
        {
            sql             =>  SQL sent
            result          =>  Hashes of hashes of the rows
            rows            =>  Scalar value of rows
            placeholders    =>  Original placeholders
            primary_key     =>  'this' # the column name for the number passed in
            cols            =>  An array of the cols in query order
        }

- `array`

        This query is for those queries where you will get more than one row with
        one column back. (or joined columns)

        Internally, it does this:

        $sth = $dbh->prepare_cached($SQL);
        $sth->execute($PLACEHOLDERS);
        while (@row = $sth->fetchrow_array()) {
            if ($separator) {
                push(@results, join($separator,@row));
            } else {
                push(@results, join(',',@row));
            }
        }
        return @results;

        Here's an example on how to trigger this event:

        $kernel->post('EasyDBI',
            array => {
                sql => 'SELECT this FROM my_table WHERE my_id = ?',
                event => 'result_handler',
                placeholders => [qw(2021)],
                separator => ',', # default separator
            }
        );

        The Success Event handler will get a hash in ARG0:
        {
            sql             =>  SQL sent
            result          =>  Array of scalars (joined with separator if more
                than one column is returned)
            rows            =>  Scalar value of rows
            placeholders    =>  Original placeholders
        }

- `arrayarray`

        This query is for those queries where you will get more than one row and
        column back. Also see arrayhash

        Internally, it does this:

        $sth = $dbh->prepare_cached($SQL);
        $sth->execute($PLACEHOLDERS);
        while (@row = $sth->fetchrow_array()) {
            push( @results,\@row );
        }
        return @results;

        Here's an example on how to trigger this event:

        $kernel->post('EasyDBI',
            arrayarray => {
                sql => 'SELECT this,that FROM my_table WHERE my_id > ?',
                event => 'result_handler',
                placeholders => [qw(2021)],
            }
        );

        The Success Event handler will get a hash in ARG0:
        {
            sql             =>  SQL sent
            result          =>  Array of array refs
            rows            =>  Scalar value of rows
            placeholders    =>  Original placeholders
        }

- `hash`

        This query is for those queries where you will get one row with more than
        one column back.

        Internally, it does this:

        $sth = $dbh->prepare_cached($SQL);
        $sth->execute($PLACEHOLDERS);
        @row = $sth->fetchrow_array();
        if (@row) {
            for $i (0..$sth->{NUM_OF_FIELDS}-1) {
                $results{$sth->{NAME}->[$i]} = $row[$i];
            }
        }
        return %results;

        Here's an example on how to trigger this event:

        $kernel->post('EasyDBI',
            hash => {
                sql => 'SELECT * FROM my_table WHERE my_id = ?',
                event => 'result_handler',
                placeholders => [qw(2021)],
            }
        );

        The Success Event handler will get a hash in ARG0:
        {
            sql             =>  SQL sent
            result          =>  Hash
            rows            =>  Scalar value of rows
            placeholders    =>  Original placeholders
        }

- `keyvalhash`

        This query is for those queries where you will get one row with more than
        one column back.

        Internally, it does this:

        $sth = $dbh->prepare_cached($SQL);
        $sth->execute($PLACEHOLDERS);
        while (@row = $sth->fetchrow_array()) {
            $results{$row[0]} = $row[1];
        }
        return %results;

        Here's an example on how to trigger this event:

        $kernel->post('EasyDBI',
            keyvalhash => {
                sql => 'SELECT this, that FROM my_table WHERE my_id = ?',
                event => 'result_handler',
                placeholders => [qw(2021)],
                primary_key => 1, # uses 'this' as the key
            }
        );

        The Success Event handler will get a hash in ARG0:
        {
            sql             =>  SQL sent
            result          =>  Hash
            rows            =>  Scalar value of rows
            placeholders    =>  Original placeholders
        }

- `insert`

        This is for inserting rows.

        Here's an example on how to trigger this event:

        $_[KERNEL]->post('EasyDBI',
            insert => {
                sql => 'INSERT INTO zipcodes (zip,city,state) VALUES (?,?,?)',
                placeholders => ['98004', 'Bellevue', 'WA'],
                event => 'insert_handler',
            }
        );

        a multiple insert:

        $_[KERNEL]->post('EasyDBI',
            insert => {
                insert => [
                    { id => 1, username => 'foo' },
                    { id => 2, username => 'bar' },
                    { id => 3, username => 'baz' },
                ],
                table => 'users',
                event => 'insert_handler',
            },
        );

        also an example to retrieve a last insert id

        $_[KERNEL]->post('EasyDBI',
            insert => {
                hash => { username => 'test', pass => 'sUpErSeCrEt', name => 'John' },
                table => 'users',
                last_insert_id => {
                    field => 'user_id', # mysql uses SELECT LAST_INSERT_ID instead
                    table => 'users',   # of these values, just specify {} for mysql
                },
                # or last_insert_id can be => 'SELECT LAST_INSERT_ID()' or some other
                # query that will return a value
            },
        );

        The Success Event handler will get a hash in ARG0:
        {
            action          =>  insert
            event           =>  result_handler
            id              =>  queue id
            insert          =>  original multiple insert hash reference
            insert_id       =>  insert id if last_insert_id is used
            last_insert_id  =>  the original hash or scalar sent
            placeholders    =>  original placeholders
            rows            =>  number of rows affected
            result          =>  same as rows
            sql             =>  SQL sent
            table           =>  table from insert
        }

- `combo`

        This is for combining multiple SQL statements in one call.

        Here's an example of how to trigger this event:

        $_[KERNEL]->post('EasyDBI',
            combo => {
                queries => [
                    {
                        do => {
                            sql => 'CREATE TABLE test (id INT, foo TEXT, bar TEXT)',
                        }
                    },
                    {
                        insert => {
                            table => 'test',
                            insert => [
                                { id => 1, foo => 123456, bar => 'a quick brown fox' },
                                { id => 2, foo => 7891011, bar => time() },
                            ],
                        },
                    },
                    {
                        insert => {
                            table => 'test',
                            hash => { id => 2, foo => 7891011, bar => time() },
                        },
                    },
                ],
                event => 'combo_handler',
            }
        );

        The Success Event handler will get a hash for each of the queries in
        ARG0..$#. See the respective hash structure for each of the single events.

- `func`

        This is for calling $dbh->func(), when using a driver that supports it.

        Internally, it does this:

        return $dbh->func(@{$args});

        Here's an example on how to trigger this event (Using DBD::AnyData):

        $kernel->post('EasyDBI',
            func => {
                args => ['test2','CSV',["id,phrase\n1,foo\n2,bar"],'ad_import'],
                event => 'result_handler',
            }
        );

        The Success Event handler will get a hash in ARG0:
        {
            sql             =>  SQL sent
            result          =>  return value
        }

- `method`

        This is for calling any method on the $dbh,

        Internally, it does this:

        return $dbh->{method}(@{$args});

        Here's an example on how to trigger this event (Using DBD::SQLite):

        $kernel->post('EasyDBI',
            method => {
                    method => 'sqlite_table_column_metadata'
                args => [undef, 'users', 'username'],
                event => 'result_handler',
            }
        );

        The Success Event handler will get a hash in ARG0:
        {
            action          =>  method
            args            =>  original array reference containing the arguments
            event           =>  result_handler
            id              =>  queue id
            method          =>  sqlite_table_column_metadata
            result          =>  return value
            session         =>  session id
        }

- `commit`

        This is for calling $dbh->commit(), if the driver supports it.

        Internally, it does this:

        return $dbh->commit();

        Here's an example on how to trigger this event:

        $kernel->post('EasyDBI',
            commit => {
                event => 'result_handler',
            }
        );

        The Success Event handler will get a hash in ARG0:
        {
            action          =>  commit
            event           =>  result_handler
            id              =>  queue id
            result          =>  return value
            session         =>  session id
        }

- `rollback`

        This is for calling $dbh->rollback(), if the driver supports it.

        Internally, it does this:

        return $dbh->rollback();

        Here's an example on how to trigger this event:

        $kernel->post('EasyDBI',
            rollback => {
                event => 'result_handler',
            }
        );

        The Success Event handler will get a hash in ARG0:
        {
            action          =>  rollback
            event           =>  result_handler
            id              =>  queue id
            result          =>  return value
            session         =>  session id
        }

- `begin_work`

        This is for calling $dbh->begin_work(), if the driver supports it.

        Internally, it does this:

        return $dbh->begin_work();

        Here's an example on how to trigger this event:

        $kernel->post('EasyDBI',
            begin_work => {
                event => 'result_handler',
            }
        );

        The Success Event handler will get a hash in ARG0:
        {
            action          =>  begin_work
            event           =>  result_handler
            id              =>  queue id
            result          =>  return value
            session         =>  session id
        }

- `shutdown`

        $kernel->post('EasyDBI', 'shutdown');

        This will signal EasyDBI to start the shutdown procedure.

        NOTE: This will let all outstanding queries run!
        EasyDBI will kill it's session when all the queries have been processed.

        you can also specify an argument:

        $kernel->post('EasyDBI', 'shutdown' => 'NOW');

        This will signal EasyDBI to shutdown.

        NOTE: This will NOT let the outstanding queries finish!
        Any queries running will be lost!

        Due to the way POE's queue works, this shutdown event will take some time
        to propagate POE's queue. If you REALLY want to shut down immediately, do
        this:

        $kernel->call('EasyDBI', 'shutdown' => 'NOW');

        ALL shutdown NOW's send kill 9 to thier children, beware of any
        transactions that you may be in. Your queries will revert if you are in
        transaction mode

### Arguments

They are passed in via the $kernel->post(...);

Note: all query types can be in ALL-CAPS or lowercase but not MiXeD!

ie ARRAYHASH or arrayhash but not ArrayHash

- `sql`

    This is the actual SQL line you want EasyDBI to execute.
    You can put in placeholders, this module supports them.

- `placeholders`

    This is an array of placeholders.

    You can skip this if your query does not use placeholders in it.

- `event`

    This is the success/failure event, triggered whenever a query finished
    successfully or not.

    It will get a hash in ARG0, consult the specific queries on what you will get.

    \*\*\*\*\* NOTE \*\*\*\*\*

    In the case of an error, the key 'error' will have the specific error that
    occurred.  Always, always, \_always\_ check for this in this event.

    \*\*\*\*\* NOTE \*\*\*\*\*

- `separator`

    Query types single, and array accept this parameter.
    The default is a comma (,) and is optional

    If a query has more than one column returned, the columns are joined with
    the 'separator'.

- `primary_key`

    Query types hashhash, and hasharray accept this parameter.
    It is used to key the hash on a certain field

- `chunked`

    All multi-row queries can be chunked.

    You can pass the parameter 'chunked' with a number of rows to fire the 'event'
    event for every 'chunked' rows, it will fire the 'event' event. (a 'chunked'
    key will exist) A 'last\_chunk' key will exist when you have received the last
    chunk of data from the query

- `last_insert_id`

    See the insert event for a example of its use.

- `begin_work`

    Optional.  Works with all queries.  You should have AutoCommit => 0 set on
    connect.

- `commit`

    Optional.  After a successful 'do' or 'insert', a commit is performed.
    ONLY used when using `do` or `insert`

- (arbitrary data)

    You can pass custom keys and data not mentioned above, BUT I suggest using a
    prefix like \_ in front of your custom keys.  For example:

        $_[KERNEL->post('EasyDBI',
            do => {
                sql => 'DELETE FROM sessions WHERE ip = ?',
                placeholders => [$ip],
                _ip => $ip,
                _port => $port,
                _filehandle => $fh,
            }
        );

    If I were to add an option 'filehandle' (for importing data from a file for
    instance) you don't want an upgrade to produce BAD results.

## OBJECT METHODS

When using new() to spawn/create the EasyDBI object, you can use the methods
listed below

NOTE: The object interface will be improved in later versions, please send
suggestions to the author.

- `ID`

    This retrieves the session ID.  When managing a pool of EasyDBI objects, you
    can set the alias to '' (nothing) and retrieve the session ID in this manner.

        $self->ID()

- `commit, rollback, begin_work, func, method, insert, do, single, quote, arrayhash, hashhash, hasharray, array, arrayarray, hash, keyvalhash, combo, shutdown`

    All query types are now supported as object methods.  For example:

        $self->arrayhash(
            sql => 'SELECT user_id,user_login from users where logins = ?',
            event => 'arrayash_handler',
            placeholders => [ qw( 53 ) ],
        );

- `DESTROY`

    This will shutdown EasyDBI.

        $self->DESTROY()

## LONG EXAMPLE

    use POE qw(Component::EasyDBI);

    # Set up the DBI
    POE::Component::EasyDBI->spawn(
        alias       => 'EasyDBI',
        dsn         => 'DBI:mysql:database=foobaz;host=192.168.1.100;port=3306',
        username    => 'user',
        password    => 'pass',
    );

    # Create our own session to communicate with EasyDBI
    POE::Session->create(
        inline_states => {
            _start => sub {
                $_[KERNEL]->post('EasyDBI',
                    do => {
                        sql => 'DELETE FROM users WHERE user_id = ?',
                        placeholders => [qw(144)],
                        event => 'deleted_handler',
                    }
                );

                # 'single' is very different from the single query in SimpleDBI
                # look at 'hash' to get those results

                # If you select more than one field, you will only get the last one
                # unless you pass in a separator with what you want the fields seperated by
                # to get null sperated values, pass in separator => "\0"
                $_[KERNEL]->post('EasyDBI',
                    single => {
                        sql => 'Select user_id,user_login from users where user_id = ?',
                        event => 'single_handler',
                        placeholders => [qw(144)],
                        separator => ',', #optional!
                    }
                );

                $_[KERNEL]->post('EasyDBI',
                    quote => {
                        sql => 'foo$*@%%sdkf"""',
                        event => 'quote_handler',
                    }
                );

                $_[KERNEL]->post('EasyDBI',
                    arrayhash => {
                        sql => 'SELECT user_id,user_login from users where logins = ?',
                        event => 'arrayash_handler',
                        placeholders => [qw(53)],
                    }
                );

                my $postback = $_[SESSION]->postback("arrayhash_handler",3,2,1);

                $_[KERNEL]->post('EasyDBI',
                    arrayhash => {
                        sql => 'SELECT user_id,user_login from users',
                        event => $postback,
                    }
                );

                $_[KERNEL]->post('EasyDBI',
                    arrayarray => {
                        sql => 'SELECT * from locations',
                        event => 'arrayarray_handler',
                        primary_key => '1', # you can specify a primary key, or a number based on what column to use
                    }
                );

                $_[KERNEL]->post('EasyDBI',
                    hashhash => {
                        sql => 'SELECT * from locations',
                        event => 'hashhash_handler',
                        primary_key => '1', # you can specify a primary key, or a number based on what column to use
                    }
                );

                $_[KERNEL]->post('EasyDBI',
                    hasharray => {
                        sql => 'SELECT * from locations',
                        event => 'hasharray_handler',
                        primary_key => "1",
                    }
                );

                # you should use limit 1, it is NOT automaticly added
                $_[KERNEL]->post('EasyDBI',
                    hash => {
                        sql => 'SELECT * from locations LIMIT 1',
                        event => 'hash_handler',
                    }
                );

                $_[KERNEL]->post('EasyDBI',
                    array => {
                        sql => 'SELECT location_id from locations',
                        event => 'array_handler',
                    }
                );

                $_[KERNEL]->post('EasyDBI',
                    keyvalhash => {
                        sql => 'SELECT location_id,location_name from locations',
                        event => 'keyvalhash_handler',
                        # if primary_key isn't used, the first one is assumed
                    }
                );

                $_[KERNEL]->post('EasyDBI',
                    insert => {
                        sql => 'INSERT INTO zipcodes (zip,city,state) VALUES (?,?,?)',
                        placeholders => ['98004', 'Bellevue', 'WA'],
                        event => 'insert_handler',
                    }
                );

                $_[KERNEL]->post('EasyDBI',
                    insert => {
                        # this can also be a array of hashes similar to this
                        hash => { username => 'test' , pass => 'sUpErSeCrEt', name => 'John' },
                        table => 'users',
                        last_insert_id => {
                            field => 'user_id', # mysql uses SELECT LAST_INSERT_ID instead
                            table => 'users',   # of these values, just specify {} for mysql
                        },
                        event => 'insert_handler',
                        # or last_insert_id can be => 'SELECT LAST_INSERT_ID()' or some other
                        # query that will return a value
                    },
                );

                # 3 ways to shutdown

                # This will let the existing queries finish, then shutdown
                $_[KERNEL]->post('EasyDBI', 'shutdown');

                # This will terminate when the event traverses
                # POE's queue and arrives at EasyDBI
                #$_[KERNEL]->post('EasyDBI', shutdown => 'NOW');

                # Even QUICKER shutdown :)
                #$_[KERNEL]->call('EasyDBI', shutdown => 'NOW');
            },

            deleted_handler => \&deleted_handler,
            quote_handler   => \&quote_handler,
            arrayhash_handler => \&arrayhash_handler,
        },
    );

    sub quote_handler {
        # For QUOTE calls, we receive the scalar string of SQL quoted
        # $_[ARG0] = {
        #   sql => The SQL you sent
        #   result  => scalar quoted SQL
        #   placeholders => The placeholders
        #   action => 'QUOTE'
        #   error => Error occurred, check this first
        # }
    }

    sub deleted_handler {
        # For DO calls, we receive the scalar value of rows affected
        # $_[ARG0] = {
        #   sql => The SQL you sent
        #   result  => scalar value of rows affected
        #   placeholders => The placeholders
        #   action => 'do'
        #   error => Error occurred, check this first
        # }
    }

    sub single_handler {
        # For SINGLE calls, we receive a scalar
        # $_[ARG0] = {
        #   sql => The SQL you sent
        #   result  => scalar
        #   placeholders => The placeholders
        #   action => 'single'
        #   separator => Seperator you may have sent
        #   error => Error occurred, check this first
        # }
    }

    sub arrayhash_handler {
        # For arrayhash calls, we receive an array of hashes
        # $_[ARG0] = {
        #   sql => The SQL you sent
        #   result  => array of hash refs
        #   placeholders => The placeholders
        #   action => 'arrayhash'
        #   error => Error occurred, check this first
        # }
    }

    sub hashhash_handler {
        # For hashhash calls, we receive a hash of hashes
        # $_[ARG0] = {
        #   sql => The SQL you sent
        #   result  => hash ref of hash refs keyed on primary key
        #   placeholders => The placeholders
        #   action => 'hashhash'
        #   cols => array of columns in order (to help recreate the sql order)
        #   primary_key => column you specified as primary key, if you specifed
        #       a number, the real column name will be here
        #   error => Error occurred, check this first
        # }
    }

    sub hasharray_handler {
        # For hasharray calls, we receive an hash of arrays
        # $_[ARG0] = {
        #   sql => The SQL you sent
        #   result  => hash ref of array refs keyed on primary key
        #   placeholders => The placeholders
        #   action => 'hashhash'
        #   cols => array of columns in order (to help recreate the sql order)
        #   primary_key => column you specified as primary key, if you specifed
        #           a number, the real column name will be here
        #   error => Error occurred, check this first
        # }
    }

    sub array_handler {
        # For array calls, we receive an array
        # $_[ARG0] = {
        #   sql => The SQL you sent
        #   result  => an array, if multiple fields are used, they are comma
        #           seperated (specify separator in event call to change this)
        #   placeholders => The placeholders
        #   action => 'array'
        #   separator => you sent  # optional!
        #   error => Error occurred, check this first
        # }
    }

    sub arrayarray_handler {
        # For array calls, we receive an array ref of array refs
        # $_[ARG0] = {
        #   sql => The SQL you sent
        #   result  => an array ref of array refs
        #   placeholders => The placeholders
        #   action => 'arrayarray'
        #   error => Error occurred, check this first
        # }
    }

    sub hash_handler {
        # For hash calls, we receive a hash
        # $_[ARG0] = {
        #   sql => The SQL you sent
        #   result  => a hash
        #   placeholders => The placeholders
        #   action => 'hash'
        #   error => Error occurred, check this first
        # }
    }

    sub keyvalhash_handler {
        # For keyvalhash calls, we receive a hash
        # $_[ARG0] = {
        #   sql => The SQL you sent
        #   result  => a hash  # first field is the key, second is the value
        #   placeholders => The placeholders
        #   action => 'keyvalhash'
        #   error => Error occurred, check this first
        #   primary_key => primary key used
        # }
    }

    sub insert_handle {
        # $_[ARG0] = {
        #   sql => The SQL you sent
        #   placeholders => The placeholders
        #   action => 'insert'
        #   table => 'users',
        #   # for postgresql, or others?
        #   last_insert_id => { # used to retrieve the insert id of the inserted row
        #       field => The field of id requested
        #       table => The table the holds the field
        #   },
        #   -OR-
        #   last_insert_id => 'SELECT LAST_INSERT_ID()', # mysql style
        #   result => the id from the last_insert_id post query
        #   error => Error occurred, check this first
        # }
    }

## EasyDBI Notes

This module is very picky about capitalization!

All of the options are in lowercase. Query types can be in ALL-CAPS or lowercase.

This module will try to keep the SubProcess alive.
if it dies, it will open it again for a max of 5 retries by
default, but you can override this behavior by using [max\_retries](https://metacpan.org/pod/max_retries)

Please rate this module. [http://cpanratings.perl.org/rate/?distribution=POE-Component-EasyDBI](http://cpanratings.perl.org/rate/?distribution=POE-Component-EasyDBI)

## EXPORT

Nothing.

# SEE ALSO

[DBI](https://metacpan.org/pod/DBI), [POE](https://metacpan.org/pod/POE), [POE::Wheel::Run](https://metacpan.org/pod/POE::Wheel::Run), [POE::Component::DBIAgent](https://metacpan.org/pod/POE::Component::DBIAgent), [POE::Component::LaDBI](https://metacpan.org/pod/POE::Component::LaDBI),
[POE::Component::SimpleDBI](https://metacpan.org/pod/POE::Component::SimpleDBI)

[DBD::AnyData](https://metacpan.org/pod/DBD::AnyData), [DBD::SQLite](https://metacpan.org/pod/DBD::SQLite)

[AnyEvent::DBI](https://metacpan.org/pod/AnyEvent::DBI)

# AUTHOR

David Davis <xantus@cpan.org>

# CREDITS

- Apocalypse <apocal@cpan.org>
- Chris Williams <chris@bingosnet.co.uk>
- Andy Grundman <andy@hybridized.org>
- Gelu Lupaș <gvl@cpan.org>
- Olivier Mengué <dolmen@cpan.org>
- Stephan Jauernick <stephan@stejau.de>

# COPYRIGHT AND LICENSE

Copyright 2003-2005 by David Davis and Teknikill Software

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
