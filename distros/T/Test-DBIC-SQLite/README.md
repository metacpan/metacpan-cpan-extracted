# NAME

`Test::DBIC::SQLite` - Connection tester for any `DBIx::Class::Schema` on `SQLite3`

# SYNOPSIS

The preferred way (*with* support for **`pre_deploy_hook`**):

```perl
#! perl -w
use Test::More;
use Test::DBIC::SQLite;

my $t = Test::DBIC::SQLite->new(
    schema_class    => 'My::Schema',
    pre_deploy_hook => \&define_functions,
);
my $schema = $t->connect_dbic_ok();

my $thing = $schema->resultset('MyTable')->search(
    { name    => 'Anything' },
    { columns => [ { ul_name   => \'uc_last(name)' } ] }
)->first;
is(
   $thing->get_column('ul_name'),
   'anythinG',
   "SELECT uc_last(name) AS ul_name FROM ...; works!"
);

$t->drop_dbic_ok();
done_testing();

# select uc_last('Stupid'); -- stupiD
# these functions will only exist within this database connection
sub define_functions {
    my ($schema) = @_;
    my $dbh = $schema->storage->dbh;
    $dbh->sqlite_create_function(
        'uc_last',
        1,
        sub { my ($str) = @_; $str =~ s{(.*)(.)$}{\L$1\U$2}; return $str },
    );
}
```

The backward compatible way (*without* support for **`pre_deploy_hook`**):

```perl
#! perl -w
use Test::More;
use Test::DBIC::SQLite;

my $schema = connect_dbic_sqlite_ok('My::Schema');

done_tesing();
```


# DESCRIPTION

This is a re-implementation of `Test::DBIC::SQLite` `v0.01` using the
[`Moo::Role`](https://metacpan.org/pod/Moo::Role):
[`Test::DBIC::DBDConnector`](#test-dbic-dbdconnector).

It will `import()` [`warnings`](https://metacpan.org/pod/warnings) and
[`strict`](https://metacpan.org/pod/strict) for you.

## **`Test::DBIC::SQLite->new()`**

This is the new implementation that supports the `$pre_deploy_hook`.

### Parameters

Named:

- ***`schema_class`* => `$dbic_schema_class`** (*Required*)  
The class name of the
[DBIx::Class::Schema](https://metacpan.org/pod/DBIx::Class::Schema) to use for
the database connection.


- ***`dbi_connect_info`* => `$sqlite_dbname`** (*Optional*, `:memory:`)  
The default is **`:memory:`** which will create a temporary in-memory database.
One can also pass a file name for a database on disk. See
[MyDBD\_connection\_parameters](#mydbd_connection_parameters).  


- ***`pre_deploy_hook`* => `$pre_deploy_hook`** (*Optional*)  
This is an optional `CodeRef` that will be executed right after the connection
is established but before `$schema->deploy` is called. The CodeRef will only be
called if deploy is also needed. See
[MyDBD\_check\_wants\_deploy](#mydbd_check_wants_deploy).


- ***`post_connect_hook`* => `$post_connect_hook`** (*Optional*)  
This is an optional `CodeRef` that will be executed right after deploy (if any)
and just before returning the schema instance. Useful for populating the
database.

### Returns

This method returns an instance of `Test::DBIC::SQLite`.

## **`Test::DBIC::SQLite->connect_dbic_ok()`**

This method can be called as a *class*method or as an *instance*method.

### The instancemethod

#### Parameters

None.

#### Returns

An instance of the `DBIx::Class::Schema` one is trying to test.

### The classmethod

#### Parameters

See the [new](#test-dbic-sqlite-new-) method.

#### Returns

An instance of the `DBIx::Class::Schema` one is trying to test.

## Implementation of `MyDBD_connection_parameters`

The value of the `dbi_connect_info` parameter to the `connect_dbic_ok()`
method, is passed to this method. For this *SQLite3* implementation this is a
single string that should contain the name of the database on disk, that can be
accessed with `SQLite3`. By default we use the "special" value of
**`:memory:`** to create a temporary in-memory database.

This method returns a list of parameters to be passed to
`DBIx::Class::Schema->connect()`. Keep in mind that the last argument
(options-hash) will always be augmented with key-value pair: `ignore_version => 1`.

### Note

At this moment we do not support the `uri=file:$db_file_name?mode=rwc` style of
*dsn*, only the `dbname=$db_file_name` style, as we only support
`$db_file_name` as a single parameter.

## Implementation of `MyDBD_check_wants_deploy`

For in-memory databases this will always return **true**. For databases on disk
this will return **true** if the file does not exist and **false** if it does.

## **`connect_dbic_sqlite_ok()`**

This function is provided for backward compatibility and internally uses
`Test::DBIC::SQLite->connect_dbic_ok()`.

**NB**: As this function is backward compatible, it does *not* support the
`$pre_deploy_hook` callback!

### Parameters

Positional:

1. **`$dbic_schema_class`** (*Required*)  
The class name of the
[DBIx::Class::Schema](https://metacpan.org/pod/DBIx::Class::Schema) to use for
the database connection.

2. **`$sqlite_dbname`** (*Optional*, `:memory:`)  
The default is **`:memory:`** which will create a temporary in-memory database.
One can also pass a file name for a database on disk. See
[MyDBD\_connection\_parameters](#mydbd_connection_parameters).

3. **`$post_connect_hook`** (*Optional*)  
This is an optional `CodeRef` that will be executed right after deploy (if any)
and just before returning the schema instance. Useful for populating the
database.

---

---

# `Test::DBIC::DBDConnector`

[`Moo::Role`](https://metacpan.org/pod/Moo::Role) for writing
`Test::DBIC::yourDBD` implementations

# SYNOPSIS

```perl
    package Test::DBIC::SQLite;
    use Moo;
    with 'Test::DBIC::DBDConnector';

    sub MyDBD_connection_parameters {
        my $class = shift;
        my ($db_name) = @_;

        $db_name //= ':memory:';
        return [ "dbi:SQLite:dbname=$db_name" ];
    }

    sub MyDBD_check_wants_deploy {
        my $class = shift;
        my ($connection_params) = @_;

        my ($db_name) = $connection_params->[0] =~ m{dbname=(.+)(?:;|$)};
        my $wants_deploy = $db_name eq ':memory:'
            ? 1
            : ((not -f $db_name) ? 1 : 0);

        return $wants_deploy;
    }
    use namespace::autoclean 0.16;
    1;
```
This could be used as:

```perl
    #! perl -w
    use Test::More;
    use Test::DBIC::SQLite;

    my $t = Test::DBIC::SQLite->new(schema_class => 'My::Schema');
    my $schema = $t->connect_dbic_ok();

    $t->drop_dbic_ok();
    done_testing();
```

# DESCRIPTION

This `Moo::Role` is for Tester-modules that implement the connection-test
function for the combination of any `DBIx::Class::Schema` and a specific
database-engine (`DBD::yourDBD`).

## `Test::DBIC::<yourDBD>->new(@parameters)`

The connection test does these steps:

* create connection_parameters (*`MyDBD_connection_parameters`*)
* create a database connection (`DBIx::Class::AnySchema->connect()`)
* check the need for a fresh deployment of the schema (`wants_deploy`)
 * if `wants_deploy`, run the provided pre-deploy-hook (if any)
 * if `wants_deploy`, run `$schema->deploy`
* run the post-connect-hook (if any)

Your implementation will only be able to "shape" the `dbi_connect_info` parameter
(*`$dbi_connect_info`*).

### Parameters

Named:

* **`schema_class` => `$dbic_schema_class`** (*Required*)  
This is the name of the
[DBIx::Class::Schema](https://metacpan.org/pod/DBIx::Class::Schema) subclass
of the ORM that the user who is writing the tests must provide.


* **`dbic_connect_info` => `$your_dbd_connect_info`** (*Optional*)  
This parameter will contain the information that your
`MyDBD_connection_parameters()` method implementation needs to return an ArrayRef of
parameters for `DBIx::Class::Schema->connect()`.  
This is the only parameter your `Test::DBIC::yourDBD` must take care of in
order to provide a successful connection/deploy for the user's test databases.
This is done by implementing the two required methods
`MyDBD_connection_parameters` and `MyDBD_check_wants_deploy`.


* **`pre_deploy_hook` => `$pre_deploy_hook`** (*Optional*)  
A CodeRef to execute *before* `$schema->deploy` is called if `wants_deploy`.  
This CodeRef might be provided by the user who is writing the tests and is called
with an instantiated `$your_schema_class` object as argument.


* **`post_connect_hook` => `$post_connect_hook`** (*Optional*)  
A CodeRef to execute *after* `$schema->deploy` (if at all) is called.  
This CodeRef might be provided by the user who is writing the tests and is called
with an instantiated `$your_schema_class` object as argument.

## The `connect_dbic_ok` method

This is the base connection test for all `Test::DBIC::<yourDBD>`
implementations and probably shouldn't be overridden.

The method can serve as a *instance* method as well as a *class* method.

### Retruns

In both cases it returns an instantiated `DBIx::Class::Schema` object one wants to test.

## `$instance->connect_dbic_ok`

### Parameters

None.

## `Test::DBIC::<yourDBD>->connect_dbic_ok`

### Parameters

As a *class* method it takes the same parameters as the [new method](#new-parameters-).

## **Required**: `MyDBD_connection_parameters($your_dbd_connect_info)`

Your class will have to implement this method in a way that is appropriate for *yourDBD*.

For [`DBD::SQLite`](https://metacpan.org/pod/DBD::SQLite) one could use a
single argument for the filename and choose `:memory:` when not defined.

Other database drivers may need a lot more more information and you could use
an ArrayRef or HashRef to make sure the correct information can be returned for
the connection.

### Parameters

Positional:

1. **`$your_dbd_connect_info`** (unknown type)  
What the exact content of this parameter is, will depend on the database driver
and the interface one creates for the tester module.

### Response

This method should return an ArrayRef with the 4 elements supported by `DBI->connect()` and `DBIx::Class::Schema->connect()`.

1. **`dsn`**  like `dbi:yourDBD:dbname=blah;...`

2. **`username`**

3. **`password`**

4. **`options`**  A HashRef with extra option.

### Note

This `Moo::Role` augments this method (via `around`) in order to always make sure that
the `options` HashRef gets the key-pair `ignore_version => 1`, one can examine
this option from within the `DBIx::Class::Schema->connect()` method to ignore a
check for software and database versions.

## **Required**: `MyDBD_check_wants_deploy($your_dbd_connection_parameters)`

Your class will have to implement this method in a way that is appropriate for *yourDBD*.

This method gets the result of
[`MyDBD_connection_parameters`](#required-mydbd_connection_parameters-your_dbd_connect_info-)
passed. You will have to define a way to determine on what criteria you're
going to have the code invoke the `$schema->deploy` method.

### Parameters

Positional:

1. **`$your_dbd_connection_parameters`** (ArrayRef)  
This is the ArrayRef that was returned by your implementation of `MyDBD_connection_parameters`.

### Response

The response of this method is interpreted as a perl `boolean`.

---

# COPYRIGHT

&copy; `MMXXI` - Abe Timmerman <abeltje@cpan.org>

# LICENSE

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

