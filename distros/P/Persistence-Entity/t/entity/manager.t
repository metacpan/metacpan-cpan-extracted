use strict;
use warnings;

use Test::More tests => 18;
use Test::DBUnit connection_name => 'test';

my $class;

BEGIN {
        $class = 'Persistence::Entity::Manager';
	use_ok($class);
	use_ok('Persistence::Entity', ':all');
}


my %trigger_test;
my %orm_trigger_test;
my $entity_manager = $class->new(name => 'my_manager', connection_name => 'test');
isa_ok($entity_manager, $class);

$entity_manager->add_entities(Persistence::Entity->new(
    name                  => 'emp',
    unique_expression     => 'empno',
    primary_key           => ['empno'],
    columns               => [
        sql_column(name => 'ename'),
        sql_column(name => 'empno'),
        sql_column(name => 'deptno')
    ],
    triggers => {
        on_fetch => sub {
           $trigger_test{on_fetch} ||= 0;
           $trigger_test{on_fetch}++;
        },
        before_insert => sub {
           $trigger_test{before_insert} ||= 0;
           $trigger_test{before_insert}++;
        },
        after_insert => sub {
           $trigger_test{after_insert} ||= 0;
           $trigger_test{after_insert}++;
        },
        before_update => sub {
           $trigger_test{before_update} ||= 0;
           $trigger_test{before_update}++;
        },
        after_update => sub {
           $trigger_test{after_update} ||= 0;
           $trigger_test{after_update}++;
        },
        before_delete => sub {
           $trigger_test{before_delete} ||= 0;
           $trigger_test{before_delete}++;
        },
        after_delete => sub {
           $trigger_test{after_delete} ||= 0;
           $trigger_test{after_delete}++;
        },
     
    }
));

isa_ok($entity_manager->entity('emp'), 'SQL::Entity');


SKIP: {
    
    skip('missing env varaibles DB_TEST_CONNECTION, DB_TEST_USERNAME DB_TEST_PASSWORD', 14)
      unless $ENV{DB_TEST_CONNECTION};

    my $connection = DBIx::Connection->new(
      name     => 'test',
      dsn      => $ENV{DB_TEST_CONNECTION},
      username => $ENV{DB_TEST_USERNAME},
      password => $ENV{DB_TEST_PASSWORD},
    ); 
   
   
    SKIP: {

        my $dbms_name  = $connection->dbms_name;
            skip('Tests are not prepared for ' . $dbms_name , 14)
                unless -d "t/sql/". $connection->dbms_name;
   
        # preparing tests
        reset_schema_ok("t/sql/". $connection->dbms_name . "/create_schema.sql");
        populate_schema_ok("t/sql/". $connection->dbms_name . "/populate_schema.sql");
        
        $entity_manager->begin_work;
        
        eval {
                $entity_manager->begin_work;
        };
        
        like($@, qr{active transaction}, 'catch active transaction error');
        
        {
            package Employee;
    
            use Abstract::Meta::Class ':all';
            use Persistence::ORM ':all';
            entity 'emp';
    
            trigger (on_fetch => sub {
               $orm_trigger_test{on_fetch} ||= 0;
               $orm_trigger_test{on_fetch}++;
            });
            
            trigger (before_insert => sub {
               $orm_trigger_test{before_insert} ||= 0;
               $orm_trigger_test{before_insert}++;
            });
            
            trigger (after_insert => sub {
               $orm_trigger_test{after_insert} ||= 0;
               $orm_trigger_test{after_insert}++;
            });
            
            trigger (before_update => sub {
               $orm_trigger_test{before_update} ||= 0;
               $orm_trigger_test{before_update}++;
            });
            
            trigger (after_update => sub {
               $orm_trigger_test{after_update} ||= 0;
               $orm_trigger_test{after_update}++;
            });
            
            trigger (before_delete => sub {
               $orm_trigger_test{before_delete} ||= 0;
               $orm_trigger_test{before_delete}++;
            });
            
            trigger (after_delete => sub {
               $orm_trigger_test{after_delete} ||= 0;
               $orm_trigger_test{after_delete}++;
            });
            
            #or xml equivalent
            column empno => has('$.no') ;
            column ename => has('$.name');
            column deptno => has('$.deptno');
    
            {
                my $emp = Employee->new(
                    no     => 1,
                    name   => 'adrian',
                    deptno => '1'
                );
                $entity_manager->insert($emp);
                
                #update no needed
                $entity_manager->update($emp);
                
                $emp->set_deptno(2);
                
                $entity_manager->update($emp);
                
            }
    
            {
                my ($emp) = $entity_manager->find(emp => 'Employee', ::sql_cond('ename', '=', 'adrian'));
                ::isa_ok($emp, 'Employee', 'deserialise object');
                ::is($emp->name, 'adrian', "have requested object");
        
            }
            {
                my ($emp) = $entity_manager->find(emp => 'Employee', name => 'adrian');
                ::isa_ok($emp, 'Employee', 'deserialise object');
                ::is($emp->name, 'adrian', "have requested object");
                $entity_manager->delete($emp);
            }
            
            my $event_stats =  {
              'after_update' => 1,
              'before_update' => 1,
              'before_insert' => 1,
              'on_fetch' => 2,
              'after_insert' => 1,
              'before_delete' => 1,
              'after_delete' => 1,
            };
            ::is_deeply(\%trigger_test ,$event_stats, "should have all Entity events");
            #$event_stats->{on_fetch} = 2;
            ::is_deeply(\%orm_trigger_test ,$event_stats, "should have all ORM events");
        
            my $emp = Employee->new(
                no     => 102,
                name   => 'test_102',
                deptno => '1'
            );
             
            $entity_manager->merge($emp);
            ::is($trigger_test{after_insert}, 2, "insert forced by merge");
            ::is($trigger_test{after_update}, 1, "insert forced by merge");
    
            $emp->set_name('test_105');
            $entity_manager->merge($emp);
            ::is($trigger_test{on_fetch}, 3, "fetch forced by merge");
            ::is($trigger_test{after_insert}, 2, "no insert forced by merge");
            ::is($trigger_test{after_update}, 2, "update forced by merge");
            
        }
    
        $entity_manager->commit;
    }
}