# common routines for testing Net::LDAP::SimpleServer

use strict;
use warnings;
use Exporter 'import';
our @EXPORT_OK   = qw(ldap_client test_requests server_ok server_nok);
our %EXPORT_TAGS = (
    LDIFSTORE => [
        qw(
          ldifstore_check_param
          ldifstore_check_param_success
          ldifstore_check_param_failure
          )
    ],
    PARAMS => [qw(server_ok server_nok)],
    CLIENT => [qw/ldap_client test_requests/],
);

use Carp;
use Proc::Fork;
use IO::Pipe;
use Try::Tiny;
use Test::More;

use Net::LDAP;
use Net::LDAP::SimpleServer;

##############################################################################
# LDIFSTORE

sub ldifstore_check_param {
    eval { my $o = Net::LDAP::SimpleServer::LDIFStore->new(@_); };
    return $@;
}

sub ldifstore_check_param_success {
    ok( not ldifstore_check_param(@_) );
}

sub ldifstore_check_param_failure {
    ok( ldifstore_check_param(@_) );
}

##############################################################################

my $default_test_port   = 30389;
my $default_start_delay = 5;
my $default_end_signal  = 3;

my $test_fixed_opts = {
    log_file => '/tmp/ldapserver.log',
    port     => $default_test_port,
    host     => 'localhost',
};

my $OK  = 'OK';
my $NOK = 'NOK ';

sub _eval_params {
    my $p      = shift;
    my $result = undef;

    our $pipe = IO::Pipe->new;

    run_fork {
        parent {
            # parent code
            $pipe->reader;
            $result = <$pipe>;
        }
        child {
            $pipe->writer;

            my $quit = sub { print $pipe shift; exit; };

            alarm 0;
            local $SIG{ALRM} = sub { $quit->($OK) };
            alarm $default_start_delay;

            try {
                Net::LDAP::SimpleServer->new($test_fixed_opts)->run($p);
            }
            catch {
                $quit->( $NOK . '[' . $@ . ']' );
            }
        }
    };
    return $result;
}

sub server_nok {
    my ( $params, $test_name ) = @_;
    my $res = _eval_params($params);

    isnt( $res, $OK, $test_name )
      || diag( $res . ': params=' . explain($params) );
}

sub server_ok {
    my ( $params, $test_name ) = @_;
    my $res = _eval_params($params);

    is( $res, $OK, $test_name )
      || diag( $res . ': params=' . explain($params) );
}

sub ldap_client {
    return Net::LDAP->new( 'localhost', port => $default_test_port );
}

sub test_requests {
    my $opts = ref $_[0] eq 'HASH' ? $_[0] : {@_};

    my $requests_sub = $opts->{requests_sub}
      || croak "Must pass 'requests_sub'";
    my $server_opts = $opts->{server_opts} || croak "Must pass 'server_opts'";
    my $start_delay = $opts->{start_delay} || $default_start_delay;
    my $end_signal  = $opts->{end_signal}  || $default_end_signal;

    run_fork {
        parent {
            # client side
            my $child = shift;

            try {
                sleep $start_delay;
                $requests_sub->();
            }
            finally {
                kill $end_signal, $child;
            }
        }
        child {
            # server side
            Net::LDAP::SimpleServer->new($test_fixed_opts)->run($server_opts);
        }
    };
}
