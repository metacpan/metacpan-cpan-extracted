package Schema::RDBMS::AUS;

use 5.006;
use strict;
use warnings;

use DBI;
use DBIx::Transaction;
use DBIx::Migration::Directories::Base;

our $VERSION = '0.04';
our $SCHEMA_VERSION = '0.01';

our @optmap = (
    ['AUS_DB_DSN',  'DBI_DSN'],
    ['AUS_DB_USER', 'DBI_USER'],
    ['AUS_DB_PASS', 'DBI_PASS'],
);

sub sdbh {
    my $class = shift;
    my $dbh = $class->dbh(@_);
    
    DBIx::Migration::Directories::Base->new(dbh=>$dbh)->require_schema(
        'Schema-RDBMS-AUS'  =>  $VERSION
    );
    
    return $dbh;
}

sub db_opts {
    my($class, @db_opts) = @_;
    
    $db_opts[$_->[0]] = $ENV{$_->[1]}
        foreach(
            grep    { defined $_->[1] }
            map     { [ $_, (grep { defined $ENV{$_} } @{$optmap[$_]})[0] ] }
            grep    { !defined $db_opts[$_] }
                ($[ .. $#optmap)
        );

    $db_opts[3] = {
        RaiseError => 1, PrintError => 0, PrintWarn => 0, AutoCommit => 1
    } unless defined $db_opts[3];
    
    return(@db_opts);
}

sub dbh {
    my($class, @db_opts) = @_;
   
    @db_opts = $class->db_opts(@db_opts);
    
    my $dbh = DBIx::Transaction->connect_cached(@db_opts)
        or die "Database connection @db_opts[0,1] failed: ", DBI->errstr;

    return $dbh;
}

1;
