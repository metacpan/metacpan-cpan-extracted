use strictures 2;
use Test2::V0 -no_srand => 1;
use JSON ();
use lib 't/lib';
use TestFixtures qw(client_connection make_signed_event);

my ($client, $connection) = client_connection();
my (@received, @warnings);
$client->on(eose => sub { push @received, [@_] });
local $SIG{__WARN__} = sub { push @warnings, @_ };
for my $hints (undef, [], ['finish'], ['more'], ['auth','finish'], ['future','more']) {
    my @wire = ('EOSE', 'subscription');
    push @wire, $hints if defined $hints;
    $connection->receive(JSON::encode_json(\@wire));
    is shift(@received), ['subscription', $hints], 'EOSE callback preserves hints and first argument';
}
is \@warnings, [], 'unknown hints produce no warnings';
my @events;
$client->on(event => sub { push @events, $_[1]->id });
my $event = make_signed_event();
$connection->receive(JSON::encode_json(['EVENT', 'subscription', $event->to_hash]));
is \@events, [$event->id], 'live delivery continues after finish';
done_testing;
