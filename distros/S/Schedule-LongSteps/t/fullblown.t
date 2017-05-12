#! perl -w

use strict;
use warnings;
use Test::More;
use Test::MockDateTime;

use DateTime;

use Schedule::LongSteps;

BEGIN{
  eval "use Test::mysqld";
  plan skip_all => "Test::mysqld is required for this test" if $@;

  eval "use DBIx::Class";
  plan skip_all => "DBIx::Class is required for this test" if $@;

  eval "use SQL::Translator";
  plan skip_all => "SQL::Translator is required for this test" if $@;

  eval "use DBIx::Class::InflateColumn::Serializer";
  plan skip_all => "DBIx::Class::InflateColumn::Serializer is required for this test" if $@;

  eval "use DateTime::Format::MySQL";
  plan skip_all => "DateTime::Format::MySQL is required for this test" if $@;

  eval "use Net::EmptyPort";
  plan skip_all => "Net::EmptyPort is required for this test" if $@;
}


#
# This is a real life test. Using a common DB engine
#
my $test_mysql = Test::mysqld->new(my_cnf => {
                                              port => Net::EmptyPort::empty_port()
                                             }) or plan skip_all => $Test::mysqld::errstr;



#
#  We build a DBIx::Class::Schema, starting with the Result classes.
#
{
    package MyApp::Schema::Result::Patient;
    use base qw/DBIx::Class::Core/;
    __PACKAGE__->table('patient');
    __PACKAGE__->add_columns(
        id =>
            { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
        name =>
            { data_type => 'varchar', is_nullable => 0, size => 50 },
        looks_cancerous =>
            { data_type => 'integer', is_nullable => 0 , default_value => 0 },
        family_history =>
            { data_type => 'integer', is_nullable => 0 , default_value => 0 },
    );
    __PACKAGE__->set_primary_key("id");
    1;
}

{
    package MyApp::Schema::Result::Process;
    use base qw/DBIx::Class::Core/;
    __PACKAGE__->table('longprocess');
    __PACKAGE__->load_components(qw/InflateColumn::DateTime InflateColumn::Serializer/);
    __PACKAGE__->add_columns(
        id =>
            { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
        process_class =>
            { data_type => "varchar", is_nullable => 0, size => 255 },
        what =>
            { data_type => "varchar", is_nullable => 1, size => 255 },
        status =>
            { data_type => "varchar", is_nullable => 0, size => 50 , default_value => 'pending' },
        run_at =>
            { data_type => "datetime", datetime_undef_if_invalid => 1, is_nullable => 1 },
        run_id =>
            { data_type => "varchar", is_nullable => 1, size => 36 },
        state =>
            { data_type => "text",
              serializer_class => 'JSON',
              is_nullable => 0,
          },
        error =>
            { data_type => "text", is_nullable => 1 }
        );

    __PACKAGE__->set_primary_key("id");
    sub sqlt_deploy_hook {
        my ($self, $sqlt_table) = @_;
        $sqlt_table->add_index(name => 'idx_longprocess_run_id', fields => ['run_id']);
        $sqlt_table->add_index(name => 'idx_longprocess_run_at', fields => ['run_at']);
    }
    1;
}

{
    package MyApp::Schema;
    use base qw/DBIx::Class::Schema/;
    __PACKAGE__->load_classes({ 'MyApp::Schema::Result' => [ 'Process', 'Patient' ] });

    sub connection{
        my ($class, @args ) = @_;
        unless( ( ref $args[0] || '' ) eq 'CODE' ){
            defined( $args[3] ) or ( $args[3] = {} );
            $args[3]->{AutoCommit} = 1;
            $args[3]->{RaiseError} = 1;
            $args[3]->{mysql_enable_utf8} = 1;
            ## Only for mysql DSNs
            $args[3]->{on_connect_do} = ["SET SESSION sql_mode = 'TRADITIONAL'"];
        }
        my $self = $class->next::method(@args);
        return $self;
    }
    1;
}

#
# Then we build our test Process.
#
{
    package MyMedicalProcess;
    # Inspired by https://en.wikipedia.org/wiki/XPDL Medical process example
    use Moose;
    extends qw/Schedule::LongSteps::Process/;

    use DateTime;

    has 'schema' => ( is => 'ro', isa => 'DBIx::Class::Schema', required => 1);

    has 'patient' => ( is => 'ro', lazy_build => 1 );
    sub _build_patient{
        my ($self) = @_;
        return $self->schema()->resultset('Patient')->find($self->state()->{patient_id});
    }

    sub build_first_step{
        my ($self) = @_;
        return $self->new_step({ what => 'do_first_look', run_at => DateTime->now() });
    }

    sub do_first_look{
        my ($self) = @_;
        my $state = $self->state();
        my $patient = $self->patient();
        if( ! $patient->looks_cancerous() ){
            return $self->final_step({ state => { %$state , has_cancer => 0 } });
        }
        return $self->new_step({ what => 'do_analyze_more', run_at => DateTime->now() });
    }

    sub do_analyze_more{
        my ($self) = @_;
        my $state = $self->state();
        my $p1 = $self->longsteps->instantiate_process('AnalyzePatient', { schema =>  $self->schema()  }, { %$state });
        my $p2 = $self->longsteps->instantiate_process('AnalyzeFamily', { schema => $self->schema() } , { %$state });
        return $self->new_step({ what => 'do_synthetize_analyzes', run_at => DateTime->now()->add( days => 3 ),
                                 state => { %$state , processes => [ $p1->id(), $p2->id() ] } });
    }
    sub do_synthetize_analyzes{
        my ($self) = @_;
        return $self->wait_processes(
            $self->state()->{processes},
            sub{
                my ( @processes ) = @_;
                return $self->new_step({
                    what => 'do_prescribe',
                    run_at => DateTime->now(),
                    state => {
                        %{$self->state()},
                        map{ %{$_->state()} } @processes
                    }});
            });
    }
    sub do_prescribe{
        my ($self) = @_;
        my $state = $self->state();
        if( $self->patient()->looks_cancerous() &&
                ( $state->{has_cancer_cells} ||
                  $state->{has_cancer_history} )
            ){
            return $self->final_step({ state => { %$state , have_treatment => 1 } });
        }
        return $self->final_step({ state => { %$state , have_treatment => 0 } });
    }
    __PACKAGE__->meta->make_immutable();
}

{
    package AnalyzePatient;
    use Moose;
    extends qw/Schedule::LongSteps::Process/;

    has 'schema' => ( is => 'ro', isa => 'DBIx::Class::Schema', required => 1);

    sub build_first_step{
        my ($self) = @_;
        return $self->new_step({ what => 'do_analyze_patient', run_at => DateTime->now() });
    }
    sub do_analyze_patient{
        my ($self) = @_;
        return $self->final_step({ state => { has_cancer_cells => 0 } });
    }
    __PACKAGE__->meta->make_immutable();
}

{
    package AnalyzeFamily;
    use Moose;
    extends qw/Schedule::LongSteps::Process/;

    has 'schema' => ( is => 'ro', isa => 'DBIx::Class::Schema', required => 1);

    has 'patient' => ( is => 'ro', lazy_build => 1);
    sub _build_patient{
        my ($self) = @_;
        return $self->schema->resultset('Patient')->find($self->state()->{patient_id});
    }

    sub build_first_step{
        my ($self) = @_;
        return $self->new_step({ what => 'do_analyze_family', run_at => DateTime->now()->add(days => 2) });
    }
    sub do_analyze_family{
        my ($self) = @_;
        return $self->final_step({ state => { has_cancer_history => $self->patient->family_history() } });
    }
    __PACKAGE__->meta->make_immutable();
}

#
# Time to make all the wheels turn.
#

my $schema = MyApp::Schema->connect( $test_mysql->dsn(), '', '' );
$schema->deploy();


use_ok('Schedule::LongSteps::Storage::DBIxClass');
use_ok('Schedule::LongSteps::Storage::AutoDBIx');


my $storage_dbixclass = Schedule::LongSteps::Storage::DBIxClass->new({
    schema => $schema,
    resultset_name => 'Process'
});
my $long_steps_dbixclass = Schedule::LongSteps->new({
    storage => $storage_dbixclass
});

my $storage_auto = Schedule::LongSteps::Storage::AutoDBIx->new({ get_dbh => sub{ return $schema->storage()->dbh(); } });
my $long_steps_auto = Schedule::LongSteps->new({
    storage => $storage_auto
});

foreach my $long_steps ( $long_steps_dbixclass , $long_steps_auto ){

    # Build some data, a  process and run it.

    my $patient = $schema->resultset('Patient')->create({ name => 'Joe Foobar' });
    my $cancerous_patient = $schema->resultset('Patient')->create({ name => 'Joe BarBaz' , looks_cancerous => 1 });
    my $cancerous_family  = $schema->resultset('Patient')->create({ name => 'Joe BarBaz' , looks_cancerous => 1 , family_history => 1 });


    ok( my $healthy_process = $long_steps->instantiate_process('MyMedicalProcess', { schema => $schema } , { patient_id => $patient->id() }) );
    ok( my $cancer_process = $long_steps->instantiate_process('MyMedicalProcess', {  schema => $schema } , { patient_id => $cancerous_patient->id() }) );
    ok( my $family_process = $long_steps->instantiate_process('MyMedicalProcess', {  schema => $schema } , { patient_id => $cancerous_family->id() }) );

    # This would run in a completely separate process
    ok( $long_steps->run_due_processes({ schema => $schema }) );

    $healthy_process->discard_changes(); # This is needed, cause the framework only does 'update'
    $cancer_process->discard_changes();

    is( $healthy_process->status(), 'terminated' );
    is( $cancer_process->status(), 'paused' );
    is( $cancer_process->what() , 'do_analyze_more');

    ok( $long_steps->run_due_processes({ schema => $schema }) );
    $cancer_process->discard_changes();
    is( $cancer_process->what() , 'do_synthetize_analyzes');

    # Some stuff should run now.
    ok( $long_steps->run_due_processes({ schema => $schema }) );

    # Simulate 3 days after now.
    my $three_days = DateTime->now()->add( days => 3 );

    on $three_days.'' => sub{
        # And more stuff should run three days after
        ok( $long_steps->run_due_processes({ schema => $schema }) );
        # Give it another go.
        $long_steps->run_due_processes({ schema => $schema });
        $cancer_process->discard_changes();
        is( $cancer_process->what() , 'do_prescribe' );

        # Give it another go and check that the final state is reached.
        ok( $long_steps->run_due_processes({ schema => $schema }) );
        $cancer_process->discard_changes();
        is( $cancer_process->status() , 'terminated' );
        is( $cancer_process->state()->{have_treatment}, 0 );

        $family_process->discard_changes();
        is( $family_process->status() , 'terminated' );
        is( $family_process->state()->{have_treatment}, 1 );
    };
}


done_testing();
