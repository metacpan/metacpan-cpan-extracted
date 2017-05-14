package Padre::Plugin::Swarm::Wx::Editor;

use strict;
use warnings;
use Scalar::Util qw( refaddr );
use Padre::Logger;

use Class::XSAccessor
    accessors => {
        editors => 'editors',
        resources=> 'resources',
        transport => 'transport',
    };
    
=pod

=head1 NAME

Padre::Plugin::Swarm::Wx::Editor - Padre editor collaboration

=head1 DESCRIPTION

Hijack the padre editor for the purposes of collaboration. 

=head1 TODO

Shared/Ghost cursors/document

Trap editor cursor movement for common documents and ghost the
remote users' cursors in the local editor.


=head2 Operational transform - concurrent remote edits

Trap the editor CHANGE event and try to transmit quanta
of operations against a document.
Trap received quanta and apply to open documents, adjusting 
local quanta w/ OT if required.

=head2 Code/Commit Review Mode.

Find the current project, find it's VCS if possible and send
the repo details and local diff to the swarm for somebody? to 
respond to.

=cut


sub new {
	my $class = shift;
	my %args  = @_;
	TRACE( "Instanced editor supervisor" ) if DEBUG;
	$args{editors} = {};
	$args{resources} = {};
	return bless \%args, $class ;
}

sub enable {
	my $self = shift;

	foreach my $editor ( $self->plugin->main->editors ) {
	    eval{ $self->editor_enable( $editor, $editor->{Document} ) };
		TRACE( "Failed to enable editor - $@" ) if DEBUG && $@;
	}

}

sub disable {}

sub plugin { Padre::Plugin::Swarm->instance }

sub editor_enable {
	my ($self,$editor,$document) = @_;
	return unless $document && $document->filename;
	
        eval  {
	    $self->transport->send(
		{ 
			type => 'promote', service => 'editor',
			resource => $document->filename
		}
	    );
	
	};
	TRACE( "Failed to send $@" ) if DEBUG;
	
	$self->editors->{ refaddr $editor } = $editor;
	$self->resources->{ $document->filename } = $document;
	
	
	TRACE( "Failed to promote editor open! $@" ) if DEBUG && $@;

}

# TODO - document->filename should be $self->canonical_resource($document); ?

sub editor_disable {
	my ($self,$editor,$document) = @_;
	return unless $document->filename;
	
	eval {
            $self->transport->send( {
                type => 'destroy' , 
                service => 'editor',
                resource => $document->filename}
            );

        delete $self->editors->{refaddr $editor};
        delete $self->resources->{$document->filename};
	};
        TRACE( "Failed to promote editor close! $@" ) if DEBUG && $@;
}


# Swarm event handler
sub on_recv {
	my ($self,$message) = @_;
	my $handler = 'accept_' . $message->{type};
	TRACE( $handler ) if DEBUG;
	if ($self->can($handler)) {
		eval { $self->$handler($message) };
		TRACE( "$handler failed - $@" ) if DEBUG && $@;
	}
	
}
# message handlers

=head1 MESSAGE HANDLERS

For a given message->type

=head2 openme

Accept an openme message and open a new editor window 
with the contents of message->body

=cut


sub accept_openme {
    my ($self,$message) = @_;
    # Skip loopback 
    return if $message->from eq $self->plugin->identity->nickname;
    # Skip anything not addressed to us.
    if ( $message->to ne $self->plugin->identity->nickname ) 
    {
	return;
    }
    
    $self->plugin->main->new_document_from_string( $message->body );
}

=head2 gimme

Give the requested message->resource to the sender in an 'openme'
if the resource matches one of our open documents.

=cut

sub accept_gimme {
	my ($self,$message) = @_;
	
	my $r = $message->{resource};
	$r =~ s/^://;
	TRACE( $message->{from} . ' requests resource ' . $r ) if DEBUG;

	if ( exists $self->resources->{$r} ) {
		my $document = $self->resources->{$r};
		$self->transport->send(
		    { 	type => 'openme',
			service => 'editor',
			body => $document->text_get,
			to   => $message->from ,
		}
		);
	}
	
}

=head1 disco

Respond to discovery messages by transmitting a promote for 
each known resource

=cut


sub accept_disco {
	my ($self,$message) = @_;
	TRACE( $message->{from} . " disco" ) if DEBUG;
	foreach my $doc ( values %{ $self->resources } ) {
		TRACE( "Promoting " . $doc->filename ) if DEBUG;
	    eval  {
		$self->transport->send(
				{ type => 'promote', service => 'editor',
				  resource => $doc->filename }
				);
	    };
	    
	    if ($@) {
			TRACE("Failed to send - $@" ) if DEBUG;
		}
	    
	}
	
}

=head2 runme

=cut


sub NEVER_accept_runme {
    my ($self,$message) = @_;
    # Previously the honour system - now pure evil.
    return if $message->from eq $self->plugin->identity->nickname;
    # Ouch..
    my @result = (eval $message->body);
    
    my $file = ($message->{filename} || 'Unknown');
    if ( $@ ) {
	
	my $reply = "Ran document $file but failed with $@";
       
	    $self->plugin->send(
		 {type => 'openme', to=>$message->from, service=>'editor',
		 body => $reply,}
	    );
        
    }
    else {
	    my $reply = 'Ran document sucessfully - returning '
		. join('', @result );
	    $self->plugin->send(
		{
			type => 'openme',
			service => 'editor',
			to=>$message->from,
			body => $reply,
			filename => $file,
		}
	    );
        
    }
    
}



1;
