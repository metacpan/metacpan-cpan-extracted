#!/usr/bin/perl

package OTTest;

use strict;
use warnings;
use POE qw( Component::Client::opentick::OTClient );
use base qw( POE::Component::Client::opentick::OTClient );
use Data::Dumper;
$|=1;

sub onLogin {
    my( $self, @args ) = @_;
    print "Logged in.\n";
    my $req_id = $self->requestTickSnapshot( 'Q' => 'MSFT' );
    print "ReqID = $req_id\n";
}

sub onRealtimeTrade
{
    my( $self, $req_id, $cmd_id, $record ) = @_;
    print "Data: ", join( ' ', $record->get_data() ), "\n";
}

sub onMessage
{
    my( $self, @args ) = @_;
#    print Dumper \@args;
    print "Logging out...\n";
    $self->logout();
}

sub onError {
    my( $self, $req_id, $cmd_id, $error ) = @_;
    print "ERROR: $error\n";
}

sub startup {
    my( $self ) = @_;
    print "Connecting to opentick server...\n";
    $self->login();
}

package main;

use strict;
use POE qw( Component::Client::opentick::OTClient );

my $user = 'YourUser';
my $pass = 'YourPass';

my $opentick = OTTest->new( $user, $pass );

$poe_kernel->run();
exit(0);

__END__

