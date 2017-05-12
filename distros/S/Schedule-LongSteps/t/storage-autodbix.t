#! perl -wt

use strict;
use warnings;

use Test::More;

use DateTime;

eval "use DBD::SQLite";
plan skip_all => "DBD::SQLite is required for this test."
    if $@;

eval "use DBIx::Class";
plan skip_all => "DBIx::Class is required for this test" if $@;

eval "use SQL::Translator";
plan skip_all => "SQL::Translator is required for this test" if $@;

eval "use DBIx::Class::InflateColumn::Serializer";
plan skip_all => "DBIx::Class::InflateColumn::Serializer is required for this test" if $@;

eval "use DateTime::Format::SQLite";
plan skip_all => "DateTime::Format::SQLite is required for this test" if $@;


my $dbh = DBI->connect('dbi:SQLite:dbname=:memory:', undef, undef, {
    AutoCommit => 1,
    RaiseError => 1
});

use_ok('Schedule::LongSteps::Storage::AutoDBIx');

ok( my $storage = Schedule::LongSteps::Storage::AutoDBIx->new({ get_dbh => sub{ $dbh; } }) );
# $storage->deploy();
is( scalar( $storage->prepare_due_processes() ) , 0 , "Ok zero due steps");

# Note that we need that for SQLite, cause it hasnt got
# a datetime type. Therefore, we need to make sure the format is consistent with what is done
# inside the LongSteps::Storage::DBIxClass code.
my $dtf = $storage->schema->storage()->datetime_parser();

{
    $dbh->begin_work();
    ok( my $process_id = $storage->create_process({ process_class => 'Blabla',
                                                    state => {},
                                                    what => 'whatever',
                                                    run_at => $dtf->format_datetime( DateTime->now() )
                                                })->id(), "Ok got ID");
    $dbh->commit();
    ok( $storage->find_process($process_id) );
}


{
    $dbh->begin_work();
    my @due_processes = $storage->prepare_due_processes();
    is( scalar( @due_processes )  , 1);
    is( scalar( $storage->prepare_due_processes() ) , 0 , "Doing it again gives zero steps");
    $dbh->commit();
}

my $process = $storage->create_process({ process_class => 'Blabla',
                                         what => 'whatever',
                                         state => {},
                                         run_at => $dtf->format_datetime( DateTime->now() )
                                     });
ok( $storage->find_process($process->id()));
$storage->create_process({ process_class => 'Blabla',
                           what => 'whatever',
                           state => {},
                           run_at => $dtf->format_datetime( DateTime->now() )
                       });

my @steps = $storage->prepare_due_processes();
is( scalar( @steps ) , 2 , "Ok two steps to do");
foreach my $step ( @steps ){
    # While we are doing things, any other process would see zero things to do
    is( scalar( $storage->prepare_due_processes() ) , 0 , "Preparing steps again whilst they are running give zero steps");
}


done_testing();
