#
# $Id: Session.pm,v 0.16 2003/08/07 00:01:59 lawrence Exp $
#

package Net::Msmgr::Session;
use strict;
use warnings;
use Net::Msmgr qw(:debug GetVersion8Response );
use Net::Msmgr::Object;
use Net::Msmgr::Switchboard;
use Net::Msmgr::Conversation;
use Carp;

our @ISA = qw (Net::Msmgr::Object);

sub _fields { return shift->SUPER::_fields,( proto => 'MSNP2',
					     user => undef,
					     debug => 0,
					     list_version => 0,
					     list => undef,
					     roster => undef,
					     login_handler => undef,
					     logout_handler => undef,
					     connect_handler => undef,
					     disconnect_handler => undef,
					     conversation => {},
					     _conv_by_handle => {},
					     ns => undef) ; }

=pod

=head1 NAME

Net::Msmgr::Session -- The main point of contact in a Perl MSN Client

=head1 SYNOPSIS

 our $session = new Net::Msmgr::Session;
 our $user = new Net::Msmgr::User ( user => 'username@msn.com',
                             password => 'my_password' ) ;

 $session->user($user);
 $session->login_handler( sub { shift->Logout } ) ;
 $session->Login;

 Event::loop;


=head1 DESCRIPTION

Net::Msmgr::Session is the encapsulation for an
entire MSN Messenger Client session.  You
register handlers to deal with various inbound
messages such as incoming chat requests or
state change notifications.  When you are
finished, you call instance method Logout and
everything goes away.

=head1 CONSTRUCTOR

    my $session = new Net::Msmgr::Session (...);

	- or -

    my $session = Net::Msmgr::Session->new(...);


Constructor parameters are:

=over

=item user (mandatory) 

The container for the Authentication Data for the
    session.


=item login_handler (optional)

A code reference to a subroutine that will be
called upon successful authentication and
connection to the notification server.

=item connect_handler (optional)

A code reference to a subroutine that will be called after each
connection to a server.

=item disconnect_handler (optional)

A code reference to a subroutine that will be called just before each
close call when disconnecting from a server.

=back

=cut

### 
###  These are methods for handling common user-interface requests
###

=pod

=head1 INSTANCE METHODS

=over

=item $session->ui_new_conversation;

Instantiate a new conversation (which you can later invite people to)

=cut

sub ui_new_conversation( $ )
{
    my $self = shift;
    my $conversation = new Net::Msmgr::Conversation( session => $self );
    $self->add_conversation($conversation);
    
    my $command = Net::Msmgr::Command->new(type => Net::Msmgr::Command::Normal,
				    cmd => 'XFR',
				    params => [ 'SB' ] );
    $command->send($self->ns);
    $self->{_conv_by_handle}->{$command->trid} = $conversation;
    return $conversation;
}

=pod

=item	$session->ui_invite_conversation($conversation, $username);

Send an invitation to another user.
    
=cut

=pod

=item	$session->ui_sync;

Initiate list syncronization.

=cut
    
sub ui_sync($)
{
    my ($self) = @_;
    Net::Msmgr::Command->new(type => Net::Msmgr::Command::Normal,
		      cmd => 'SYN',
		      params => [ '0' ] )->send($self->ns);
}

=pod

=item	$session->ping;

Ping the Notification Server.

=cut

sub ui_ping
{
    my ($self) = @_;
    Net::Msmgr::Command->new(type => Net::Msmgr::Command::Async,
		      cmd => 'PNG')->send($self->ns);
}

=pod

=item	$session->ui_send_message($ssid, $message);

Send a message to all users in Switchboard Connection $ssid.  $message 
must be a properly MIME formatted message.

=cut

sub ui_send_message($$$;$)
{
    carp 'use $conversation->send_message instead';
}

=pod

=item	$session->ui_state_nln;

=item	$session->ui_state_bsy;

=item	$session->ui_state_idl;

=item	$session->ui_state_brb;

=item	$session->ui_state_awy;

=item	$session->ui_state_phn;

=item	$session->ui_state_lun;

=item	$session->ui_state_hdn;

Set your Notification Status to one of Online (NLN), Busy (BSY), Idle (IDL),
Be Right Back (BRB), Away (AWY), Phone (PHN), Out To Lunch (LUN), or Hidden (HDN).  
All of these are advisory, except hidden, which makes you appear offline, and disallows
initiation of Switchboard sessions.

=cut

sub ui_state_nln
{
    my ($self) = @_;
    Net::Msmgr::Command->new(type => Net::Msmgr::Command::Normal,
		      cmd => 'CHG',
		      params => [ 'NLN' ] )->send($self->ns);
}

sub ui_state_bsy
{
    my ($self) = @_;
    Net::Msmgr::Command->new(type => Net::Msmgr::Command::Normal,
		      cmd => 'CHG',
		      params => [ 'BSY' ] )->send($self->ns);
}

sub ui_state_idl
{
    my ($self) = @_;
    Net::Msmgr::Command->new(type => Net::Msmgr::Command::Normal,
		      cmd => 'CHG',
		      params => [ 'IDL' ] )->send($self->ns);
}

sub ui_state_brb
{
    my ($self) = @_;
    Net::Msmgr::Command->new(type => Net::Msmgr::Command::Normal,
		      cmd => 'CHG',
		      params => [ 'BRB' ] )->send($self->ns);
}

sub ui_state_awy
{
    my ($self) = @_;
    Net::Msmgr::Command->new(type => Net::Msmgr::Command::Normal,
		      cmd => 'CHG',
		      params => [ 'AWY' ] )->send($self->ns);
}

sub ui_state_phn
{
    my ($self) = @_;
    Net::Msmgr::Command->new(type => Net::Msmgr::Command::Normal,
		      cmd => 'CHG',
		      params => [ 'PHN' ] )->send($self->ns);
}

sub ui_state_lun
{
    my ($self) = @_;
    Net::Msmgr::Command->new(type => Net::Msmgr::Command::Normal,
		      cmd => 'CHG',
		      params => [ 'LUN' ] )->send($self->ns);
}

sub ui_state_hdn
{
    my ($self) = @_;
    Net::Msmgr::Command->new(type => Net::Msmgr::Command::Normal,
		      cmd => 'CHG',
		      params => [ 'HDN' ] )->send($self->ns);
}

sub add_default_handlers
{
    my $self = shift;
    return unless $self && $self->ns;

    $self->ns->add_handler('_handle_xfr','XFR'); 
    $self->ns->add_handler('_handle_usr','USR');
    $self->ns->add_handler('_handle_rng','RNG');
    $self->ns->add_handler('_handle_chg','CHG');
    $self->ns->add_handler('_handle_iln','ILN');
    $self->ns->add_handler('_handle_nln','NLN');
    $self->ns->add_handler('_handle_fln','FLN');
    $self->ns->add_handler('_handle_lst','LST');

    $self->ns->add_handler('_handle_misc','GTC','BLP','PRP','LSG','ADD','REM','REA','ADG','RMG','REG');
    return $self;
}

sub dispatch_all
{
    my ($self, $connection, $command) = @_;
    foreach my $handler (@{$connection->{handlers}->{$command->cmd}})
    {
	if ($self->debug & DEBUG_HANDLER)
	{
	    print STDERR $connection->name ," is calling a " . $command->cmd ." handler\n";
	}
	$self->dispatch($handler,$command);
    }
}

#
# Currently - dispatch takes a single method-name
# and calls it within session
#
# sub dispatch
# {
#     my ($self, $handler, $command) = @_;
#     my ($method, @params) = @$handler;
#     $self->$method($command, @params);
# }


#
# Instead, let us do it more like Perl/Tk callbacks
# so - it can be 
# [ \&subroutine @params ] -- call subroutine ($command, @params )
# [ 'method' ] -- call $self->method ($command, @params)
# [ $object, 'method' ] -- call $object->method ($command, @params)
# 

sub dispatch
{
    my ($self, $handler, $command) = @_;
    
    my ($first, @params) = @$handler;
    if (ref($first) eq 'CODE')
    {
	\&$first($command, @params)
    }
    elsif (ref($first))		# is this an object reference
    {
	my $method = shift @params; # pick up method name
	$first->$method($command, @params);
    }
    else
    {
	$self->$first($command, @params);
    }
}

sub list
{
    my $self = shift;
    $self->{list} = { AL => [], FL => [], BL => [], RL => [] }  unless $self->{list};
    return $self->{list};
}

sub online
{
    my ($self, $user, $sub_status) = @_;
    $self->{roster}->{$user} = $sub_status;
}

sub offline
{
    my ($self, $user) = @_;
    delete $self->{roster}->{$user};
}

=pod

=item $session->Logout;

The end of the road.

=cut


sub Logout
{
    my $self = shift;
    foreach my $conversation (values(%{$self->conversation}))
    {
	$self->del_conversation($conversation);
    }
    $self->ns->shutdown;
    $self->ns(undef);
}

=pod

=item $session->Login;

The beginning of the road.  If
$session->login_handler is defined, it will be
treated as a callback when the session connects,
and passed the single parameter of the
Net::Msmgr::Session object

=cut

sub Login( $ )
{
    my $self = shift;
    unless ($self->ns)
    {
	$self->ns( new Net::Msmgr::Connection(session => $self ) );
	
	$self->ns->debug($self->debug);
	$self->add_default_handlers;
	$self->ns->add_handler($self->login_handler,'login');
    }
    $self->ns->connect;
    &{$self->{connect_handler}}($self->ns) if $self->{connect_handler};
    my $status;
    $status = Net::Msmgr::Command->new(type => Net::Msmgr::Command::Normal,
				cmd => 'VER',
				params => [ $self->proto , 'CVR0' ] )->send($self->ns) ;
    
    if ($self->proto eq 'MSNP8')
    {
	$status = Net::Msmgr::Command->(type => Net::Msmgr::Command::Normal,
				 cmd => 'CVR',
				 params => [qw ( 0x0409 winnt 5.1 i386 MSNMSGR 5.0.0515 MSMSGS ) , $self->user->user  ])->send($self->ns);
	
	$status = Net::Msmgr::Command (type => Net::Msmgr::Command::Normal,
				cmd => 'USR',
				params => [ 'TWN', 'I', $self->user->user ] )->send($self->ns);
	
    }
    else
    {
	$status = Net::Msmgr::Command->new( type => Net::Msmgr::Command::Normal,
				     cmd => 'USR',
				     params => [ 'MD5','I', $self->user->user ] )->send($self->ns);
	
    }
}

### <<< XFR  2 NS 207.46.106.145:1863 0 207.46.104.20:1863 
### <<< XFR 10 SB 207.46.108.37:1863 CKI 17262740.1050826919.32308
###          0  1              2      3            4
sub _handle_xfr($$)
{
    my ($self, $command) = @_;
    
    my @param = @{$command->params};

    $param[2] =~ m/(\d+\.\d+\.\d+\.\d+):(\d+)/;
    my ($nserver, $nsport) = ($1,$2);

    if ($param[1] eq 'NS')	# going from DS to NS
    {
	my $oldns = $self->ns;

	$self->ns(new Net::Msmgr::Connection ( nserver => $nserver,
					nsport => $nsport,
					debug => $oldns->debug,
					session => $self,
					handlers => $oldns->handlers,
					name => 'Notification Server'));
	$self->Login;
	$oldns->close;	# destroy old session
    }
    elsif ($param[1] eq 'SB')	# adding a connection to a switchboard
    {
	$param[4] =~ m/(\d*)\..*/;
	my $ssid = $1;
	my $conversation = $self->{_conv_by_handle}->{$param[0]};
	my $sb = new Net::Msmgr::Switchboard ( nserver => $nserver,
					nsport => $nsport,
					debug => $self->ns->debug,
					session => $self,
					ssid => $ssid, 
					name => 'Switchboard Channel ' . $ssid );
	$sb->connect;
	&{$self->{connect_handler}}($sb) if $self->{connect_handler};
	
	$command = new Net::Msmgr::Command ( type => Net::Msmgr::Command::Normal,
				      cmd => 'USR',
				      params => [ $self->user->user, $param[4] ] );
	if (my $conversation = $self->{_conv_by_handle}->{$param[0]})
	{
	    $conversation->switchboard($sb);
	    $sb->add_handler([$conversation, '_handle_usr'], 'USR');
	    $sb->add_handler([$conversation, '_handle_iro'], 'IRO');
	    $sb->add_handler([$conversation, '_handle_bye'], 'BYE');
	    $sb->add_handler([$conversation, '_handle_joi'], 'JOI');
	    my $command = new Net::Msmgr::Command ( type => Net::Msmgr::Command::Pseudo,
					     cmd => 'conversation',
					     params => [ $conversation ] );
	    $self->dispatch_all($self->ns, $command); 
	}

	$command->send($sb);


    }
    else
    {
	warn "unheard of XFR target `$param[1]'";
    }
}

sub _handle_usr
{
    my ($self, $command) = @_;
#    my $command = shift;
    my @param = @{$command->params};

    ### <-- USR 5 OK arrow@sandbox.cluon.com Arrow%20The%20Dog
    ###         0  1    2                     3
    if ($param[1] eq 'OK')	# special case
    {
	$self->ns->add_handler('Logout','close');
	my $pseudo = new Net::Msmgr::Command;
	$pseudo->type(Net::Msmgr::Command::Pseudo);
	$pseudo->cmd('login');
	$self->dispatch_all($self->ns, $pseudo);
    }
    elsif ($param[1] eq 'TWN' && $param[2] eq 'S')
    {
	my $magic_token = GetVersion8Response($self->user, @param);
	warn "No authentication token" unless $magic_token;
	Net::Msmgr::Command->new( type => Net::Msmgr::Command::Normal,
			   cmd => 'USR',
			   params => [ 'TWN', 'S', $magic_token ] )->send($self->ns);
    }
    elsif ($param[1] eq 'MD5' && $param[2] eq 'S')
    {
	$self->user->salt($param[3]);
	Net::Msmgr::Command->new( type => Net::Msmgr::Command::Normal,
			   cmd => 'USR',
			   params => [ 'MD5', 'S', $self->user->crypto_passwd ] )->send($self->ns);
    }
}

sub _handle_rng
{
    ## RNG 111920 207.46.108.76:1863 CKI 1059841202.25757 lawrenceeu@hotmail.com FriendlyName
    ##      0                1       2     3                 4                       5
    my ($self, $command) = @_;
    my @params = @{$command->params};

    $params[1] =~ m/(\d+\.\d+\.\d+\.\d+):(\d+)/;
    my ($server, $port) = ($1,$2);

    my $sb = new Net::Msmgr::Switchboard( nserver => $server,
				   nsport => $port,
				   name => 'Switchboard Channel ' . $params[0],
				   debug => $self->debug,
				   ssid => $params[0],
				   session => $self)->connect;
    &{$self->{connect_handler}}($sb) if $self->{connect_handler};

    my $conversation = new Net::Msmgr::Conversation ( session => $self,
					       switchboard => $sb );
    $self->add_conversation($conversation);

    $sb->add_handler([$conversation, '_handle_ans'], 'ANS');
    $sb->add_handler([$conversation, '_handle_iro'], 'IRO');
    $sb->add_handler([$conversation, '_handle_bye'], 'BYE');
    $sb->add_handler([$conversation, '_handle_joi'], 'JOI');
    $command = new Net::Msmgr::Command ( type => Net::Msmgr::Command::Pseudo,
				  cmd => 'conversation',
				  connection => $sb,
				  params => [ $conversation ] );
    $self->dispatch_all($self->ns, $command); 

    $command = Net::Msmgr::Command->new(type => Net::Msmgr::Command::Normal,
				    cmd => 'ANS',
				    params => [ $self->user->user, $params[3], $params[0] ] );

    $command->send($sb);

}

sub _handle_ans
{
}

### <<< LST trid ln 12182 1 3 myname@msn.com My%20Name\r\n
### <<< LST trid ln 12182 2 3 example@passport.com Mike\r\n
### <<< LST trid ln 12182 3 3 name_123@hotmail.com Name_123\r\n
###           0   1     2 3 4  5                     6
### $pr->[1] is one of AL, FL, BL, or RL
### $pr->[2] is the list version number (if any of the four lists change, the version number bumps)
### $pr->[3] is sequence number
### $pr->[4] is # of items in the list
### $pr->[5] is the email and $pr->[6] is the friendly name
sub _handle_lst
{
    my ($self, $command) = @_;
    my $pr = $command->params;
    if ($pr->[4])
    {
	$self->list_version($pr->[2]);
	$self->list->{$pr->[1]}->[$pr->[3] -1 ] = $pr->[5];
    }
    else
    {
	$self->list_version($pr->[2]);
	$self->list->{$pr->[1]} = [];
    }
}


our %_status_words = ( NLN => 'Online', BSY => 'Busy', IDL => 'Idle', BRB => 'Be Right Back',
		       AWY => 'Away', PHN => 'On the phone', LUN => 'Out to Lunch', HDN => 'Hidden', FLN => 'Offline' ); 


### Async message -- no trid
### <<< NLN NLN msnuser@msn.com Friendly%20User
###         0    1               2

sub _handle_nln
{
    my ($self, $command) = @_;
    my $pr = $command->params;
    $self->online($pr->[1], $_status_words{$pr->[0]});
}

sub _handle_fln
{
    my ($self, $command) = @_;
    my $pr = $command->params;
    $self->offline($pr->[0]);
}

### Syncronous - response to your first CHG trid NLN
### <<< ILN trid NLN msnuser@msn.com Friendly%20User
###         0    1   2               3
sub _handle_iln
{
    my ($self, $command) = @_;
    my $pr = $command->params;
    $self->online($pr->[2], $_status_words{$pr->[1]});
}

### <<< CHG trid NLN
### <<< CHG trid BSY
### <<< CHG trid IDL
### <<< CHG trid BRB
### <<< CHG trid AWY
### <<< CHG trid PHN
### <<< CHG trid LUN

sub _handle_chg
{
    my ($self, $command) = @_;
    my $pr = $command->params;
}

sub _handle_misc
{
    my ($self, $command) = @_;
    print STDERR $command->as_text if $self->{debug} & DEBUG_NOTIFICATION;
}

sub add_conversation($$)
{
    my ($self, $conversation) = @_;
    $self->conversation->{$conversation} = $conversation;
    return $conversation;
}

sub del_conversation($$)
{
    my ($self, $conversation) = @_;
    $self->conversation->{$conversation}->shutdown;
    delete $self->conversation->{$conversation};
}

sub list_conversations($)
{
    my ($self) = @_;
    return values(%{$self->{conversation}});
}

# sub add_sb
# {
#     my $self = shift;
#     my $sb = shift;
#     my $ssid = shift;
#     $self->{sb}->{$ssid} = $sb;
# }

# sub del_sb
# {
#     my $self = shift;
#     my $ssid = shift;
#     return undef unless $ssid && exists ($self->{sb}->{$ssid});
#     $self->{sb}->{$ssid}->shutdown;
#     delete $self->{sb}->{$ssid};
# }

# sub all_sb
# {
#     my $self = shift;
#     return keys(%{$self->{sb}});
# }

1;

#

# $Log
#
