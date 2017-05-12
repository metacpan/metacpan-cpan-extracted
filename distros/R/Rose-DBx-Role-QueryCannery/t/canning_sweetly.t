#!/usr/bin/env perl
#
# $Id$

BEGIN {
    require Test::More;
    if ( eval { require Rose::DBx::CannedQuery::Glycosylated } ) {
        Test::More->import( tests => 7 );
    }
    else {
        Test::More->import(
            skip_all => 'No Rose::DBx::CannedQuery::Glycosylated' );
    }
}

package My::Test::Logger;

sub new { my $str = ''; return bless \$str, shift; }

sub info { my ( $self, $msg ) = @_; $$self .= $msg; }

sub warn { }

sub message { my $self = shift; $$self; }

package My::Test::Shell;

sub new { my ( $class, %args ) = @_; return bless \%args; }

sub results { shift->{logger}->info('Test message'); }

package My::Cannery;
use Rose::DBx::CannedQuery::Glycosylated;
use Rose::DBx::Role::QueryCannery;
use Moo 2;
with 'MooX::Role::Chatty';    # verbose and logger attrs for us
Rose::DBx::Role::QueryCannery->apply(
    {
        query_class => 'Rose::DBx::CannedQuery::Glycosylated',
        rdb_class   => 'My::Test::Shell',
        rdb_params  => { domain => 'test', type => 'vapor' }
    }
);

### And now, the tests
package main;

my $logger  = My::Test::Logger->new;
my $cannery = My::Cannery->new( verbose => 1, logger => $logger );
my $qry     = $cannery->build_query('SELECT * FROM test WHERE color = ?');
isa_ok( $qry, 'Rose::DBx::CannedQuery::Glycosylated', 'query class' );

is( $qry->rdb_class, 'My::Test::Shell', 'RDB class name' );
is( $qry->verbose,   1,                 'default verbosity level' );
is( $qry->logger,    $logger,           'default logger' );

$qry = $cannery->build_query(
    'SELECT * FROM test WHERE color = ?',
    {
        verbose => 3,
        logger  => My::Test::Logger->new,
        name    => 'logger_test'
    }
);
is( $qry->verbose, 3, 'override verbosity level' );
isnt( $qry->logger, $logger, 'override logger' );

# Haven't bothered to set up db; just looking for log message
eval { $qry->do_one_query; };

is(
    $qry->logger->message,
    "Executing logger_test with query modifiers:\n\t{}",
    'message to custom logger'
);
