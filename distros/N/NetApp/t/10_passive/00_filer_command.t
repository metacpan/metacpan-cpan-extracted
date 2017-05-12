#!/usr/bin/env perl -w

use strict;
use warnings;

use lib 'blib/lib';
use lib 't/lib';
use NetApp::Test;

BEGIN {
    if ( not @NetApp::Test::filer_args ) {
        print "1..0 # Skip: No test filers defined\n";
        exit 0;
    }
}

use Test::More qw( no_plan );
use Test::Exception;
use Data::Dumper;

use NetApp::Filer;

my @filer_args		= @NetApp::Test::filer_args;

my ($ssh_filer)		= grep { $_->{protocol} eq 'ssh' } @filer_args;
my $ssh_command		= $ssh_filer->{ssh_command};
my $ssh_identity	= $ssh_filer->{ssh_identity};
my $hostname		= $ssh_filer->{hostname};
my $ssh_string_want	= join(' ',@$ssh_command,
                               "-i $ssh_identity -l root $hostname");

my ($telnet_filer)	= grep { $_->{protocol} eq 'telnet' } @filer_args;

throws_ok {
    my $filer		= NetApp::Filer->new({});
} qr{Mandatory parameter 'hostname' missing in call to NetApp::Filer::BUILD.*},
    qq{NetApp::Filer->new requires hostname};

throws_ok {
    my $filer		= NetApp::Filer->new({
        hostname	=> 'some_random_hostname',
        ssh_identity	=> '/no/such/file',
    });
} qr{No such ssh_identity file: /no/such/file},
    qq{NetApp::Filer->new requires valid ssh_identity file};

my $filer		= NetApp::Filer->new( $ssh_filer );
isa_ok( $filer, 'NetApp::Filer' );

ok( ref $filer->_get_ssh_command eq "ARRAY",
    'return type of _get_ssh_command');

my $ssh_string_have	= join(' ',@{ $filer->_get_ssh_command });
ok( $ssh_string_have eq $ssh_string_want,
    "return value of _get_ssh_command: $ssh_string_have" );

ok( $filer->_run_command( command => [qw(version)] ),
    'calling _run_command');
ok( $filer->_get_command_status,	'true status');

my @stderr	= $filer->_get_command_stderr;
my @stdout	= $filer->_get_command_stdout;

ok( scalar @stderr == 0,		'no stderr');
ok( $filer->_get_command_error == 0,	'no error');
ok( scalar @stdout == 1,		'one line in stdout');

my $status	= $filer->_run_command(
    command	=> [qw(nosuch command)],
    nonfatal	=> 1,
);

ok( $status,	'calling run_command again');
# Hmm...  The status is still true
# ok( $filer->_get_command_status == 0,	'failed status' );
ok( scalar $filer->_get_command_stdout == 0, 'no stdout');
ok( scalar $filer->_get_command_stderr == 1, 'one line in stderr');
ok( ( $filer->_get_command_stderr )[0] eq
        "nosuch not found.  Type '?' for a list of commands",
    'nosuch command error message');

#
# This is failing with a bizarre error:
#   Failed test 'Fatal _run_command throws exception by default'
#   at t/00_filer_command.t line 76.
# expecting: Regexp ((?-xism:Error running 'nosuch command' on))
# found: panic: attempt to copy freed scalar a1c7d20 to 9fd7238 at /efs/dist/perl5/core/5.10.0-ml01/.exec/x86-32.linux.2.4/lib/perl5/Carp/Heavy.pm line 104.
#
# There appear to be major problems with perl5.8 and Test::Exception
# on Solaris 8, too.
#
# throws_ok {
#     $filer->_run_command( command => [qw(nosuch command)] );
# } qr{Error running 'nosuch command' on},
#     qq{Fatal _run_command throws exception by default};

eval {
    $filer->_run_command( command => [qw(nosuch command)] );
};
ok( $@ =~ qr{Error running 'nosuch command' via ssh on},
    qq{Fatal _run_command throws exception by default} );
    
# Telnet tests

if ( not ref $telnet_filer ) {
    print "# Skipping tests of telnet access.  Not configured\n";
    exit 0;
}

$filer			= NetApp::Filer->new( $telnet_filer );
isa_ok( $filer,		'NetApp::Filer' );

ok( $filer->_run_command( command => [qw( version )] ),
    'calling _run_command' );
ok( $filer->_get_command_status,
    'true status' );
@stderr		= $filer->_get_command_stderr;
@stdout		= $filer->_get_command_stdout;
ok( scalar @stderr == 0,	'no stderr');
ok( scalar @stdout == 1,	'one line in stdout' );

# NOTE: The error checking tests, based on calling "nosuch command"
# can NOT be made to work with Net::Telnet, because there is no
# generic error handling available via telnet, only ssh.
