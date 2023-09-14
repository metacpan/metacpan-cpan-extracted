#!/usr/bin/env perl

use strict;
use warnings;

use Test::More; my $tests = 5; # used later
use Test::Trap;
use IO::Socket::SSL qw(SSL_VERIFY_NONE);

if ( not $ENV{PROXMOX_TEST_URI} ) {
    my $msg = 'This test sucks.  Set $ENV{PROXMOX_TEST_URI} to a real running proxmox to run.';
    plan( skip_all => $msg );
} else {
    plan tests => $tests
}

require_ok('Net::Proxmox::VE')
    or die "# Net::Proxmox::VE not available\n";

my $obj;

=head2 new() works with good values

This relies on a $ENV{PROXMOX_TEST_URI}.

Try something like...

   PROXMOX_TEST_URI="user:password@192.0.2.28:8006/pam" prove ...

=cut

{

   my ($user, $pass, $host, $port, $realm) =
       $ENV{PROXMOX_TEST_URI} =~ m{^(\w+):(\w+)\@([\w\.]+):(\d+)/(\w+)$}
       or die q|PROXMOX_TEST_URI didnt match form 'user:pass@hostname:port/realm'|."\n";

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
   ok (! $trap->die, 'doesnt die with good arguments');

}

=head2 login() connects to the server

After the object is created, we should be able to log in ok

=cut

ok($obj->login(), 'logged in to ' . $ENV{PROXMOX_TEST_URI});

=head2 user access

checks users access stuff

=cut

{

  my @index = $obj->access();
  is_deeply(\@index,[map {{ subdir => $_ }} qw(users groups roles acl domains ticket password)], 'correct top level directories');

  @index = $obj->access_domains();
  ok(scalar @index == 2, 'two access domains');

}
