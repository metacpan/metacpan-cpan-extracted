#!/usr/bin/perl

# ABSTRACT: evolve - evolve your schema to the latest version
use strict;
use warnings;

use FindBin '$Bin';
use lib "$Bin/../lib";

use SchemaEvolution;

my $app = SchemaEvolution->new_with_options;
$app->run;

=head1 DESCRIPTION

Schema evolution is a critical part of any developers work - the process of
changing the structure of a database overtime. However, while there are tools to
help with this task, the are not many that integrate well with version control
systems.

SchemaEvolution is a very basic command line application that helps automate
this process, while allowing you to also track changes in version control.

Each change to the database is tracked in a single SQL file, which are ordered
numerically. The database itself has a special column (schema_version.version by
default) that maintains track of the current version of the database, and the
C<evolve> command simply applies the set of SQL files after this version.

=head1 TUTORIAL

Let's briefly use evolve to track a small project - a little application that
has users and messages, and messages can be sent between users. The first thing
we need to do is create our C<evolution.ini> file. This configuration file tells
evolve how to connect to our database.

    dsn = dbi:Pg:dbname=messaging
    username = messaging
    password = hello

The dsn string is the same format as used by L<DBI>, in this case we're using
the PostgresSQL driver to connect to the messaging database, with the
credentials "messaging" and "hello"

Next, we need to add the version column into our database. By default this is
the version column in the schema_version table. We can either enter the SQL by
hand...

    CREATE TABLE schema_version (
         version INTEGER NOT NULL DEFAULT 0
    );
    INSERT INTO schema_version VALUES (0);

Or we can just let evolve.pl do it for us:

    evolve.pl --initialize

Great! Now we can start writing some schema evolutions. The first thing we need
in our system is support for users. Let's go with something basic. In our
application directory, create the folder "evolutions" and start with our first
definition, 1_user.sql

    CREATE TABLE 'user' (
        id SERIAL PRIMARY KEY,
        name TEXT NOT NULL
    );

Now, with our first schema evolution, all we have to do is run "evolve". As
we're at version 0 in our database, 1_user.sql will be applied. Now you can go
ahead and write your model in Perl code to access this table (DBIx::Class, Fey,
or whatever takes your fancy). Now we can check this in to our version control
system and Bob Other Developer can grab our code and get his database up to the
same as ours, great!

Likewise, we can continue with our messages table:

    CREATE TABLE 'messages' (
        id SERIAL PRIMARY KEY,
        to INT NOT NULL,
        from INT NOT NULL,
        message TEXT NOT NULL
    );

We just evolve again, and voila, we have a messages table. Again, our other
developers can just update their version control, run C<evolve> and then be up
to date ready to run code. New developers can do the same; for the them the
database would first get 1_user.sql applied, and then 2_messages.sql

=cut
