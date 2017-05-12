=head1 NAME

PApp::SQL - absolutely easy yet fast and powerful sql access.

=head1 SYNOPSIS

 use PApp::SQL;

 my $st = sql_exec $DBH, "select ... where a = ?", $a;

 local $DBH = <database handle>;
 my $st = sql_exec \my($bind_a, $bind_b), "select a,b ...";
 my $id = sql_insertid
             sql_exec "insert into ... values (?, ?)", $v1, $v2;
 my $a = sql_fetch "select a from ...";
 sql_fetch \my($a, $b), "select a,b ...";

 sql_exists "table where name like 'a%'"
    or die "a* required but not existent";

 my $db = new PApp::SQL::Database "", "DBI:mysql:test", "user", "pass";
 local $PApp::SQL::DBH = $db->checked_dbh; # does 'ping'

 sql_exec $db->dbh, "select ...";

=head1 DESCRIPTION

This module provides you with easy-to-use functions to execute sql
commands (using DBI). Despite being easy to use, they are also quite
efficient and allow you to write faster programs in less lines of code. It
should work with anything from perl-5.004_01 onwards, but I only support
5.005+. UTF8 handling (the C<sql_u*> family of functions) will only be
effective with perl version 5.006 and beyond.

If the descriptions here seem terse or if you always wanted to know
what PApp is then have a look at the PApp module which uses this module
extensively but also provides you with a lot more gimmicks to play around
with to help you create cool applications ;)

=cut

package PApp::SQL;

use Carp ();
use DBI ();

BEGIN {
   use base qw(Exporter DynaLoader);

   $VERSION = '2.0';
   @EXPORT = qw(
         sql_exec  sql_fetch  sql_fetchall  sql_exists sql_insertid $sql_exec
         sql_uexec sql_ufetch sql_ufetchall sql_uexists
   );
   @EXPORT_OK = qw(
         connect_cached
   );

   bootstrap PApp::SQL $VERSION;
}

boot2 DBI::SQL_VARCHAR, DBI::SQL_INTEGER, DBI::SQL_DOUBLE;

our $sql_exec;  # last result of sql_exec's execute call
our $DBH;       # the default database handle
our $Database;	# the current SQL::Database object, if applicable

our %dbcache;

=head2 Global Variables

=over 4

=item $sql_exec

Since the C<sql_exec> family of functions return a statement handle there
must be another way to test the return value of the C<execute> call. This
global variable contains the result of the most recent call to C<execute>
done by this module.

=item $PApp::SQL::DBH

The default database handle used by this module if no C<$DBH> was
specified as argument. See C<sql_exec> for a discussion.

=item $PApp::SQL::Database

The current default C<PApp::SQL::Database>-object. Future versions might
automatically fall back on this database and create database handles from
it if neccessary. At the moment this is not used by this module but might
be nice as a placeholder for the database object that corresponds to
$PApp::SQL::DBH.

=back

=head2 Functions

=over 4

=item $dbh = connect_cached $id, $dsn, $user, $pass, $flags, $connect

(not exported by by default)

Connect to the database given by C<($dsn,$user,$pass)>, while using the
flags from C<$flags>. These are just the same arguments as given to
C<DBI->connect>.

The database handle will be cached under the unique id
C<$id|$dsn|$user|$pass>. If the same id is requested later, the
cached handle will be checked (using ping), and the connection will
be re-established if necessary (be sure to prefix your application or
module name to the id to make it "more" unique. Things like __PACKAGE__ .
__LINE__ work fine as well).

The reason C<$id> is necessary is that you might specify special connect
arguments or special flags, or you might want to configure your $DBH
differently than maybe other applications requesting the same database
connection. If none of this is necessary for your application you can
leave C<$id> empty (i.e. "").

If specified, C<$connect> is a callback (e.g. a coderef) that will be
called each time a new connection is being established, with the new
C<$dbh> as first argument.

Examples:

 # try your luck opening the papp database without access info
 $dbh = connect_cached __FILE__, "DBI:mysql:papp";

Mysql-specific behaviour: The default setting of
C<mysql_client_found_rows> is TRUE, you can overwrite this, though.

=cut

sub connect_cached {
   my ($id, $dsn, $user, $pass, $flags, $connect) = @_;
   # the following line is duplicated in PApp::SQL::Database::new
   $id = "$id\0$dsn\0$user\0$pass";
   unless ($dbcache{$id} && $dbcache{$id}->ping) {
      # first, nuke our statement cache (sooory ;)
      cachesize cachesize 0;

      # then make mysql behave more standardly by default
      $dsn =~ /^[Dd][Bb][Ii]:mysql:/
         and $dsn !~ /;mysql_client_found_rows/
            and $dsn .= ";mysql_client_found_rows=1";

      # then connect anew
      $dbcache{$id} =
         eval { DBI->connect($dsn, $user, $pass, $flags) }
         || eval { DBI->connect($dsn, $user, $pass, $flags) }
         || Carp::croak "unable to connect to database $dsn: $DBI::errstr\n";
      $connect->($dbcache{$id}) if $connect;
   }
   $dbcache{$id};
}

=item $sth = sql_exec [dbh,] [bind-vals...,] "sql-statement", [arguments...]

=item $sth = sql_uexec <see sql_exec>

C<sql_exec> is the most important and most-used function in this module.

Runs the given sql command with the given parameters and returns the
statement handle. The command and the statement handle will be cached
(with the database handle and the sql string as key), so prepare will be
called only once for each distinct sql call (please keep in mind that the
returned statement will always be the same, so, if you call C<sql_exec>
with the same dbh and sql-statement twice (e.g. in a subroutine you
called), the statement handle for the first call mustn't not be in use
anymore, as the subsequent call will re-use the handle.

The database handle (the first argument) is optional. If it is missing,
it tries to use database handle in C<$PApp::SQL::DBH>, which you can set
before calling these functions. NOTICE: future and former versions of
PApp::SQL might also look up the global variable C<$DBH> in the callers
package.

=begin comment

If it is missing, C<sql_exec> first tries to use the variable C<$DBH>
in the current (= calling) package and, if that fails, it tries to use
database handle in C<$PApp::SQL::DBH>, which you can set before calling
these functions.

=end comment

The actual return value from the C<$sth->execute> call is stored in the
package-global (and exported) variable C<$sql_exec>.

If any error occurs C<sql_exec> will throw an exception.

C<sql_uexec> is similar to C<sql_exec> but upgrades all input arguments to
UTF-8 before calling the C<execute> method.

Examples:

 # easy one
 my $st = sql_exec "select name, id from table where id = ?", $id;
 while (my ($name, $id) = $st->fetchrow_array) { ... };

 # the fastest way to use dbi, using bind_columns
 my $st = sql_exec \my($name, $id),
                   "select name, id from table where id = ?",
                   $id;
 while ($st->fetch) { ...}

 # now use a different dastabase:
 sql_exec $dbh, "update file set name = ?", "oops.txt";


=item sql_fetch <see sql_exec>

=item sql_ufetch <see sql_uexec>

Execute an sql-statement and fetch the first row of results. Depending on
the caller context the row will be returned as a list (array context), or
just the first columns. In table form:

 CONTEXT	RESULT
 void		()
 scalar		first column
 list		array

C<sql_fetch> is quite efficient in conjunction with bind variables:

 sql_fetch \my($name, $amount),
           "select name, amount from table where id name  = ?",
           "Toytest";

But of course the normal way to call it is simply:

 my($name, $amount) = sql_fetch "select ...", args...

... and it's still quite fast unless you fetch large amounts of data.

C<sql_ufetch> is similar to C<sql_fetch> but upgrades all input values to
UTF-8 and forces all result values to UTF-8 (this does I<not> include result
parameters, only return values. Using bind variables in conjunction with
sql_u* functions might result in undefined behaviour - we use UTF-8 on
bind-variables at execution time and it seems to work on DBD::mysql as it
ignores the UTF-8 bit completely. Which just means that that DBD-driver is
broken).

=item sql_fetchall <see sql_exec>

=item sql_ufetchall <see sql_uexec>

Similarly to C<sql_fetch>, but all result rows will be fetched (this is
of course inefficient for large results!). The context is ignored (only
list context makes sense), but the result still depends on the number of
columns in the result:

 COLUMNS	RESULT
 0		()
 1		(row1, row2, row3...)
 many		([row1], [row2], [row3]...)

Examples (all of which are inefficient):

 for (sql_fetchall "select id from table") { ... }

 my @names = sql_fetchall "select name from user";

 for (sql_fetchall "select name, age, place from user") {
    my ($name, $age, $place) = @$_;
 }

C<sql_ufetchall> is similar to C<sql_fetchall> but upgrades all input
values to UTF-8 and forces all result values to UTF-8 (see the caveats in
the description of C<sql_ufetch>, though).

=item sql_exists "<table_references> where <where_condition>...", args...

=item sql_uexists <see sql_exists>

Check wether the result of the sql-statement "select xxx from
$first_argument" would be empty or not (that is, imagine the string
"select * from" were prepended to your statement (it isn't)). Should work
with every database but can be quite slow, except on mysql, where this
should be quite fast.

C<sql_uexists> is similar to C<sql_exists> but upgrades all parameters to
UTF-8.

Examples:

 print "user 7 exists!\n"
    if sql_exists "user where id = ?", 7;
 
 die "duplicate key"
    if sql_exists "user where name = ? and pass = ?", "stefan", "geheim";

=cut

=item $lastid = sql_insertid $sth

Returns the last automatically created key value. It must be executed
directly after executing the insert statement that created it. This is
what is actually returned for various databases. If your database is
missing, please send me an e-mail on how to implement this ;)

 mysql:    first C<AUTO_INCREMENT> column set to NULL
 postgres: C<oid> column (is there a way to get the last SERIAL?)
 sybase:   C<IDENTITY> column of the last insert (slow)
 informix: C<SERIAL> or C<SERIAL8> column of the last insert
 sqlite:   C<last_insert_rowid()>

Except for sybase, this does not require a server access.

=cut

sub sql_insertid($) {
   my $sth = shift or Carp::croak "sql_insertid requires a statement handle";
   my $dbh = $sth->{Database};
   my $driver = $dbh->{Driver}{Name};

   $driver eq "mysql"    and return $sth->{mysql_insertid};
   $driver eq "Pg"       and return $sth->{pg_oid_status};
   $driver eq "Sybase"   and return sql_fetch ($dbh, 'SELECT @@IDENTITY');
   $driver eq "Informix" and return $sth->{ix_sqlerrd}[1];
   $driver eq "SQLite"   and return sql_fetch ($dbh, 'SELECT last_insert_rowid ()');

   Carp::croak "sql_insertid does not support the dbd driver '$driver', at";
}

=item [old-size] = cachesize [new-size]

Returns (and possibly changes) the LRU cache size used by C<sql_exec>. The
default is somewhere around 50 (= the 50 last recently used statements
will be cached). It shouldn't be too large, since a simple linear list
is used for the cache at the moment (which, for small (<100) cache sizes
is actually quite fast).

The function always returns the cache size in effect I<before> the call,
so, to nuke the cache (for example, when a database connection has died
or you want to garbage collect old database/statement handles), this
construct can be used:

 PApp::SQL::cachesize PApp::SQL::cachesize 0;

=cut

=item reinitialize [not exported]

Clears any internal caches (statement cache, database handle
cache). Should be called after C<fork> and other accidents that invalidate
database handles.

=cut

sub reinitialize {
   cachesize cachesize 0;
   for (values %dbcache) {
      eval { $_->{InactiveDestroy} = 1 };
   }
   undef %dbcache;
}

=back

=cut

reinitialize;

=head2 Type Deduction

Since every database driver seems to deduce parameter types differently,
usually wrongly, and at leats in the case of DBD::mysql, different in
every other release or so, and this can and does lead to data corruption,
this module does type deduction itself.

What does it mean? Simple - sql parameters for placeholders will be
explicitly marked as SQL_VARCHAR, SQL_INTEGER or SQL_DOUBLE the first time
a statement is prepared.

To force a specific type, you can either continue to use e.g. sql casts,
or you can make sure to consistently use strings or numbers. To make a
perl scalar look enough like a string or a number, use this when passing
it to sql_exec or a similar functions:

   "$string"   # to pass a string
   $num+0      # to pass a number

=cut

package PApp::SQL::Database;

=head2 The Database Class

Again (sigh) the problem of persistency. What do you do when you have
to serialize on object that contains (or should contain) a database
handle? Short answer: you don't. Long answer: you can embed the necessary
information to recreate the dbh when needed.

The C<PApp::SQL::Database> class does that, in a relatively efficient
fashion: the overhead is currently a single method call per access (you
can cache the real dbh if you want).

=over 4

=item $db = new <same arguments as C<connect_cached>>

The C<new> call takes the same arguments as C<connect_cached> (obviously,
if you supply a connect callback it better is serializable, see
L<PApp::Callback>!) and returns a serializable database class. No database
handle is actually being created.

=item $db->dbh

Return the database handle as fast as possible (usually just a hash lookup).

=item $db->checked_dbh

Return the database handle, but first check that the database is still
available and re-open the connection if necessary.

=cut

sub new($$;@) {
   my $class = shift;
   my ($id, $dsn, $user, $pass, $flags, $connect) = @_;
   # the following line is duplicated in PApp::SQL::Database::new
   my $id2 = "$id\0$dsn\0$user\0$pass";
   bless [$id2, $flags, $connect], $class;
}

# the following two functions better be fast!
sub dbh($) {
   $dbcache{$_[0][0]} || $_[0]->checked_dbh;
}

sub checked_dbh($) {
   my $dbh = $dbcache{$_[0][0]};
   $dbh && $dbh->ping
      ? $dbh
      : PApp::SQL::connect_cached((split /\x00/, $_[0][0], 4), $_[0][1], $_[0][2]);
}

=item $db->dsn

Return the DSN (L<DBI>) fo the database object (e.g. for error messages).

=item $db->login

Return the login name.

=item $db->password

Return the password (emphasizing the fact that the password is stored plaintext ;)

=cut

sub dsn($) {
   my $self = shift;
   (split /\x00/, $self->[0])[1];
}

sub login($) {
   my $self = shift;
   (split /\x00/, $self->[0])[2];
}

sub password($) {
   my $self = shift;
   (split /\x00/, $self->[0])[3];
}

=back

=cut

1;

=head1 SEE ALSO

L<PApp>.

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

=cut

