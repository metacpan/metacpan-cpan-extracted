# WIZARD_GROUP PBS
# WIZARD_NAME  distributor
# WIZARD_DESCRIPTION template for a distributor defintion
# WIZARD_ON

print <<'EOP' ;
use PBS::Shell::Telnet ;
use PBS::Shell::SSH ;
use PBS::Shell ;

#~ our $build_sequence ;
#~ my $number_of_o_node = 0 ;

#~ for my $node (@$build_sequence)
	#~ {
	#~ $number_of_o_node++ if $node->{__NAME} =~ /\.o$/ ;
	#~ }
	
#~ PrintDebug "Number of object nodes = $number_of_o_node\n" ;	

# You can also set $node->{__SHELL_OVERRIDE} to the shell the node will be build in
# use this with precausion and mainly to force local compilation
# giving a remote shell object might not work as you have no control on the scheduler
# and multiple nodes might be build with the same shell object simulteanously.
# It is safe to give diffrent shells for diffrent nodes. This gives the possibility to 
# build a specific node on a specific box but you must not share the connection between objects.

[
new PBS::Shell::Telnet
	(
	HOST_NAME              => '192.168.1.98',
	USER_NAME              => 'user',
	PASSWORD               => '****',
	TIMEOUT                => 10,
	PROMPT                 => '/.+]\$ $/',
	LOGIN_COMMANDS         => 
		[
			['cd /devel', '/devel]\$ $/']
		],
	
	REUSE_CONNECTION       => 1,
	USER_INFO              => " [1GHz]",
	COMMAND_COLOR          => \&PrintUser
	)
		
# for SSH conection, you must setup up an SSH agent
, new PBS::Shell::SSH
	(
	  HOST_NAME => 'localhost'
	, USER_NAME => 'nadim'
	, USER_INFO => " [3GHz]"
	)

, new PBS::Shell(USER_INFO => " [3GHz]")
]

# it is also possible to return a distributor object that implements the same
# interface as PBS::Distributor.

EOP


