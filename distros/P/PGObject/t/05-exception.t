use Test::More tests => 9;
use PGObject::Util::DBException;
use DBI;

# the internal constructor
ok(my $e = PGObject::Util::DBException->internal(
        'ABCDE', 'Something silly', 'What are we doing here?',
        1,2,'132', 'FooBar'));
is($e->{state}, 'ABCDE', 'Got back the correct state');
is($e->{errstr}, 'Something silly', 'Errstr works');
is($e->{query}, 'What are we doing here?', 'Got our query back').
is_deeply($e->{args}, [1,2,'132', 'FooBar'], 'Got back the args');
is($e->{trace}, undef, 'No stack trace');
is("$e", 'ABCDE: Something silly', 'Stringification works properly');
is($e->short_string, 'ABCDE: Something silly', 'Stringification works properly 2');
is($e->log_msg, 
    "STATE ABCDE, Something silly
Query: What are we doing here?
Args: 1,2,132,FooBar", 'Got the log message');
