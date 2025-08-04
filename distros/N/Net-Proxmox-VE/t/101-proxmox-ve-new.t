#!/usr/bin/env perl

use strict;
use warnings;
use v5.10;

use Test::More import =>
  [qw( BAIL_OUT cmp_ok note ok plan require_ok subtest )];
use IO::Socket::SSL qw( SSL_VERIFY_NONE );
use Test::Trap;

if (   not $ENV{PROXMOX_USERPASS_TEST_URI}
    or not $ENV{PROXMOX_APITOKEN_TEST_URI} )
{
    my $msg =
'Set $ENV{PROXMOX_USERPASS_TEST_URI} and $ENV{PROXMOX_APITOKEN_TEST_URI} to a real running proxmox to run.';
    plan( skip_all => $msg );
}
else {
    plan tests => 4;
}

require_ok('Net::Proxmox::VE')
  or die "# Net::Proxmox::VE not available\n";

=head1 ENVIRONMENT

Some quick notes on testing ->new() against a live server.

This relies on a $ENV{PROXMOX_USERPASS_TEST_URI}.

Try something like...

 PROXMOX_USERPASS_TEST_URI="user:password@192.0.2.28:8006/pam" prove ...

=head1 PARAMETER TESTING

=cut

subtest 'Parameter Testing' => sub {
    plan tests => 7;

    my $obj;

=head2 new() dies with bad values

Test that new() dies when bad values are provided

=cut

    trap { $obj = Net::Proxmox::VE->new() };
    ok( $trap->die, 'no arguments dies' );

    trap {
        $obj = Net::Proxmox::VE->new(
            host     => 'x',
            password => 'x',
            user     => 'x',
        )
    };
    ok( $trap->die, 'unknown argument dies' );
    trap {
        $obj = Net::Proxmox::VE->new( password => 'x', )
    };
    ok( $trap->die, 'missing host argument dies' );
    trap {
        $obj = Net::Proxmox::VE->new( host => 'x', )
    };
    ok( $trap->die, 'missing password argument dies' );
    trap {
        $obj = Net::Proxmox::VE->new( tokenid => 'x', )
    };
    ok( $trap->die, 'dies with tokenid only' );
    trap {
        $obj = Net::Proxmox::VE->new( secret => 'x', )
    };
    ok( $trap->die, 'dies with secret only' );
    trap {
        $obj = Net::Proxmox::VE->new(
            secret   => 'x',
            tokenid  => 'x',
            password => 'x'
        )
    };
    ok( $trap->die, 'dies with secret, tokenid, and password' );

};

=head1 USER/PASSWORD TESTING

Tests various actions with User/Password Authentication.

See L<METHOD TESTING SEQUENCE>


=cut

subtest 'User/Password Testing' => sub {

    plan tests => 17;

    my ( $user, $pass, $host, $port, $realm ) =
      $ENV{PROXMOX_USERPASS_TEST_URI} =~
      m{^(\w+):(\w+)\@([\w\.]+):([0-9]+)/(\w+)$}
      or BAIL_OUT
q|PROXMOX_USERPASS_TEST_URI didnt match form 'user:pass@hostname:port/realm'|
      . "\n";

    test_all_the_things(
        {
            host     => $host,
            password => $pass,
            port     => $port,
            realm    => $realm,
            ssl_opts => {
                SSL_verify_mode => SSL_VERIFY_NONE,
                verify_hostname => 0
            },
            username => $user,
        }
    );

};

=head1 API TOKEN TESTING

Tests various actions with API Token Authentication.

See L<METHOD TESTING SEQUENCE>


=cut

subtest 'API Token Testing' => sub {

    plan tests => 15;

    my ( $user, $tokenid, $secret, $host, $port, $realm ) =
      $ENV{PROXMOX_APITOKEN_TEST_URI} =~
      m{^(\w+):(\w+)=([A-z0-9\-]+)\@([\w\.]+):([0-9]+)/(\w+)$}
      or BAIL_OUT
q|PROXMOX_APITOKEN_TEST_URI didnt match form 'user:tokenid=secret@hostname:port/realm'|
      . "\n";

    test_all_the_things(
        {
            host     => $host,
            port     => $port,
            realm    => $realm,
            secret   => $secret,
            ssl_opts => {
                SSL_verify_mode => SSL_VERIFY_NONE,
                verify_hostname => 0
            },
            tokenid  => $tokenid,
            username => $user,
        }
    );

};

=head1 METHOD TESTING SEQUENCE

Used with testing for both Auth methods

=cut

sub test_all_the_things {

    my $args = shift;
    my $obj;

=head2 new() works with good values

Tests new() works correctly with User/Password values

=cut

    trap {
        $obj = Net::Proxmox::VE->new(%$args)
    };
    ok( !$trap->die, 'doesnt die with good arguments' );

=head2 login() connects to the server

After the object is created, we should be able to log in ok

=cut

    ok( $obj->login(), 'logged in to server' );

=head2 Check server version

Manually check that the remote version is 2 or greater (also checks we can get the version)

Then use the helper function

=cut

    cmp_ok( $obj->api_version->{release},
        '>=', 2, 'manually: check remote version is 2+' );
    ok( $obj->api_version_check, 'helper: check remote version is 2+' );
    note( 'API Version Observed: ' . $obj->api_version->{release} // 'null' );

=head2 check the login ticket

=cut

    ok( $obj->check_login_ticket, 'login ticket still be valid' );

=head2 check debug toggling

=cut

    ok( !$obj->debug(),  'debug off by default' );
    ok( $obj->debug(1),  'debug toggled on and returns true' );
    ok( $obj->debug(),   'debug now turned on' );
    ok( !$obj->debug(0), 'debug toggled off and returns false' );
    ok( !$obj->debug(),  'debug now turned off' );
    $obj = Net::Proxmox::VE->new( %$args, debug => 1, );
    ok( $obj->debug(), 'debug parameter to new propagates correctly' );
    $obj->debug(0);

=head2 cluster nodes

=cut

    my @nodes = $obj->nodes();
    ok( scalar @nodes >= 1, 'at least one node observed' );

=head2 clear login ticket

checks that the login ticket clears, also checks that the login ticket is now invalid

Doesn't have any effect with API Token

=cut

    ok( $obj->clear_login_ticket, 'clears the login ticket' )
      unless $obj->{pveapitoken};    # not relevant for API Token
    ok( !$obj->clear_login_ticket, 'clearing doesnt clear any more' );
    ok( !$obj->check_login_ticket, 'login ticket is now invalid' )
      unless $obj->{pveapitoken};    # not relevant for API Token

=head2 user access

checks users access stuff

=cut

    {

        my @index = $obj->access();
        ok( scalar @index, 'access top level directories' );

        @index = $obj->access_domains();
        ok( scalar @index >= 2, 'access domains' );

    }

}    # sub test_all_the_things

1;

__END__

