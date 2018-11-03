package TaskPipe::TestUtils::Resume;

use Moose;
use Test::More;
use Time::HiRes qw(gettimeofday tv_interval);
use TaskPipe::TaskUtils;
use TaskPipe::TestUtils::Basic;
use Carp;


has root_dir => (is => 'ro', isa => 'Str', required => 1);
has configs => (is => 'ro', isa => 'ArrayRef', required => 1);
has n_tests => (is => 'ro', isa => 'Int', required => 1);

has utils => (is => 'rw', isa => 'TaskPipe::TaskUtils');
has modes => (is => 'ro', isa => 'ArrayRef', default => sub{['id','md5']});
has specs => (is => 'rw', isa => 'HashRef');
has basic => (is => 'ro', isa => 'TaskPipe::TestUtils::Basic', lazy => 1, default => sub{
    +TaskPipe::TestUtils::Basic->new(
        root_dir => $_[0]->root_dir
    );
});
has test_setup_info => (is => 'rw', isa => 'Str');


sub create_plan{
    my ($self) = @_;

    my $plan = [];
    my $last_table;   
    foreach my $table ( qw( city company employee ) ){

        last unless +$self->specs->{$table};

        push @$plan, +$self->Task_SeparateArray($table);
        push @$plan, +$self->Task_Record($table,$last_table);
        $last_table=$table;

    }

    return $plan;
}
        

sub Task_SeparateArray{
    my ($self,$table) = @_;

    my $max = $self->specs->{$table};

    return {
        _name => 'SeparateArray',
        array => "1..$max"
    };
}


sub Task_Record{
    my ($self,$table,$key_table) = @_;

    my $task = {
        _name => 'Record',
        table => $table,
        'values' => {
            label => '$this{li}',
        }
    };

    $task->{'values'}{$key_table.'_id'} = '$this[1]{id}' if $key_table;
    return $task;
}


sub expected_n_ops{
    my ($self) = @_;

    my $city = $self->specs->{city};
    my $company = $self->specs->{company};
    my $employee = $self->specs->{employee};

    my $x = $city + ( $city * $company )
        + ( $city * $company * $employee );
    return $x;
}


sub test_results{
    my ($self) = @_;

    my $tot = 1;
    foreach my $table ( qw(city company employee ) ){
        $tot *= $self->specs->{$table};
        #my $rs = $self->utils->sm->table($table,'plan')->search({});
        my $n = $self->count($table);
        #is( $rs->count, $tot, $self->test_setup_info." Number of records on $table table" );
        is( $n, $tot, $self->test_setup_info." Number of records on $table table" );
    }

    my @kids = ('company','employee');
    $self->test_table_rows('city',\@kids);
}




sub test_table_rows{
    my ($self,$table,$kids,$last_table,$id) = @_;

    for my $i (1..$self->specs->{$table}){

        my $search = { label => $i };
        if ( $last_table ){
            $search->{$last_table.'_id'} = $id;
        }
            
        #my $rs = $self->utils->sm->table($table,'plan')->search($search);
        my $set = $self->search( $table,$search );
     
        is ( scalar(@$set), 1, $self->test_setup_info." Record [".$self->utils->serialize($search)."] exists on $table table" );

        if ( @$kids ){
            my $kid_table = shift( @$kids );
            $self->test_table_rows($kid_table,$kids,$table,$set->[0]{id});
        }
    }
}





sub test_operations{
    my ($self) = @_;

    my $n_ops = $self->count('operations');
    my $x_n_ops = $self->expected_n_ops;

    cmp_ok($n_ops, '>=', $x_n_ops, $self->test_setup_info." Number of ops >= minimum");
    cmp_ok($n_ops, '<=', $x_n_ops + $self->specs->{threads}, $self->test_setup_info." Number of ops within tolerance");

}


sub count{
    my ($self,$table) = @_;

    my $ops_rs = $self->utils->sm->table( $table, 'plan' )->search({});
    return +$ops_rs->count;
}

sub search{
    my ($self,$table,$search) = @_;

    my $rs = $self->utils->sm->table($table,'plan')->search($search);
    my $set = [];

    while( my $row = $rs->next ){
        push @$set, { $row->get_columns };
    }

    return $set;
}



sub run_tests{
    my ($self) = @_;

    my $preops;
    my $count;
    my $n_tests = $self->n_tests;
    #my $n_tests = 1;

    $self->basic->clear_tables;

    my $sm = $_[0]->basic->cmdh->handler->schema_manager;
    my $gm = $_[0]->basic->cmdh->handler->job_manager->gm;
    $self->utils(
        TaskPipe::TaskUtils->new(
            sm => $sm,
            gm => $gm
        )
    );
#    my %specs;
#    my $mode;

    for my $mode (@{$self->modes}){

        for my $specs (@{$self->configs}){
            $self->specs( $specs );
#            %specs = %$specs;

            my $plan = $self->create_plan;
            my $p = {
                plan => $plan,
                key_mode => $mode, 
                threads => $self->specs->{threads}
            };

            my $tot_run_time = $self->basic->run_plan( $p );
            my $wait_period = $tot_run_time / $n_tests;
            #print "wait period $wait_period tot_run_time $tot_run_time\n";

            for my $i (1..$n_tests){
                $count = $i;

                my $pid = fork();
                if ( $pid ){

                    #$self->basic->taskpipe(["clear","tables", "--group" => "project"]);
                    $self->basic->clear_tables;
                    my $wait_time = ( $i + 1  ) * $wait_period;
                    #print "   wait time $wait_time\n";

                    sleep($wait_time);
                    $self->basic->stop_job( $pid );

                    sleep 1;

                    $preops = $self->count('operations');

                    $self->basic->cmdh->run_info->scope('project');
                    $self->basic->run_plan( $p );

                    sleep 1;

                    $self->test_setup_info("mode: $mode count: $count preops: $preops specs: "
                        .$self->utils->serialize( $self->specs ));

                    $self->test_results;
                    $self->test_operations;
                    #$self->basic->taskpipe(["clear","tables", "--group" => "project"]);
                    $self->basic->clear_tables;


                } else {
                    $self->basic->run_plan( $p );
                    exit;
                }
            }
        }
    }
}


1;

