
use strict;
use warnings;
use Test::More;
#use IO::Scalar;
my $IO_Scalar_OK=use_ok('IO::Scalar');

STDERR->autoflush(1);
STDOUT->autoflush(1);

use_ok('Net::SolarWinds::Log');

# this object all ready extends known good objects so our constructor tests are minimal
{
    my $log = new Net::SolarWinds::Log( 'hostname', 'testing' );

    cmp_ok( $log->{hostname}, 'eq', 'testing', 'make sure constructor overloading works!' );
}

SKIP: {
    skip 'IO::Scalar is not installed', 50 unless $IO_Scalar_OK;
    my $log = new Net::SolarWinds::Log();

    ok( $log->{hostname}, 'should have a hostname value' );
    my $data = '';

    # muck with the internals so we don't need a local file
    $log->{fh} = IO::Scalar->new( \$data );

    # these functions are copy paste so if one works they all work
    can_ok( $log, qw(log_info log_error log_debug log_warn) );

    $log->log_error("This should exist in some file!");
    like( $data, qr/main::/, 'called in the main package outside of a function' );

    false_hope( $log, 'log_error', "this is a test" );
    like( $data, qr/main::false_hope/, 'called in main::false_hope' );

    &voidwalker::false_hope( $log, 'log_error', "this is another test" );
    like( $data, qr/main::false_hope/, 'called in voidwalker::false_hope' );

    &voidwalker::eval_hope( $log, 'log_error', "this is another test" );
    like( $data, qr/main::false_hope/, 'called in voidwalker::eval_hope' );

    # handy dandy garbage for people to see!
    #diag $data;

    # reset out test buffer
    $data = '';

    # muck with internals
    $log->set_loglevel( $log->LOG_NONE );
    cmp_ok( $log->get_loglevel, '==', $log->LOG_NONE, 'get and set loglevel check' );

    &voidwalker::eval_hope( $log, 'log_error', "this is another test" );
    ok( !$data, "should have no logs now!" );

    # call it cart before the horse.. but we need to actually test logging in our base class!
    $data = '';

    # cart before the hourse style testing I guess..
    my $base = new Net::SolarWinds::ConstructorHash( log => $log );
    isa_ok( $base, 'Net::SolarWinds::ConstructorHash' );

    is_deeply( $log, $base->get_log, 'should get our logging object back' );

    my $self = new cabbage( log => $log );

    isa_ok( $self, 'cabbage', 'should look like smell like and taste like cabbage' );

    $self->get_log->set_loglevel( $log->LOG_DEBUG );

    cmp_ok( $log->get_loglevel, '==', $log->LOG_DEBUG, 'make sure the log level jumped to debug' );

    # make sure we get the right package and anonymous sub, and level info
    sub { $self->log_info("I am talking trash!") }
      ->();

    #diag $data;

    like $data, qr/INFO main::__ANON__/m, 'make sure we logged info';

    # make sure each log method works
    foreach my $level (qw(error warn info debug always)) {
        $data = '';
        my ( $method, $type ) = ( "cabbage::check_${level}", uc($level) );
        $self->$method;
        like $data, qr/$type $method/m, "make sure we logged a $type";

        #diag $data;
    }

    for ( my $current = $log->LOG_DEBUG ; $current > -1 ; --$current ) {

        $log->set_loglevel($current);

        foreach my $level (qw(error warn info debug always)) {

            # reset our log file
            $data = '';

            my ( $method, $type ) = ( "log_${level}", uc($level) );
            my $constant = "LOG_${type}";

            sub { $log->$method }
              ->();

            #diag "Testing level check for $constant or $current\n", $data;

            if ( $current >= $log->$constant ) {
                like $data, qr/$type main::__ANON__/m, "make sure we logged a $type level: $current >= " . $log->$constant;

            } else {

                ok( $data eq '', "making sure we didn't" . " log $type when log level is $current >= " . $log->$constant );
            }

        }
    }

    # make sure each log level works as expected for
    # our lazy man methods

    for ( my $current = $log->LOG_DEBUG ; $current > -1 ; --$current ) {

        $log->set_loglevel($current);

        foreach my $level (qw(error warn info debug always)) {

            # reset our log file
            $data = '';

            my ( $method, $type ) = ( "cabbage::check_${level}", uc($level) );
            my $constant = "LOG_${type}";

            $self->$method;

            #diag "Testing level check for $constant or $current\n", $data;

            if ( $current >= $log->$constant ) {
                like $data, qr/$type $method/m, "make sure we logged a $type level: $current >= " . $log->$constant;

            } else {

                ok( $data eq '', "making sure we didn't" . " log $type when log level is $current >= " . $log->$constant );
            }

        }
    }

    # lazy man testing with an additional header!
    # and yes its more cart before the horse type stuffs!
    {
        my $self = new notcabbage( log => $log );
        for ( my $current = $log->LOG_DEBUG ; $current > -1 ; --$current ) {

            $log->set_loglevel($current);

            foreach my $level (qw(error warn info debug always)) {

                # reset our log file
                $data = '';

                my ( $method, $type ) = ( "cabbage::check_${level}", uc($level) );
                my $constant = "LOG_${type}";

                $self->$method;

                #diag "Testing level check for $constant or $current\n", $data;

                if ( $current >= $log->$constant ) {
                    like $data, qr/$type $method/m,   "make sure we logged a $type level: $current >= " . $log->$constant;
                    like $data, qr/No Cabbage here!/, 'Valid header check';

                } else {

                    ok( $data eq '', "making sure we didn't" . " log $type when log level is $current >= " . $log->$constant );
                }

            }
        }
    }

    # overload checks

    is_deeply( $log, $log->get_log, 'make sure logging object is returned correctly!' );

}
{

    # new constructor option test
    my $log = new Net::SolarWinds::Log( filename => 'test.txt' );
    isa_ok( $log, 'Net::SolarWinds::Log' );

    cmp_ok( $log->generate_filename, 'eq', 'test.txt', 'filename fetch' );

}

{

    # new constructor argument layout test
    my $log = new Net::SolarWinds::Log('test.txt');
    isa_ok( $log, 'Net::SolarWinds::Log' );

    cmp_ok( $log->generate_filename, 'eq', 'test.txt', 'filename fetch' );

}
SKIP: {
  skip 'IO::Scalar not found', 1 unless $IO_Scalar_OK;
  my $string="";
  my $fh=new IO::Scalar(\$string);
  my $log=new Net::SolarWinds::Log(fh=>$fh);
  sub {eval { $log->log_die("some message") }}->();
  ok($@,"Should be fatal to log_die ");
}

## below are packages and subs created just for testing.

{

    package cabbage;

    use base qw(Net::SolarWinds::ConstructorHash);

    sub check_info {
        my ($self) = @_;

        $self->log_info("this is a test")

    }

    sub check_error {
        my ($self) = @_;

        $self->log_error("this is a test")

    }

    sub check_warn {
        my ($self) = @_;

        $self->log_warn("this is a test")

    }

    sub check_debug {
        my ($self) = @_;

        $self->log_debug("this is a test")

    }

    sub check_always {
        my ($self) = @_;

        $self->log_always("this is a test");
    }

    sub check_depth_error {
        my ($self) = @_;
        $self->check_error("this is another test");
    }

    sub check_anon_error {
        my ($self) = @_;

        sub { $self->log_error("Some message") }
          ->();
    }
    1;
}

# subclass cabbage but add a header
{

    package notcabbage;
    use base qw(cabbage);

    use constant log_header => 'No Cabbage here!';

}
{

    package voidwalker;

    sub false_hope {
        my ( $log, $method, @data ) = @_;

        $log->$method(@data);

    }

    sub eval_hope {
        my ( $log, $method, @data ) = @_;
        eval { $log->$method(@data) };
    }

    1;
}

sub false_hope {
    my ( $log, $method, @data ) = @_;

    $log->$method(@data);

}

done_testing;
