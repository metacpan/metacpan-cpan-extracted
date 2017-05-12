#!perl

BEGIN {
    $SIG{__DIE__} = \&Carp::confess;
}

package My::DB;
use FindBin;
use IO::File;
use base 'Rose::Planter::DB';
use File::Temp qw( tempdir );

BEGIN {
    __PACKAGE__->register_databases(
        module_name => 'Rose::Planter',
        # Really we need a Module::Build::Database::SQLite, but until then :
        register_params => {
            driver   => "sqlite",
            database => tempdir( CLEANUP => 1) . "/db.sqlite",
        }
    );
}

sub do_init_db {
    my $fp = IO::File->new("$FindBin::Bin/../eg/fooparams.sql");
    my $db = My::DB->new();

    {
        local $/ = ';';
        while (<$fp>) {
            next unless /\S/;
            $db->dbh->do($_);
        }
    }
}

package main;
use Test::More qw/no_plan/;
use strict;

BEGIN {
    My::DB->do_init_db();
    eval <<DONE;
    use Rose::Planter
        loader_params =>
            {   db_class => "My::DB",
                class_prefix => "My::Object",
            } 
DONE
    ok !$@, "used Rose::Planter" or diag $@;
}

diag( "Testing Rose::Planter $Rose::Planter::VERSION, Perl $], $^X" );

my $h = {
    stuff  => 123,
    params => [
                 { name => "froogle",  value => "frogle"  },
                 { name => "froogle2", value => "frogle2"  },
              ]
};

my $new_object = My::Object::Foo->new( %$h );

ok $new_object->save, "created new object";

my $got = $new_object->as_hash;

$h->{fookey} = $got->{fookey};

is_deeply ($got,$h);

1;

