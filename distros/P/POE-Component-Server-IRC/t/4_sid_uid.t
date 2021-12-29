package Poco::Server::IRC::UID;

use strict;
use warnings;
use base qw[POE::Component::Server::IRC];

sub spawn {
    my ($package, %args) = @_;
    $args{lc $_} = delete $args{$_} for keys %args;
    my $config = delete $args{config};
    my $self = bless {}, $package;
    $self->configure($config ? $config : ());
    $self->_state_create();
    return $self;
}

package main;

use strict;
use warnings;
use Test::More qw[no_plan];

my $ircd = Poco::Server::IRC::UID->spawn();

isa_ok($ircd,'POE::Component::Server::IRC');

my $sid = $ircd->server_sid();
like( $sid, qr/^[0-9][A-Z0-9][A-Z0-9]$/, "SID: $sid is valid" );

my $count = 0;
my %uids;
while ( $count <= 9999 ) {
  my $uid = $ircd->_state_gen_uid();
  $ircd->{state}{uids}{$uid} = 'bogus';
  like( $uid, qr/^[0-9][A-Z0-9][A-Z0-9][A-Z][A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9]$/, "UID: $uid is valid" );
  like( $uid, qr!^$sid!, "UID: $uid belongs to $sid");
  $count++;
}
is( scalar keys %{ $ircd->{state}{uids} }, 10000, 'Should be 10000 UIDs' );
