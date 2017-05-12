#!/usr/bin/perl -w

use Aw 'SOAP@active.dev.erols.net:7449';
require Aw::Client;
require Aw::Event;


my $client = newEZ Aw::Client ( "devkitClient" );

my $event = new Aw::Event (
	$client,
	"AdapterDevKit::calcRequest", 
 );


my @Numbers = ( 1 );

$event->setField ( numbers => \@Numbers );
print "  publish Error!\n" if ( $client->publish ( $event ) );
print "Sum(1)    = ", $client->getEvent( AW_INFINITE )->getIntegerField ( "result" ), "\n";

push ( @Numbers, 2 );
$event->setField ( numbers => \@Numbers );
print "  publish Error!\n" if ( $client->publish ( $event ) );
print "Sum(1..2) = ", $client->getEvent( AW_INFINITE )->getIntegerField ( 'result' ), "\n";

push ( @Numbers, 3 );
$event->setField ( numbers => \@Numbers );
print "  publish Error!\n" if ( $client->publish ( $event ) );
print "Sum(1..3) = ", $client->getEvent( AW_INFINITE )->getIntegerField ( 'result' ), "\n";

push ( @Numbers, 4 );
$event->setField ( numbers => \@Numbers );
print "  publish Error!\n" if ( $client->publish ( $event ) );
print "Sum(1..4) = ", $client->getEvent( AW_INFINITE )->getIntegerField ( 'result' ), "\n";


__END__


=head1 DESCRIPTION

This script is part of the SOAP::Transport::ACTIVEWORKS testing suite.

This script creates an ActiveWorks client and publishes an
'AdapterDevKit::calcRequest' event directly to an ActiveWorks broker.
The companion 'calc-adapter.pl' script is the intended recipient adapter.

B<No> SOAP components are employed.
