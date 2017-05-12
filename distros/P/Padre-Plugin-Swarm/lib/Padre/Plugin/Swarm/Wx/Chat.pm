package Padre::Plugin::Swarm::Wx::Chat;

use 5.008;
use strict;
use warnings;
use Text::Patch ();
use Params::Util qw{_INSTANCE};

use Padre::Current qw{_CURRENT};
use Padre::Logger;
use Padre::Wx ();
use Padre::Config ();
use Padre::Plugin::Swarm ();
use Padre::Swarm::Identity;
use Padre::Swarm::Message;
use Padre::Swarm::Message::Diff;
use Padre::Util;
our $VERSION = '0.2';
our @ISA     = 'Wx::Panel';

use Class::XSAccessor
	accessors => {
		universe  => 'universe',
		textinput => 'textinput',
		chatframe => 'chatframe',
		userlist  => 'userlist',
		users => 'users',
		label =>'label',
	},
	setters => {
		'set_task' => 'task',
	};

sub new {
	my $class = shift;
	my %args = @_;
	my $self = $class->SUPER::new(
		$class->plugin->wx , -1,
		#'',
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxLC_REPORT
		| Wx::wxLC_SINGLE_SEL
	);
	$self->$_( $args{$_} ) for qw( universe label );
	Padre->ide->wx->main->bottom->show($self);
	
	# build large area for chat output , with a
	#  single line entry widget for input
	my $sizer = Wx::BoxSizer->new(Wx::wxVERTICAL);
        my $hbox = Wx::BoxSizer->new(Wx::wxHORIZONTAL);
	my $text = Wx::TextCtrl->new(
		$self, -1, '',
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxTE_PROCESS_ENTER | Wx::wxTE_PROCESS_TAB
	);
	my $chat = Wx::TextCtrl->new(
		$self, -1, '',
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxTE_READONLY
		| Wx::wxTE_MULTILINE
		| Wx::wxTE_RICH
		| Wx::wxNO_FULL_REPAINT_ON_RESIZE
	);
	my $style = $chat->GetDefaultStyle;
	my $font   = Wx::Font->new( 10, Wx::wxTELETYPE, Wx::wxNORMAL, Wx::wxNORMAL );
	$style->SetFont($font);
	$chat->SetDefaultStyle( $style );
	
	my $userlist = Wx::ListView->new(
		$self, -1 ,
                Wx::wxDefaultPosition,
                Wx::wxDefaultSize,
                Wx::wxLC_REPORT | Wx::wxLC_SINGLE_SEL
        );
        
        $userlist->InsertColumn( 0, 'Users' );
        $userlist->SetColumnWidth( 0, -1 );
	$self->userlist($userlist);
	
	$hbox->Add( $chat , 1 , Wx::wxGROW );
	$hbox->Add( $userlist, 0 , Wx::wxGROW );
	
	$sizer->Add($hbox,1, Wx::wxGROW );
	$sizer->Add($text,0, Wx::wxGROW );

	$self->textinput( $text );
	$self->chatframe( $chat );
	$self->SetSizer($sizer);

	my $config = Padre::Config->read;
	my $nickname = $config->identity_nickname;
	unless ( $nickname ) {
		$nickname = "Anonymous_$$";
	}

	my $identity = Padre::Swarm::Identity->new(
		nickname => $nickname,
		service  => 'chat',
		resource => 'Padre',
	);

	$self->users( {} );
        
	Wx::Event::EVT_TEXT_ENTER(
                $self, $text,
                \&on_text_enter
        );
        
        Wx::Event::EVT_CHAR(
		$text,
		sub{ $self->on_text_char(@_) },
        );
        
    $self->universe->reg_cb( 'enable' , sub { $self->enable(@_) } );
	$self->universe->reg_cb( 'disable' , sub { $self->disable(@_) } );
	

	return $self;
}

sub plugin { Padre::Plugin::Swarm->instance };

sub bottom {
	$_[0]->GetParent;
}

sub main {
	$_[0]->GetGrandParent;
}

sub view_panel { 'bottom' }

sub view_label {
	my $self = shift;
	return $self->label . ' ' . Wx::gettext('Chat');
}

*gettext_label = \&view_label;

sub view_icon {
	my $self = shift;
	my $icon = $self->plugin->plugin_icon;
	return $icon;
}

sub enable {
	my $self     = shift;
	TRACE( "Enable Chat" ) if DEBUG;

	# Add ourself to the gui;
	my $main     = Padre->ide->wx->main;
	my $bottom   = $self->bottom;
	my $position = $bottom->GetPageCount;
	$self->update_userlist;
	$bottom->show($self);

	$self->textinput->SetFocus;
	$main->aui->Update;

	$self->{enabled} = 1;
}

sub disable {
	my $self = shift;
	TRACE( 'Disable Chat' ) if DEBUG;
	$self->universe->send( {type=>'leave', service=>'chat' } );
	my $main = Padre->ide->wx->main;
	my $bottom= $main->bottom;
	my $position = $bottom->GetPageIndex($self);
	$self->Hide;

	TRACE( "disable - $bottom" ) if DEBUG;
	$bottom->RemovePage($position);
	$main->aui->Update;
	#$self->Destroy;
}

sub update_userlist {
	my $self = shift;
	my $userlist = $self->userlist;
	my $geo = $self->universe->geometry;
	my @users = $geo->get_users();
	$userlist->DeleteAllItems;
	foreach my $user ( @users ) {
		my $item = Wx::ListItem->new( );
		$item->SetText( $user );
		$item->SetTextColour( 
			Wx::Colour->new( @{ derive_rgb($user) } )  
		);
		$userlist->InsertItem( $item );
	}
	$userlist->SetColumnWidth( 0, -1 );
	
}

sub on_recv {
	my $self = shift;
	my $message = shift;
	TRACE( "on_recv $message" ) if DEBUG;
	return unless _INSTANCE( $message , 'Padre::Swarm::Message' );
	my $handler = 'accept_' . $message->type;
	TRACE( $handler ) if DEBUG;
        if ( $self->can( $handler ) ) {
        	TRACE( $message->{from} . ' sent ' . $message->{type} ) if DEBUG;
            eval {
                $self->$handler($message);
            };
            if ($@) {
                $self->write_user_styled( $message->from,$message->from );
                $self->write_unstyled(" sent unhandled message " 
                    . $message->type .  $@ . "\n" );
                    
            }
        }

}

sub on_connect {
	my $self = shift;
	$self->universe->send(
		{type=>'announce',service=>'chat',
		from=>$self->plugin->identity->nickname 
	});
}

sub write_timestamp {
	my $self = shift;
	$self->chatframe->AppendText(
		sprintf( '%02d:%02d:%02d', (localtime())[2,1,0]  )  . ' '
	);
}

sub write_unstyled {
    my ($self,$text) = @_;
    my $style = $self->chatframe->GetDefaultStyle;
    $style->SetTextColour( 
		Wx::SystemSettings::GetColour( Wx::wxSYS_COLOUR_WINDOWTEXT ) 
	);
    $self->chatframe->SetDefaultStyle($style);
    $self->chatframe->AppendText($text);
    
}

sub write_user_styled { 
    my ($self,$user,$text) = @_;
    my $style = $self->chatframe->GetDefaultStyle;
    my $rgb   = derive_rgb( $user );
    $style->SetTextColour( Wx::Colour->new(@$rgb) );
    $self->chatframe->SetDefaultStyle($style);
    $self->chatframe->AppendText($text);
}

sub accept_chat {
    my ($self,$message) = @_;
    $self->write_timestamp;
    $self->write_user_styled(
        $message->from,
        $message->from . ': '
    );
    $self->write_unstyled( $message->body . "\n" );
    
}

sub accept_announce {
    my ($self,$announce) = @_;
    my $nick = $announce->from;
    if ( exists $self->users->{$nick} ) {
        return;
    }
    else {
    	$self->write_timestamp;
        $self->write_user_styled( $announce->from , $announce->from );
        $self->write_unstyled(  " has joined the swarm \n" );
        $self->users->{$nick} = 1;
    }
     $self->update_userlist;
}

sub accept_promote {
    my ($self,$message) = @_;
    
    ## Todo - manipulate the geometry ourselves for
    # 'chat' promote. stop spewing into the chat 
    # console.
    if ( $message->{service} eq 'chat' ) {
		$self->update_userlist;
    }
    
    
}

sub accept_disco {
	my ($self,$message) = @_;
	$self->universe->send( {type=>'promote',service=>'chat'} );
}

sub accept_leave {
    my ($self,$message) = @_;
    my $identity = $message->from;
    delete $self->users->{$identity};
    $self->write_timestamp;
    $self->write_user_styled( $identity , $identity );
    $self->write_unstyled( " has left the swarm.\n" );
    $self->update_userlist;
}


sub command_nick {
    my ($self,$new_nick) = @_;
    my $previous =
            $self->plugin->identity->nickname;
        eval {
            $self->plugin->identity->set_nickname($new_nick);
            my $config = Padre::Config->read;
            $config->set( identity_nickname => $new_nick );
            $config->write;
        };

	warn $@ if $@;
	
        $self->tell_service( 
            "was -> ".
            $previous	
        ) unless $@;
    
}

sub command_geo {
	my $self = shift;
	my $geo = $self->universe->geometry;
	foreach my $edge ( $geo->graph->edges ) {
		$self->write_unstyled( join (' => ' , @$edge) . "\n" );
	}
}

sub command_disco {
    my $self = shift;
    $self->universe->send({type=>'disco'});
}


sub tell_service {
	my $self    = shift;
	my $body    = shift;
	my $args    = shift;
	my $message = _INSTANCE($body,'Padre::Swarm::Message')
		? $body
		: Padre::Swarm::Message->new(
			body => $body,
			type => 'chat',
		);
	$self->universe->send($message)
}

sub on_text_enter {
    my ($self,$event) = @_;
    my $message = $self->textinput->GetValue;
    $self->textinput->SetValue('');
    
    if ( $message =~ m{^/(\w+)} ) {
        $self->accept_command( $message ) 
    }    
    else {
        $self->tell_service( $message );
    }
}

sub on_text_char {
	my ($self,$ctrl,$event) = @_;
	my $code = $event->GetKeyCode;
        if ($code != Wx::WXK_TAB) {
                $event->Skip(1);
                return;
        }
        my $partial = $ctrl->GetValue;
        my ($fragment) = $partial =~ /(\w+)$/;
        return unless $fragment;
        
        my @users = $self->universe->geometry->get_users;
        my @possible = grep { $_ =~ /^$fragment/ } @users;
        if ( scalar @possible == 1 ) {
        	my $replace = shift @possible;
        	my $fragment_size = length($fragment);
        	substr( $partial, 
			-$fragment_size, $fragment_size, 
			$replace );
        	$ctrl->SetValue($partial) ;
        	$ctrl->SetInsertionPointEnd;
        }
	return;
	
}

sub accept_command {
    my ($self,$message) = @_;
    $message =~ s|/||;
    # Handle /nick for now so everyone is not Anonymous_$$
    my ($command,$data) = split /\s/ , $message ,2 ;
    
    my $handler = 'command_' . $command;
    if ( $self->can( $handler ) ) {
	$self->$handler($data);
    	
    } else { $self->tell_service( $message ); }
    
}

sub accept_diff {
	my ($self,$message) = @_;
	TRACE("Received diff $message") if DEBUG;

	my $project = $message->project;
	my $file = $message->file;
	my $diff = $message->diff;

	my $current = Padre::Current->document;
	my $editor = Padre::Current->editor;

	my $p_dir = $current->project_dir;
	my $p_name = File::Basename::basename( $p_dir );
	my $p_file = $current->filename;
	$p_file =~ s/^$p_dir//;

	TRACE("Have current doc $p_file, $p_name") if DEBUG;
	return unless $p_dir;
	return unless ( $p_name eq $project );

	# Ignore my own diffs
	if ( $message->from eq $self->service->identity->nickname ) {
		TRACE("Ignore my own diffs") if DEBUG;
		return;
	}

#	Wx::Perl::Dialog::Simple::dialog(
#		sub {},
#		sub {},
#		sub {},
#		{ title => 'Swarm Diff' }
#	);
	TRACE("Patching $file in $project") if DEBUG;
	TRACE("APPLY PATCH \n" . $diff) if DEBUG;
	eval {
		my $result = Text::Patch::patch( $current->text_get , $diff , STYLE=>'Unified' );
		$editor->SetText( $result );
	};

	if ( $@ ) {
		TRACE($@) if DEBUG;
	}
}

sub on_diff_snippet {
	my ($self) = @_;
	my $document = _CURRENT->document or return;
	my $text = $document->text_get;
	my $file = $document->filename;
	unless ( $file ) {
		return;
	}
	my $canonical_file = $file;

	#my $project = $document->project;

	my $project_dir = $document->project_dir;
	my $project_name = File::Basename::basename( $project_dir );
	$canonical_file =~ s/^$project_dir//;

	my $message = Padre::Swarm::Message::Diff->new(
		file        => $canonical_file,
		project     => $project_name,
		project_dir => $project_dir,
		type        => 'diff',
	);

	# Cargo from Padre somewhere ?
	my $external_diff = $self->main->config->external_diff_tool;
	if ( $external_diff ) {
		my $dir = File::Temp::tempdir( CLEANUP => 1 );
		my $filename = File::Spec->catdir( $dir, 'IN_EDITOR' . File::Basename::basename($file) );
		if ( open my $fh, '>', $filename ) {
			print $fh $text;
			CORE::close($fh);
			system( $external_diff, $filename, $file );
		} else {
			TRACE($!) if DEBUG;
		}

		# save current version in a temp directory
		# run the external diff on the original and the launch the
	} else {
		require Text::Diff;
		my $diff = Text::Diff::diff( $file, \$text );
		unless ($diff) {
			#$self->main->errorlist->Append( Wx::gettext("There are no differences\n") );
			return;
		}
		$message->{diff} = $diff;
	}

	$self->tell_service( $message );
	return;
}


## Try to style each identity differently


HSV2RGB: {
	my %vars;
	%vars = ( 
		h=>\my $h,
		s=>\my $s,
		v=>\my $v, 
		t=>\my $t,
		f=>\my $f,
		p=>\my $p,
		q=>\my $q,
	);
	my @matrix = (
		[$vars{v}, $vars{t}, $vars{p}],
		[$vars{q}, $vars{v}, $vars{p}],
		[$vars{p}, $vars{v}, $vars{t}],
		[$vars{p}, $vars{q}, $vars{v}],
		[$vars{t}, $vars{p}, $vars{v}],
		[$vars{v}, $vars{p}, $vars{q}],
	);
	
sub hsv2rgb {
	($h,$s,$v) = @_;
	my $h_index = ( $h / 60 ) % 6;
	
	$f = abs( $h/60 ) - $h_index;
	$p = $v * ( 1 - $s );
	$q = $v * ( 1 - ($f * $s));
	$t = $v * ( 1 - ( 1 - $f ) * $s );
	
	#$q = $v * ( 1 - $s * ($h 
	
	my $result = $matrix[$h_index];
	my @rgb = map { $$_ } @$result;
	return \@rgb;

}

}

use Digest::MD5 qw( md5 );
sub derive_rgb {
    my $string = shift;
    my $digest = md5($string);
    my $word   = substr($digest,0,2);
    my $int    = unpack('%S',$word);
    my $hue = 360 * ( $int / 65535 );
    # TODO - derive differently based on system background colour ?
    my $norm =  hsv2rgb( $hue, 0.8, 0.75 );
    my @rgb =  map { int(255*$_) } @$norm;
    return \@rgb;
}

=pod

=head1 NAME

Padre::Plugin::Swarm::Wx::Chat - Swarm chat console

=head1 DESCRIPTION

Basic chat client for Padre swarm users. 

=head1 COMMANDS

Slash type commands are supported in the chat console

=head2 /nick

Change nickname. 

eg;
     /nick my_name_is
     
=head2 /disco

Send a discovery message to the swarm.

=cut


1;
