package Test::DB::Shared::mysqld;
$Test::DB::Shared::mysqld::VERSION = '0.004';

=head1 NAME

Test::DB::Shared::mysqld - Replaces (and decorate) Test::mysqld to share the MySQL instance between your tests

=head1 SYNOPSIS

If in your test you use L<Test::mysqld>, this acts as a replacement for Test::mysqld:

  my $mysqld = Test::DB::Shared::mysqld->new(
      test_namespace => 'myapp',
      # Then it's plain Test::mysqld config
      my_cnf => {
        'skip-networking' => '', # no TCP socket
     }
  );

  # and use like Test::mysqld:
  my $dbh = DBI->connect(
      $mysqld->dsn(), undef, ''
  );

And that's it. No special code to write, no restructuring of your tests, and using as
a prove plugin is optional.

=head1 STATEMENT

What you need is a test database, not a test mysqld instance.

=head1 HOW TO USE IT

See synopsis for the change to your test code. For the rest, you need to use C<prove -j number>
to benefit from it.

If not all your test use the test db, best results will be obtained by using C<prove -s -j number>

=head2 Using it as a prove Plugin

To speed things even further, you can use that as a prove plugin, with an optional config file:

  prove -PTest::DB::Shared::mysqld

Or

  prove -PTest::DB::Shared::mysqld=./testmysqld.json

The ./testmysqld.json file can contain the arguments to Test::DB::Shared::mysqld in a json format (see SYNOPSIS). They
will be used to build one instance for the whole test suite.

If no such file is given, the default configuration is the one specified in the SYNOPSIS, but with a randomly generated test_namespace.

Note that using this plugin will result in all your Test::DB::Shared::mysqld instances in your t/ files using the same configuration,
regardless of what configuration you give in this or this test.

=head1 LIMITATIONS

Do NOT use that if your test involves doing anything outside a test database. Tests that manage databases
will probably break this.

Not all mysqld methods are available. Calls like 'start', 'stop', 'setup', 'read_log' .. are not implemented.

=head1 WHAT THIS DOES

The first time this is used, it will create a Test::mysqld instance in the current process. Then concurrent processes
that use the same module (with the same parameters) will be given a new Database in this already running instance, instead
of a new MySQL instance.

When this goes out of scope, the test database is destroy, and the last process to destroy the last database will tear
down the MySQL instance.

=head1 BUGS, DIAGNOSTICS and TROUBLESHOOTING

There are probably some. To diagnose them, you can run your test in verbose mode ( prove -v ). If that doesn't help,
you can 'use Log::Any::Adapter qw/Stderr/' at the top of your test to get some very verbose tracing.

If you SIGKILL your whole test suite, bad things will happen. Running in verbose mode
will most probably tell you which files you should clean up on your filesystem to get back to a working state.

=head1 METHODS

=cut

use Moo;
use Carp qw/confess/;
use Log::Any qw/$log/;

use DBI;

use JSON;
use Test::mysqld;

use File::Slurp;
use File::Spec;
use File::Flock::Tiny;

use POSIX qw(SIGTERM WNOHANG);

use Test::More qw//;

# Settings
has 'test_namespace' => ( is => 'ro', default => 'test_db_shared' );

# Public facing stuff
has 'dsn' => ( is => 'lazy' );


# Internal cuisine

has '_lock_file' => ( is => 'lazy' );
has '_mysqld_file' => ( is => 'lazy' );

sub _build__lock_file{
    my ($self) = @_;
    return File::Spec->catfile( File::Spec->tmpdir() , $self->_namespace().'.lock' ).'';
}
sub _build__mysqld_file{
    my ($self) = @_;
    return File::Spec->catfile( File::Spec->tmpdir() , $self->_namespace().'.mysqld' ).'';
}

has '_testmysqld_args' => ( is => 'ro', required => 1);
has '_temp_db_name' => ( is => 'lazy' );
has '_shared_mysqld' => ( is => 'lazy' );
has '_instance_pid' => ( is => 'ro', required => 1);
has '_holds_mysqld' => ( is => 'rw' );

my $PROCESS_INSTANCES = {};

around BUILDARGS => sub {
    my ($orig, $class, @rest ) = @_;

    my $hash_args = $class->$orig(@rest);
    my $test_namespace = delete $hash_args->{test_namespace};

    return {
        _testmysqld_args => $hash_args,
        _instance_pid => $$,
        ( $test_namespace ? ( test_namespace => $test_namespace ) : () ),
        ( $ENV{TEST_DB_SHARED_NAMESPACE} ? ( test_namespace => $ENV{TEST_DB_SHARED_NAMESPACE} ) : () ),
    }
};

sub BUILD{
    my ($self) = @_;
    my $wself = \$self;
    Scalar::Util::weaken( $self );
    $PROCESS_INSTANCES->{$self.''} = $wself;
    return $self;
}

=head2 load

L<App::Prove> plugin implementation. Do NOT use that yourself.

=cut

{
    my $plugin_instance;
    sub load{
        my ($class, $prove) = @_;
        my @args = @{$prove->{args} || []};
        my $config = {
            test_namespace => 'plugin'.$$.int( rand(1000) ),
            my_cnf => {
                'skip-networking' => '', # no TCP socket
            }
        };
        my $config_file = $args[0];
        unless( $config_file ){
            Test::More::diag( __PACKAGE__." PID $$ config file is not given. Using default config" );
        }else{
            if( ! -e $config_file ){
                confess("Cannot find config file $config_file");
            }else{
                $config = JSON::decode_json( scalar( File::Slurp::read_file( $config_file, { binmode => ':raw' } ) ) );
            }
        }
        $plugin_instance = $class->new( $config );
        ## Just in case.
        unlink( $plugin_instance->_mysqld_file() );
        Test::More::diag( __PACKAGE__." PID $$ plugin instance mysqld lives at ".$plugin_instance->dsn() );
        Test::More::diag( __PACKAGE__." PID $$ plugin instance mysqld descriptor is ".$plugin_instance->_mysqld_file() );
        # This will inform all the other instances to reuse the namespace (see BUILDARGS).
        $ENV{TEST_DB_SHARED_NAMESPACE} = $plugin_instance->test_namespace();
        return 1;
    }
    sub plugin_instance{ return $plugin_instance; }
    sub tear_down_plugin_instance{ $plugin_instance = undef; }

    # For the plugin to 'just work'
    # on unloading this code.
    sub END{
        __PACKAGE__->tear_down_plugin_instance();
    }
}



sub _namespace{
    my ($self) = @_;
    return 'tdbs49C7_'.$self->test_namespace();
}

# Build a temp DB name according to this pid.
# Note it only works because the instance of the DB will run locally.
sub _build__temp_db_name{
    my ($self) = @_;
    return $self->_namespace().( $self + $$ );
}

sub _build__shared_mysqld{
    my ($self) = @_;
    # Two cases here.
    # Either the test mysqld is there and we returned the already built dsn

    # Or it's not there and we need to build it IN A MUTEX way.
    # For a start, let's assume it's not there
    return $self->_monitor(sub{
                               my $saved_mysqld;
                               if( ! -e $self->_mysqld_file() ){
                                   Test::More::note( "PID $$ Creating new Test::mysqld instance" );
                                   $log->info("PID $$ Creating new Test::mysqld instance");
                                   my $mysqld = Test::mysqld->new( %{$self->_testmysqld_args()} ) or confess
                                       $Test::mysqld::errstr;
                                   $log->trace("PID $$ Saving all $mysqld public properties");

                                   $saved_mysqld = {};
                                   foreach my $property ( 'dsn', 'pid' ){
                                       $saved_mysqld->{$property} = $mysqld->$property().''
                                   }
                                   $saved_mysqld->{pid_file} = $mysqld->my_cnf()->{'pid-file'};
                                   # DO NOT LET mysql think it can manage its mysqld PID
                                   $mysqld->pid( undef );

                                   $self->_holds_mysqld( $mysqld );

                                   # Create the pid_registry container.
                                   $log->trace("PID $$ creating pid_registry table in instance");
                                   $self->_with_shared_dbh( $saved_mysqld->{dsn},
                                                            sub{
                                                                my ($dbh) = @_;
                                                                $dbh->do('CREATE TABLE pid_registry(pid INTEGER NOT NULL, instance BIGINT NOT NULL, PRIMARY KEY(pid, instance))');
                                                            });
                                   my $json_mysqld = JSON::encode_json( $saved_mysqld );
                                   $log->trace("PID $$ Saving ".$json_mysqld );
                                   File::Slurp::write_file( $self->_mysqld_file() , {binmode => ':raw'},
                                                            $json_mysqld );
                               } else {
                                   Test::More::note("PID $$ Reusing Test::mysqld from ".$self->_mysqld_file());
                                   $log->info("PID $$ file ".$self->_mysqld_file()." is there. Reusing cluster");
                                   $saved_mysqld = JSON::decode_json(
                                       scalar( File::Slurp::read_file( $self->_mysqld_file() , {binmode => ':raw'} ) )
                                   );
                               }

                               $self->_with_shared_dbh( $saved_mysqld->{dsn},
                                                        sub{
                                                            my $dbh = shift;
                                                            $dbh->do('INSERT INTO pid_registry( pid, instance ) VALUES (?,?)' , {},
                                                                     $self->_instance_pid(), ( $self + $self->_instance_pid() )
                                                                 );
                                                        });
                               return $saved_mysqld;
                           });
}

sub _build_dsn{
    my ($self) = @_;
    if( $$ != $self->_instance_pid() ){
        confess("Do not build the dsn in a subprocess of this instance creator");
    }

    my $dsn = $self->_shared_mysqld()->{dsn};
    return $self->_with_shared_dbh( $dsn, sub{
                                        my $dbh = shift;
                                        my $temp_db_name = $self->_temp_db_name();
                                        $log->info("PID $$ creating temporary database '$temp_db_name' on $dsn");
                                        $dbh->do('CREATE DATABASE '.$temp_db_name);
                                        $dsn =~ s/dbname=([^;])+/dbname=$temp_db_name/;
                                        $log->info("PID $$ local dsn is '$dsn'");
                                        return $dsn;
                                    });
}

sub _teardown{
    my ($self) = @_;
    my $dsn = $self->_shared_mysqld()->{dsn};
    $self->_with_shared_dbh( $dsn,
                             sub{
                                 my $dbh = shift;
                                 $dbh->do('DELETE FROM pid_registry WHERE pid = ? AND instance = ? ',{}, $self->_instance_pid() , ( $self + $self->_instance_pid() ) );
                                 my ( $count_row ) = $dbh->selectrow_array('SELECT COUNT(*) FROM pid_registry');
                                 if( $count_row ){
                                     $log->info("PID $$ Some PIDs,Instances are still registered as using this DB. Not tearing down");
                                     return;
                                 }
                                 $log->info("PID $$ no pids anymore in the DB. Tearing down");
                                 $log->info("PID $$ unlinking ".$self->_mysqld_file());
                                 unlink $self->_mysqld_file();
                                 Test::More::note("PID $$ terminating mysqld instance (sending SIGTERM to ".$self->pid().")");
                                 $log->info("PID $$ terminating mysqld instance (sending SIGTERM to ".$self->pid().")");
                                 kill SIGTERM, $self->pid();
                             });
}

sub DEMOLISH{
    my ($self) = @_;
    if( $$ != $self->_instance_pid() ){
        # Do NOT let subprocesses that forked
        # after the creation of this to have an impact.
        return;
    }

    delete $PROCESS_INSTANCES->{$self.''};


    $self->_monitor(sub{
                        # We always want to drop the local process database.
                        my $dsn = $self->_shared_mysqld()->{dsn};
                        $log->info("PID $$ Will drop database on dsn = $dsn");
                        $self->_with_shared_dbh($dsn, sub{
                                                    my $dbh = shift;
                                                    my $temp_db_name = $self->_temp_db_name();
                                                    $log->info("PID $$ dropping temporary database $temp_db_name");
                                                    $dbh->do("DROP DATABASE ".$temp_db_name);
                                                });
                        $self->_teardown();
                    });

    if( my @other_instances = keys( %{$PROCESS_INSTANCES} ) ){
        # Other instances are still alive (in the same PID). Pass on the test mysqld to them
        # if we have one.
        if( my $test_mysqld = $self->_holds_mysqld() ){
            $log->info("PID $$ instance $self giving mysqld to other living instance ".$other_instances[0]);
            ${$PROCESS_INSTANCES->{$other_instances[0]}}->_holds_mysqld( $self->_holds_mysqld() );
            $self->_holds_mysqld( undef );
        }
    }

    if( my $test_mysqld = $self->_holds_mysqld() ){
        # This is the mysqld holder process. Need to wait for it
        # before exiting
        Test::More::note("PID $$ mysqld holder process waiting for mysqld termination");
        $log->info("PID $$ mysqld holder process waiting for mysqld termination");
        while( waitpid( $self->pid() , 0 ) <= 0 ){
            $log->info("PID $$ db pid = ".$self->pid()." not down yet. Waiting 2 seconds");
            sleep(2);
        }
        my $pid_file = $self->_shared_mysqld()->{pid_file};
        $log->trace("PID $$ unlinking mysql pidfile $pid_file. Just in case");
        unlink( $pid_file );
        $log->info("PID $$ Ok, mysqld is gone");
    }
}

=head1 dsn

Returns the dsn to connect to the test database. Note that the user is root and the password
is the empty string.

=cut

=head2 pid

See L<Test::mysqld>

=cut

sub pid{
    my ($self) = @_;
    return $self->_shared_mysqld()->{pid};
}

my $in_monitor = {};
sub _monitor{
    my ($self, $sub) = @_;

    if( $in_monitor->{$self} ){
        $log->warn("PID $$ Re-entrant monitor. Will execute sub without locking for deadlock protection");
        return $sub->();
    }
    $log->trace("PID $$ locking file ".$self->_lock_file());
    $in_monitor->{$self} = 1;
    my $lock = File::Flock::Tiny->lock( $self->_lock_file() );
    my $res = eval{ $sub->(); };
    my $err = $@;
    delete $in_monitor->{$self};
    $lock->release();
    if( $err ){
        confess($err);
    }
    return $res;
}

sub _with_shared_dbh{
    my ($self, $dsn, $code) = @_;
    my $dbh = DBI->connect_cached( $dsn, 'root', '' , { RaiseError => 1 });
    return $code->($dbh);
}

__PACKAGE__->meta->make_immutable();
