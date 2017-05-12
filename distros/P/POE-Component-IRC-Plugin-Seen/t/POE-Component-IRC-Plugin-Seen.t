use v5.14;
use strict;
use warnings;

use Test::More tests => 10;
use Test::MockObject;

BEGIN { *CORE::GLOBAL::localtime = sub { 'now' } }

BEGIN { use_ok('POE::Component::IRC::Plugin::Seen') };

# Variable setup
my $last_msg;

my $mockirc = Test::MockObject->new;
$mockirc->mock(yield => sub { $last_msg = $_[3] if $_[1] eq 'privmsg'})->set_always(nick_name => 'bot');

my $self = POE::Component::IRC::Plugin::Seen->new;
my $channels = [ '#chan' ];
my $rmgv = \'mgv!marius@ieval.ro';

# Sub setup
sub runtest{
	my ($message, $expect, $comment, $privmsg) = @_;
	undef $last_msg;
	$self->S_public($mockirc, $rmgv, \$channels, \$message) unless $privmsg;
	$self->S_msg($mockirc, $rmgv, \$channels, \$message) if $privmsg;
	is($last_msg, $expect, $comment)
}

runtest 'something', undef, 'initialize';
runtest 'seen mgv', 'I last saw mgv now on #chan saying something', 'public';

$self->S_ctcp_action($mockirc, $rmgv, \$channels, \'sleeping');
runtest '!seen mgv', 'I last saw mgv now on #chan doing: * sleeping', 'ctcp_action';

$self->S_join($mockirc, $rmgv, \'#chan');
runtest 'bot: seen mgv', 'I last saw mgv now joining #chan', 'join';

$self->S_part($mockirc, $rmgv, \'#chan', \'');
runtest 'bot: !seen mgv', 'I last saw mgv now parting #chan', 'part without message';

$self->S_part($mockirc, $rmgv, \'#chan', \'buh-bye');
runtest 'bot: seen mgv', "I last saw mgv now parting #chan with message 'buh-bye'", 'part with message';

runtest 'bot: seen asd', "I haven't seen asd", "haven't seen";

# Private messages
runtest 'seen asd', "I haven't seen asd", "haven't seen", 1;
runtest ' !seen asd', "I haven't seen asd", "haven't seen", 1;
