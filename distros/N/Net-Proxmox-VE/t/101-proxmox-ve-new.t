#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use IO::Socket::SSL qw(SSL_VERIFY_NONE);

my $tests = 17;    # used later
use Test::Trap;
if ( not $ENV{PROXMOX_TEST_URI} ) {
    my $msg =
'This test sucks.  Set $ENV{PROXMOX_TEST_URI} to a real running proxmox to run.';
    plan( skip_all => $msg );
}
else {
    plan tests => $tests;
}

require_ok('Net::Proxmox::VE')
  or die "# Net::Proxmox::VE not available\n";

my $obj;

=head2 new() dies with bad values

Test that new() dies when bad values are provided

=cut

trap { $obj = Net::Proxmox::VE->new() };
ok( $trap->die, 'no arguments dies' );

=head2 new() works with good values

This relies on a $ENV{PROXMOX_TEST_URI}.

Try something like...

   PROXMOX_TEST_URI="user:password@192.0.2.28:8006/pam" prove ...

=cut

{

    my ( $user, $pass, $host, $port, $realm ) =
      $ENV{PROXMOX_TEST_URI} =~ m{^(\w+):(\w+)\@([\w\.]+):(\d+)/(\w+)$}
      or BAIL_OUT
      q|PROXMOX_TEST_URI didnt match form 'user:pass@hostname:port/realm'|
      . "\n";

    trap {
        $obj = Net::Proxmox::VE->new(
            host     => $host,
            password => $pass,
            user     => $user,
            port     => $port,
            realm    => $realm,
            ssl_opts => {
                SSL_verify_mode => SSL_VERIFY_NONE,
                verify_hostname => 0
            },

        )
    };
    ok( !$trap->die, 'doesnt die with good arguments' );

}

=head2 login() connects to the server

After the object is created, we should be able to log in ok

=cut

ok( $obj->login(), 'logged in to ' . $ENV{PROXMOX_TEST_URI} );

=head2 Check server version

Manually check that the remote version is 2 or greater (also checks we can get the version)

Then use the helper function

=cut

cmp_ok( $obj->api_version, '>=', 2, 'manually: check remote version is 2+' );
ok( $obj->api_version_check, 'helper: check remote version is 2+' );

=head2 check the login ticket

=cut

ok( $obj->check_login_ticket, 'login ticket should still be valid' );

=head2 check debug toggling

=cut

ok( !$obj->debug(),  'debug off by default' );
ok( $obj->debug(1),  'debug toggled on and returns true' );
ok( $obj->debug(),   'debug now turned on' );
ok( !$obj->debug(0), 'debug toggled off and returns false' );
ok( !$obj->debug(),  'debug now turned off' );

=head2 cluster nodes

=cut

my $foo = $obj->nodes;

=head2 clear login ticket

checks that the login ticket clears, also checks that the login ticket is now invalid

=cut

ok( $obj->clear_login_ticket,  'clears the login ticket' );
ok( !$obj->clear_login_ticket, 'clearing doesnt clear any more' );
ok( !$obj->check_login_ticket, 'login ticket is now invalid' );

=head2 user access

checks users access stuff

=cut

{

    my @index = $obj->access();
    is_deeply(
        \@index,
        [
            map { { subdir => $_ } }
              qw(users groups roles acl domains ticket password)
        ],
        'correct top level directories'
    );

    @index = $obj->access_domains();
    ok( scalar @index == 2, 'two access domains' );

}

__END__
           %args = (
               host     => 'proxmox.local.domain',
               password => 'barpassword',
               user     => 'root', # optional
               port     => 8006,   # optional
               realm    => 'pam',  # optional
           );

