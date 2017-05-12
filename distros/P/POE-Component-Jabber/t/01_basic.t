#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 29;
use POE;

BEGIN 
{ 
	use_ok('POE::Component::Jabber');
	use_ok('POE::Component::Jabber::Events');
	use_ok('POE::Component::Jabber::ProtocolFactory');
}

sub test_new_pcj_fail
{
	my ($name, @args) = @_;
	eval { POE::Component::Jabber->new(@args); };
	ok($@ ne '', $name);
}

sub test_new_pcj_succeed
{
	my ($name, @args) = @_;
	eval { POE::Component::Jabber->new(@args); };
	ok($@ eq '', $name);
}

# Lets start by testing constants

can_ok('POE::Component::Jabber::Events', 
    qw/ PCJ_CONNECT PCJ_CONNECTING PCJ_CONNECTED PCJ_STREAMSTART
    PCJ_SSLNEGOTIATE PCJ_SSLSUCCESS PCJ_AUTHNEGOTIATE PCJ_AUTHSUCCESS
    PCJ_BINDNEGOTIATE PCJ_BINDSUCCESS PCJ_SESSIONNEGOTIATE PCJ_SESSIONSUCCESS
    PCJ_NODESENT PCJ_NODERECEIVED PCJ_NODEQUEUED PCJ_RTS_START
    PCJ_RTS_FINISH PCJ_READY PCJ_STREAMEND PCJ_SHUTDOWN_START
    PCJ_SHUTDOWN_FINISH PCJ_SOCKETFAIL PCJ_SOCKETDISCONNECT PCJ_AUTHFAIL
    PCJ_BINDFAIL PCJ_SESSIONFAIL PCJ_SSLFAIL PCJ_CONNECTFAIL/);

can_ok('POE::Component::Jabber::ProtocolFactory',
	qw/ JABBERD14_COMPONENT JABBERD20_COMPONENT LEGACY XMPP /);

#now lets test ProtocolFactory

my $guts = POE::Component::Jabber::ProtocolFactory::get_guts(+XMPP);
isa_ok($guts, 'POE::Component::Jabber::XMPP');
isa_ok($guts, 'POE::Component::Jabber::Protocol');
$guts = POE::Component::Jabber::ProtocolFactory::get_guts(+LEGACY);
isa_ok($guts, 'POE::Component::Jabber::Legacy');
isa_ok($guts, 'POE::Component::Jabber::Protocol');
$guts = POE::Component::Jabber::ProtocolFactory::get_guts(+JABBERD14_COMPONENT);
isa_ok($guts, 'POE::Component::Jabber::J14');
isa_ok($guts, 'POE::Component::Jabber::Protocol');
$guts = POE::Component::Jabber::ProtocolFactory::get_guts(+JABBERD20_COMPONENT);
isa_ok($guts, 'POE::Component::Jabber::J2');
isa_ok($guts, 'POE::Component::Jabber::Protocol');

#now lets test constructing PCJ

my $config = 
{
	IP => 'jabber.org',
	Port => '5222',
	Hostname => 'jabber.org',
	Username => 'PCJTester',
	Password => 'PCJTester',
	ConnectionType => +XMPP,
};

my $scratch_space = {};

POE::Session->create
(
	'inline_states' =>
	{
		'_start' =>
			sub
			{
				$_[KERNEL]->alias_set('basic_testing');
				$_[KERNEL]->yield('continue');
				$_[HEAP] = $config;
			},
		
        'continue' =>
			sub
			{
				test_new_pcj_fail('No arguments');

				my @keys = keys(%{$_[HEAP]});
				foreach my $key (@keys)
				{
					my %hash = %{$_[HEAP]};
					delete($hash{$key});
					test_new_pcj_fail('No ' . $key, %hash);
				}

                $_[HEAP]->{'Alias'} = 'PCJ_TESTER';
				$_[HEAP]->{'ConnectionType'} = 12983;
				
                test_new_pcj_fail('Invalid ConnectionType', %{$_[HEAP]});

                $_[KERNEL]->yield('xmpp');
            },
        
        'xmpp'  =>
            sub
            {	
				$_[HEAP]->{'ConnectionType'} = +XMPP;
                test_new_pcj_succeed('Correct construction XMPP', %{$_[HEAP]});
                $_[KERNEL]->call('PCJ_TESTER', 'destroy');

                $_[KERNEL]->yield('legacy');
            },

        'legacy' =>
            sub
            {   
                ok(!$_[KERNEL]->post('PCJ_TESTER'), 'XMPP component destroyed');
				$_[HEAP]->{'ConnectionType'} = +LEGACY;
				test_new_pcj_succeed('Correct construction LEGACY', %{$_[HEAP]});
                $_[KERNEL]->call('PCJ_TESTER', 'destroy');

                $_[KERNEL]->yield('j14');
            },

        'j14'   =>
            sub
            {   
                ok(!$_[KERNEL]->post('PCJ_TESTER'), 'LEGACY component destroyed');
				$_[HEAP]->{'ConnectionType'} = +JABBERD14_COMPONENT;
				test_new_pcj_succeed('Correct construction J14', %{$_[HEAP]});
                $_[KERNEL]->call('PCJ_TESTER', 'destroy');

                $_[KERNEL]->yield('j20');
            },

        'j20'   =>
            sub
            {
                ok(!$_[KERNEL]->post('PCJ_TESTER'), 'J14 component destroyed');
				$_[HEAP]->{'ConnectionType'} = +JABBERD20_COMPONENT;
				test_new_pcj_succeed('Correct construction J2', %{$_[HEAP]});
                $_[KERNEL]->call('PCJ_TESTER', 'destroy');

                $_[KERNEL]->yield('destroyed');
				
			},

        'destroyed' =>
            sub
            {
                ok(!$_[KERNEL]->post('PCJ_TESTER'), 'J20 component destroyed');
            },
	}
);

POE::Kernel->run();

exit 0;
