#!/usr/bin/perl
use warnings;
use strict;

use 5.010;
use Test::More tests => 16;
use IO::File;
use POE;
use POE::Component::Jabber;

my $file;
if(-e 'run_network_tests')
{
	$file = IO::File->new('< run_network_tests');

} else {
	
	SKIP: { skip('Network tests were declined', 16); }
	exit 0;
}

my $file_config = {};

my @lines = $file->getlines();
if(!@lines)
{
	SKIP: { skip('Component tests were declined', 16); }
	exit 0;
}

for(0..$#lines)
{
	my $i = $_;

	if($lines[$_] =~ /#/)
	{
		$lines[$_] =~ s/#+|\s+//g;
		my $hash = {};
		my $subline = $lines[++$i];
		do
		{
			chomp($subline);
			my ($key, $value) = split(/=/,$subline);
			$hash->{lc($key)} = lc($value);
			$subline = $lines[++$i];

		} while(defined($subline) && $subline !~ /#/);

		$file_config->{lc($lines[$_])} = $hash;
	}
}

$file->close();
undef($file);

my $config = 
{
	IP => $file_config->{'jabberd20'}->{'ip'},
	Port => $file_config->{'jabberd20'}->{'port'},
	Hostname => $file_config->{'jabberd20'}->{'host'},
	Username => $file_config->{'jabberd20'}->{'user'},
	Password => $file_config->{'jabberd20'}->{'secret'},
	ConnectionType => +JABBERD20_COMPONENT,
	debug => 0,
};

my $scratch_space = {};

POE::Session->create
(
	'inline_states' =>
	{
		'_start' =>
			sub
			{
				$_[KERNEL]->alias_set('j20_testing');
				$config->{'Alias'} = 'pcj';
				$_[HEAP]->{'pcj'} = POE::Component::Jabber->new(%$config);
				$_[KERNEL]->yield('continue');
			},
		'continue' =>
			sub
			{
                $_[KERNEL]->post('pcj', 'subscribe', +PCJ_CONNECT, 'pcj_connect');
                $_[KERNEL]->post('pcj', 'subscribe', +PCJ_CONNECTING, 'pcj_connecting');
                $_[KERNEL]->post('pcj', 'subscribe', +PCJ_CONNECTED, 'pcj_connected');
                $_[KERNEL]->post('pcj', 'subscribe', +PCJ_CONNECTFAIL, 'pcj_connectfail');
                $_[KERNEL]->post('pcj', 'subscribe', +PCJ_STREAMSTART, 'pcj_streamstart');
                $_[KERNEL]->post('pcj', 'subscribe', +PCJ_STREAMEND, 'pcj_streamend');
                $_[KERNEL]->post('pcj', 'subscribe', +PCJ_SSLNEGOTIATE, 'pcj_sslnegotiate');
                $_[KERNEL]->post('pcj', 'subscribe', +PCJ_SSLSUCCESS, 'pcj_sslsuccess');
                $_[KERNEL]->post('pcj', 'subscribe', +PCJ_SSLFAIL, 'pcj_sslfail');
                $_[KERNEL]->post('pcj', 'subscribe', +PCJ_AUTHNEGOTIATE, 'pcj_authnegotiate');
                $_[KERNEL]->post('pcj', 'subscribe', +PCJ_AUTHSUCCESS, 'pcj_authsuccess');
                $_[KERNEL]->post('pcj', 'subscribe', +PCJ_AUTHFAIL, 'pcj_authfail');
                $_[KERNEL]->post('pcj', 'subscribe', +PCJ_BINDNEGOTIATE, 'pcj_bindnegotiate');
                $_[KERNEL]->post('pcj', 'subscribe', +PCJ_BINDSUCCESS, 'pcj_bindsuccess');
                $_[KERNEL]->post('pcj', 'subscribe', +PCJ_BINDFAIL, 'pcj_bindfail');
                $_[KERNEL]->post('pcj', 'subscribe', +PCJ_READY, 'pcj_ready');
                $_[KERNEL]->post('pcj', 'subscribe', +PCJ_SHUTDOWN_START, 'pcj_shutdown_start');
                $_[KERNEL]->post('pcj', 'subscribe', +PCJ_SHUTDOWN_FINISH, 'pcj_shutdown_finish');
                $_[KERNEL]->post('pcj', 'subscribe', +PCJ_SOCKETFAIL, 'pcj_socketfail');
                $_[KERNEL]->post('pcj', 'subscribe', +PCJ_SOCKETDISCONNECT, 'pcj_socketdisconnect');
                $_[KERNEL]->post('pcj', 'subscribe', +PCJ_NODERECEIVED, 'pcj_nodereceived');
                $_[KERNEL]->post('pcj', 'subscribe', +PCJ_NODESENT, 'pcj_nodesent');
				
				if(-e 'run_network_tests')
				{
					$_[KERNEL]->post('pcj', 'connect');
				
				} else {
					
					SKIP: { skip('Network tests were declined', 16); }
					exit 0;
				}
			},
        'pcj_nodesent' =>
            sub
            {   
                my ($kernel, $arg) = @_[KERNEL, ARG0];
                if($config->{'debug'})
                {
                    say $arg->toString();
                }
            },
        'pcj_nodereceived' =>
            sub
            {
                my ($kernel, $arg) = @_[KERNEL, ARG0];
                if($config->{'debug'})
                {
                    say $arg->toString();
                }
            },
        'pcj_connect' =>
            sub
            {
                pass('Connect started');
            },
        'pcj_connecting' =>
            sub
            {
                pass('Connecting');
            },
        'pcj_connected' =>
            sub
            {
                pass('Connection sucessful');
            },
        'pcj_connectfail' =>
            sub
            {
                BAIL_OUT(q|We couldn't connect to the server. Check your |.
                    'network connection or rerun Build.PL and say "N" to '.
                    'network enabled tests');
            },
        'pcj_streamstart' =>
            sub
            {
                pass('Stream initated');
            },
        'pcj_streamend' =>
            sub
            {
                $scratch_space->{'STEAMEND'} = 1;
                pass('Stream end sent');
            },
        'pcj_sslnegotiate' =>
            sub
            {
                pass('Negotiating SSL/TLS');
            },
        'pcj_sslsuccess' =>
            sub
            {
                pass('SSL/TLS sucessfully negotiated');
            },
        'pcj_sslfail' =>
            sub
            {
                BAIL_OUT('SSL failed for some reason. Since this is, '.
                    'for the most part, a dynamic/automatic process, '.
                    'there may be a problem with the server.');
            },
	    'pcj_authnegotiate' =>
            sub
            {
                pass('Negotiating authentication');
            },
        'pcj_authsuccess' =>
            sub
            {
                pass('Authentication sucessfully negotiated');
            },
        'pcj_authfail' =>
            sub
            {
                BAIL_OUT('Authentication failed for some reason. ' .
                    'Please check the username and password in this test '.
                    'to make sure it is correct.');
            },
	    'pcj_bindnegotiate' =>
            sub
            {
                pass('Negotiating bind');
            },
        'pcj_bindsuccess' =>
            sub
            {
                $scratch_space->{'BIND'} = 1;
                pass('Bind successfully negotiated');
            },
        'pcj_bindfail' =>
            sub
            {
                BAIL_OUT('Binding failed for some reason. Since this is, '.
                    'for the most part, a dynamic/automatic process, '.
                    'there may be a problem with the server.');
            },
        'pcj_ready' =>
            sub
            {
                pass('PCJ initialization complete');

                $_[KERNEL]->post('pcj', 'shutdown');

			},
        
        'pcj_shutdown_start' =>
            sub
            {
                if(!defined($scratch_space->{'STEAMEND'}))
                {
                    fail('A stream end was not sent to the server!');
                
                } else {

                    $scratch_space->{'SHUTDOWNSTART'} = 1;
                    pass('Shutdown in progress');
                }
            },

        'pcj_shutdown_finish' =>
            sub
            {
                if(!defined($scratch_space->{'SHUTDOWNSTART'}))
                {
                    fail('Shutdown start was never called');
                
                } else {

                    pass('Shutdown complete');
                }
			},

        'pcj_socketfail' =>
            sub
            {
                if(!defined($scratch_space->{'STEAMEND'}))
                {
                    BAIL_OUT('There was a socket failure during testing');
                
                } else {

                    pass('Socket read error at end of stream okay');
                }
            },
        'pcj_socketdisconnect' =>
            sub
            {
                if(!defined($scratch_space->{'SHUTDOWNSTART'}))
                {
                    BAIL_OUT('We were disconnected during testing');
                
                } else {

                    pass('Disconnected called at the right time');
                }
            },
	}
);

POE::Kernel->run();

exit 0;
