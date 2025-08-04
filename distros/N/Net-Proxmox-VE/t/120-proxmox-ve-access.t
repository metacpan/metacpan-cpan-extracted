#!/usr/bin/env perl

use strict;
use warnings;

use Test::More import => [ qw( is_deeply note ok plan require_ok ) ];
use Test::Trap;
use IO::Socket::SSL qw( SSL_VERIFY_NONE );

if ( not $ENV{PROXMOX_USERPASS_TEST_URI} ) {
    my $msg =
'This test sucks.  Set $ENV{PROXMOX_USERPASS_TEST_URI} to a real running proxmox to run.';
    plan( skip_all => $msg );
}
else {
    plan tests => 5;
}

require_ok('Net::Proxmox::VE')
  or die "# Net::Proxmox::VE not available\n";

my $obj;

=head2 new() works with good values

This relies on a $ENV{PROXMOX_USERPASS_TEST_URI}.

Try something like...

   PROXMOX_USERPASS_TEST_URI="user:password@192.0.2.28:8006/pam" prove ...

=cut

{

    my ( $user, $pass, $host, $port, $realm ) =
      $ENV{PROXMOX_USERPASS_TEST_URI} =~ m{^(\w+):(\w+)\@([\w\.]+):(\d+)/(\w+)$}
      or die
q|PROXMOX_USERPASS_TEST_URI didnt match form 'user:pass@hostname:port/realm'|
      . "\n";

    trap {
        $obj = Net::Proxmox::VE->new(
            host     => $host,
            password => $pass,
            username => $user,
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

ok( $obj->login(), 'logged in to ' . $ENV{PROXMOX_USERPASS_TEST_URI} );

=head2 user access

checks users access stuff

=cut

{

    my @index = $obj->access();
    is_deeply(
        \@index,
        [
            map { { subdir => $_ } }
              qw(users groups roles acl domains openid tfa ticket password)
        ],
        'correct top level directories'
    );
    note( 'Directories observed: ' . join(', ', map { $_->{subdir} } @index) );

    @index = $obj->access_domains();
    ok( scalar @index == 2, 'two access domains' );

}
