#!/usr/bin/env perl

use strict;
use warnings;
use Data::Section -setup;
use Path::Tiny 'path';
use Pg::ServiceFile;
use Test2::Bundle::More;
use Test2::Tools::Compare;
use Test2::Tools::Exception 'dies';

# ABSTRACT: testing connection service file using Pg::ServiceFile

subtest basic             => \&test_basic;
subtest names             => \&test_names;
subtest pgservice_env     => \&test_pgservice_env;
subtest pgservicefile_env => \&test_pgservicefile_env;
subtest services          => \&test_services;

sub test_basic {
    ok dies {
        my $pgservice = Pg::ServiceFile->new(
            file => 'does_not_exist.conf'
        )->services;
    };
}

sub test_names {
    my $pgservice = Pg::ServiceFile->new(
        data => ${__PACKAGE__->section_data('pg_service')}
    );
    is $pgservice->names => [qw/bar foo quxx/];
}

sub test_pgservice_env {
    # Specific tests for the PGSERVICE environmental variable
    local $ENV{PGSERVICE} = undef;

    is (
        Pg::ServiceFile->new(
            data => ${ __PACKAGE__->section_data('pg_service') }
        )->name => ''
    );

    # A PGSERVICE that actually exists
    local $ENV{PGSERVICE} = 'foo';

    my $pgservice = Pg::ServiceFile->new(
        data => ${__PACKAGE__->section_data('pg_service')}
    );

    is $pgservice->name              => 'foo';
    is $pgservice->service->{dbname} => 'db_foo';
}

sub test_pgservicefile_env {
    # Specific tests for the PGSERVICEFILE environmental variable
    local $ENV{PGSERVICEFILE}
        = path(__FILE__)->parent->child('data/my_pg_service.conf');

    my $pgservice = Pg::ServiceFile->new();
    is $pgservice->file  => $ENV{PGSERVICEFILE};
    is $pgservice->names => [qw/foo/];
}

sub test_services {
    my $pgservice = Pg::ServiceFile->new(
        data => ${__PACKAGE__->section_data('pg_service')}
    );

    my $foo = $pgservice->services->{foo};
    is $foo->{user} => 'foo';
}

done_testing;

__DATA__

__[ pg_service ]__

# comments are fine
# but need to be at the beginning of the line
[foo]
host=localhost
port=5432
user=foo
dbname=db_foo
password=password

[bar]
host=localhost
port=5432
user=bar
dbname=db_bar
password=password

[quxx]
host=localhost
port=5432
user=quxx
dbname=db_quxx
