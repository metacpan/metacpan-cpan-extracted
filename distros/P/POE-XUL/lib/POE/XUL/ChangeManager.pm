package 
    POE::XUL::ChangeManager;
# $Id: ChangeManager.pm 1566 2010-11-03 03:13:32Z fil $
# Copyright Philip Gwyn 2007-2010.  All rights reserved.
# Based on code Copyright 2003-2004 Ran Eilam. All rights reserved.

#
# POE::XUL::Node and POE::XUL::TextNode will be calling us whenever they
# change attributes or children.
# We keep a list of POE::XUL::State objects that hold all these changes
# so that they may be mirrored in the browser.  To speed things up a lot
# we break POE::XUL::State's encapsulation.
#
# We also maintain a list of all the nodes, available via ->getElementById.
#

use strict;
use warnings;

use Carp qw( carp confess croak cluck );
use HTTP::Status;
use JSON::XS;
use POE::XUL::Logging;
use POE::XUL::State;
use POE::XUL::Encode;
use Scalar::Util qw( weaken blessed );

use constant DEBUG => 0;

our $VERSION = '0.0601';
our $WIN_NAME = 'POEXUL000';

##############################################################
sub new
{
    my( $package ) = @_;

    my $self = bless {
            window      => undef(), 
            current_event => undef(), 
            states      => {},
            nodes       => {},
            destroyed   => [], 
            prepend     => [],
            other_windows => []
        }, $package;

    $self->build_json;
    return $self;
}

##############################################################
sub current_event
{
    my $self = shift;
    my $rv = $self->{current_event};
    $self->{current_event} = $_[0] if $_[0];
    return $rv;
}

##############################################################
sub window
{
    my( $self ) = @_;
    return $self->{window};
}

##############################################################
sub responded
{
    my( $self ) = @_;
    return $self->{responded};
}



##############################################################
sub build_json
{
    my( $self ) = @_;
    my $coder = JSON::XS->new->space_after( 1 );
    $coder->ascii;
    $self->{json_coder} = $coder;
}

##############################################################
sub json_encode
{
    my( $self, $out ) = @_;
    my $json = eval { $self->{json_coder}->encode( $out ) };
    if( $@ ) {
        use Data::Dumper;
        warn "Error encoding JSON: $@\n", Dumper $out;
        my $err = $@;
        $err =~ s/"/\x22/g;
        $json = qq(["ERROR", "", "$err"]);
    }

    DEBUG and 
		do {
			my $foo = $json;
			$foo =~ s/], /],\n/g;
			use bytes;
			xdebug "JSON: $foo\n";
            xdebug "JSON size: ", length( $json ), "\n";
        };

    # $json =~ s/], /],\n/g;    
    return $json;
}

sub poexul_encode
{
    my( $self, $out ) = @_;
    DEBUG and xdebug "length=", 0+@$out;
    return POE::XUL::Encode->encode( $out );
}

##############################################################
sub dispose
{
    my( $self ) = @_;

    foreach my $N ( @{ $self->{destroyed} }, 
                        values %{ $self->{nodes} }, 
                        values %{ $self->{states} } ) {
        next unless defined $N and blessed $N and $N->can( 'dispose' );
        $N->dispose;
    }
    $self->{nodes}         = {};
    $self->{destroyed}     = [];
    $self->{states}        = {};
	$self->{prepend}       = [];
	$self->{other_windowx} = [];
}

##############################################################
# Get all changes, send to the browser
sub flush 
{
	my( $self ) = @_;
	local $_;
    # TODO: we could cut down on trafic if we don't flush deleted nodes
    # that are children of a deleted parent

    # XXX: How to prevent the flushing of deleted Window() and children?
	my @out = @{ $self->{prepend} };                        # our stuff
    my @more = (
                map( { $_->flush } @{$self->{destroyed}} ), # old stuff
                $self->flush_node( $self->{window} )        # new/changed stuff
              );
    if( @more ) {
        push @out, [ 'for', '' ], @more;
    }

    foreach my $win ( @{ $self->{other_windows} || [] } ) {
        push @out, [ 'for', $win->id ];
        push @out, $self->flush_node( $win );
    }
	$self->{destroyed} = [];
	$self->{prepend} = [];
	return \@out;
}

##############################################################
sub flush_node 
{
	my ($self, $node) = @_;
    return unless $node and blessed $node;
    my $state = $self->node_state( $node );
    return unless $state and blessed $state;

    my @defer = $state->as_deferred_command;
	my @out = $state->flush;
    unless( $state->{is_framify} ) {
        push @out, $self->flush_node( $_ ) foreach $node->children;
    }
    push @out, @defer;
	return @out;
}

##############################################################
sub node_state 
{
	my( $self, $node ) = @_;

	return $self->{states}{"$node"} if $self->{states}{"$node"};

    my $is_tn = UNIVERSAL::isa($node, 'POE::XUL::TextNode');

    if( DEBUG ) {
        confess "Not a node: [$node]" unless 
            UNIVERSAL::isa($node, 'POE::XUL::Node') or $is_tn;
    }

    my $state = POE::XUL::State->new( $node );
    $self->{states}{ "$node" } = $state;

    DEBUG and 
        xdebug "$self Created state ", $state->id, " for $node\n";

    $state->{is_textnode} = !! $is_tn;

    $self->register_node( $state->id, $node );

    return $state;
}

##############################################################
sub register_window
{
    my( $self, $node ) = @_;
    if( $self->{window} ) {
        DEBUG and xwarn "register_window $node";
        push @{ $self->{other_windows} }, $node;
    }
    else {
        $self->{window} = $node;
    }
    my $server = $POE::XUL::Application::server;
    if( $server ) {
        $server->register_window( $node );
    }
}

##############################################################
sub unregister_window
{
    my( $self, $node ) = @_;
    if( $node == $self->{window} ) {
        confess "You aren't allowed to unregister the main window!\n";
    }
    DEBUG and xwarn "unregister_window $node";
    my @new;
    foreach my $win ( @{ $self->{other_windows}||[] } ) {
        next if $win == $node;
        push @new, $win;
    }

    $self->{other_windows} = \@new;
    return;
}

##############################################################
sub register_node
{
    my( $self, $id, $node ) = @_;
    
    confess "Why you trying to be funny with me?" unless $id;
    if( $self->{nodes}{$id} and not $self->{nodes}{$id}{disposed} ) {
        confess "I already have a node id=$id";
    }
    confess "Why you trying to be funny with me?" unless $node;
    # xwarn "register $id is $node" if $id eq 'LIST_PREQ-PR_LAST_';
    $self->{nodes}{ $id } = $node;
    weaken( $self->{nodes}{ $id } );
    return;
}

##############################################################
sub unregister_node
{
    my( $self, $id, $node ) = @_;
    # 2009/04 Perl's DESTROY behaviour can be random; if user created
    # a new node w/ the same ID, we could see the second register before
    # the DESTROY.  So we make sure we are unregistering the right node.
    if( ($self->{nodes}{$id}||'') ne $node ) {
        DEBUG and xwarn "Out of order unregister of $id";
        return;
    }
    delete $self->{nodes}{ $id };
    # 2007/12 do NOT $node->dispose here.  unregister_node is also
    # used by ->after_set_attribute()

    # xwarn "unregister $id is $node" if $id eq 'LIST_PREQ-PR_LAST_';
    return;
}

##############################################################
sub getElementById
{
    my( $self, $id ) = @_;
    return $self->{nodes}{ $id };
}

##############################################################
# We need for the node to have the same ID as the state
sub before_creation
{
    my( $self, $node ) = @_;
    my $state = $self->node_state( $node );

    return if $node->getAttribute( 'id' );
    warn "$node has no ID";
    $node->setAttribute( id => $state->{id} );
}



##############################################################
sub after_destroy
{
    my( $self, $node ) = @_;
    # Don't use state_node, as it will create the state
    my $state = delete $self->{states}{"$node"};
    my $id;
    if( $state ) {
        $id = $state->{id};
        delete $self->{states}{ $state->{style} }
                                if $state->{style};
    }
    elsif( $node->can( 'id' ) ) {
        $id = $node->id;
    }
    return unless $id;
    $self->unregister_node( $id, $node );
}

##############################################################
sub after_set_attribute
{
    my( $self, $node, $key, $value ) = @_;
    return if $self->{ignorechanges};
	my $state = $self->node_state($node);

	if ($key eq 'tag') { 
        $state->{tag} = $value; 
        $self->register_window( $node ) if $node->is_window;
    }
	elsif( $key eq 'id' ) {
        $self->_set_id( $node, $key, $value, $state );

    }
    elsif( $key eq 'src' or $key eq 'href' or $key eq 'datasources' ) {
        $self->_set_uri( $node, $key, $value, $state );
    }
    else {
        $state->set_attribute($key, $value);
        # TODO: track exclusive things like focus()
    }

}

sub _set_id
{
    my( $self, $node, $key, $value, $state ) = @_;

    return if $state->{id} eq $value;
    DEBUG and 
        xdebug "node $state->{id} is now $value";
    my $old_id = $state->{id};

    $state->set_attribute($key, $value);

    $self->unregister_node( $state->{id}, $node );
    $state->{id} = $value;
    $self->register_node( $state->{id}, $node );
}

sub _set_uri
{
    my( $self, $node, $key, $value, $state ) = @_;

    my $hidden = "hidden-$key";
    my $cb;
    if( blessed $value ) {
        unless( $value->can( 'mime_type' ) and 
                ( $value->can( 'as_string' ) or $value->can( 'as_xml' ) ) ) {
            croak "$key object must implement as_string or as_xml, as well as mime_type methods";
        }
        DEBUG and xwarn "Callback to object $value";
        $cb = $hidden;
    }
    elsif( ref $value ) {
        # coderef or array ref for a callback
        $cb = $hidden;
        if( 'ARRAY' eq ref $value ) {
            if( 2 == @$value and 'HASH' eq ref $value->[-1] ) {
                $cb = { attribute => $cb, 
                        extra => pop @$value
                      };
            }
            if( 1 == @$value ) {
                unshift @$value, 
                    $POE::Kernel::poe_kernel->get_active_session->ID;
            }
        }
    }
    # binary data
    elsif( $value !~ m,^(((ftp|file|data|https?):)|/), ) { # not a URI
        if( 30_000 < length $value or not $node->getAttribute( 'content-type' )) {    
            # Don't use a data: url if 
            # - the data is too long
            # - we don't have a content-type attribute
            # In the latter case, we hope we'll have one, once we get to the
            # callback
            $cb = $hidden;
        }
        else {
            my $ct = $node->getAttribute( 'content-type' );
            my $uri = URI->new( "data:" );
            $uri->media_type( $ct );
            $uri->data( $value );
            $state->set_attribute( $key, $uri->as_string );
            return;
        }
    }
    else {
        $state->set_attribute($key, $value);
        return;
    }


    # Setting a callback attribute cases Runner to set the value of 
    # the attribute to an URL that does a Callback event 
    # (see commandCallback).
    # This then calls handle_Callback (see below) or the coderef/event
    # defined in $value
    # $cb must be either a value (which gets in attribute when it comes back)
    # or a hashref { extra=>{}, attribute=>'' }
    $state->set_attribute( callback => $cb );
    local $self->{ignorechanges} = 1;   # don't send to browser
    $node->setAttribute( $hidden, $value );

}


##############################################################
sub after_remove_attribute
{
    my( $self, $node, $key ) = @_;
    return if $self->{ignorechanges};
    my $state = $self->node_state( $node );

    delete $self->{states}{ $state->{style} } if $key eq 'style' and
                                                 $state->{style};
    $state->remove_attribute( $key );
}

##############################################################
sub after_method_call
{
    my( $self, $node, $key, $args ) = @_;
    return if $self->{ignorechanges};
	my $state = $self->node_state($node);

    $state->method_call($key, $args);
}



##############################################################
sub after_new_style
{
    my( $self, $node ) = @_;
    my $state = $self->node_state($node);
    delete $self->{states}{ $state->{style} }
                if $state->{style};
    my $style = $node->get_style;
    $state->{style} = 0+$style;
    $self->{states}{ $state->{style} } = $state;
    $state->set_attribute( style => "$style" );
    return;
}

##############################################################
sub after_style_change
{
    my( $self, $style, $property, $value ) = @_;
    my $state = $self->{states}{ 0+$style };
    $state->style_change( $property, $value );
}

##############################################################
# when node added, set parent node state id on child node state
sub after__add_child_at_index
{
    my( $self, $parent, $child, $index ) = @_;

    my $child_state = $self->node_state( $child );
    $child_state->{parent} = $self->node_state( $parent );
    weaken $child_state->{parent};
    if( defined $child_state->{trueindex} ) {
        $child_state->{trueindex} = $index;
    }
    else {
        $child_state->{index} = $index;
    }

    return unless @{$child->{children} || []};

    my $n = 0;
    foreach my $subchild ( @{ $child->{children} } ) {
        $self->after__add_child_at_index( $child, $subchild, $n );
        $n++;
    }
}

sub set_trueindex
{
    my( $self, $parent, $child, $trueindex ) = @_;
    my $child_state = $self->node_state( $child );
    # Ignore trueindex for now...  It breaks to many things
    $child_state->{index} = $trueindex;
}

##############################################################
# when node destroyed, update state using set_destoyed
sub before_remove_child
{
    my( $self, $parent, $child, $index ) = @_;
#	my $child       = $parent->_compute_child_and_index($context->params->[1]);
    # return unless $child;
    Carp::croak "Why no index" unless defined $index;
    my $child_state = $self->node_state($child);
    $child_state->is_destroyed( $parent, $index );
    push @{$self->{destroyed}}, $child_state;

    delete $self->{states}{ "$child" };
    delete $self->{states}{ $child_state->{style} }
                            if $child_state->{style};
    $self->unregister_node( $child_state->{id}, $child );
}

##############################################################
sub after_cdata_change
{
    my( $self, $node ) = @_;
    my $state = $self->node_state( $node );
    $state->{cdata} = $node->{data};
    $state->{is_new} = 1;
}



##############################################################
# So that we can detect changes between requests
sub request_start
{
    my( $self, $event ) = @_;
    $self->{current_event} = $event;
    $self->{responded} = 0;
}

sub request_done
{
    my( $self ) = @_;
    $self->{responded} = 1;
    my $event = delete $self->{current_event};
    $event->dispose if $event;
    undef( $event );

#    use Devel::Cycle;
#    find_cycle( $self );
}

##############################################################
sub wrapped_error
{
    my( $self, $string ) = @_;
    if( $self->{current_event} ) {
        # xwarn "wrapped with $self->{current_event}";
        $self->error_response( $self->{current_event}->response, $string );
    }
    else {
        # TODO: what to do with errors that happen between events?
        xlog "Error between events: $string";
    }
}

##############################################################
sub error_response
{
    my( $self, $resp, $string ) = @_;
    xlog "error_response $string";
    # confess "ERROR $string";
    return $self->cooked_response( $resp, [[ 'ERROR', '', $string]] );
}

##############################################################
sub response
{
    my( $self, $resp ) = @_;
    my $out = $self->flush;
    # xwarn "response = ", 0+@$out;
    $self->cooked_response( $resp, $out );
}

##############################################################
sub cooked_response
{
    my( $self, $resp, $out ) = @_;

    if( $self->{responded} ) {
        confess "Already responded";
        xcarp "Already responded";
        return;
    }
    confess "I need a response" unless $resp;

    my $data;
    unless( ref $out ) {
        $data = $out;
    }
    elsif( 0 ) {	# XXX config
        $resp->content_type( POE::XUL::Encode->content_type ); 
        $data = $self->poexul_encode( $out );
    }
    else {
        $resp->content_type( 'application/json' ); #; charset=UTF-8' );
        $data = $self->json_encode( $out );
    }
    DEBUG and 
        xdebug "Response=$data";
    $self->__response( $resp, $data );
}


##############################################################
sub xul_response
{
    my( $self, $resp, $xul ) = @_;

    $resp->content_type( 'application/vnd.mozilla.xul+xml' );
    $self->__response( $resp, $xul );
}

##############################################################
sub data_response
{
    my( $self, $resp, $data ) = @_;
    # TODO: should we check if there is anything to be flushed?
    # Idealy, we'd do it non-destructively, so that we could warn but
    # the changes would wait for next request
    $self->__response( $resp, $data );
}

##############################################################
## This should be moved to Controler
sub __response
{
    my( $self, $resp, $content ) = @_;

    
    do {
        # HTTP exptects content-length to be number of octets, not chars
        # The UTF-8 that JSON::XS is producing was screwing up length()
        use bytes;
        $resp->content_length( length $content );
    };
    $resp->content( $content );
    $resp->code( RC_OK );
    $resp->continue();          # but only if we've stoped!

    $self->request_done;
}



##############################################################
sub SID
{
    my( $self, $SID ) = @_;
    push @{ $self->{ prepend } }, $self->build_SID( $SID );
}


##############################################################
sub build_SID
{
    my( $self, $SID ) = @_;
    return POE::XUL::State->make_command_SID( $SID );
}

##############################################################
# Send a boot message to the client
sub Boot
{
    my( $self, $msg ) = @_;
    push @{ $self->{prepend} }, POE::XUL::State->make_command_boot( $msg );
}








##############################################################
# Side-effects for a given event
##############################################################
sub handle_Click 
{
	my( $self, $event ) = @_;
    return;
}

##############################################################
# A textbox was changed
# Uses source, value
sub handle_Change 
{
	my( $self, $event ) = @_;
    local $self->{ignorechanges} = 1;
    DEBUG and 
        xdebug "Change value=", $event->value, " source=", $event->source;
	$event->source->setAttribute( value=> $event->value );
}

##############################################################
sub handle_BoxClick 
{
	my( $self, $event ) = @_;
    local $self->{ignorechanges} = 1;
	my $checked = $event->checked;

    DEBUG and xdebug "Click event=$event source=", $event->source->id;
	# $checked = defined $checked && $checked eq 'true'? 1: 0;
	$event->checked( $checked );
	$event->source->checked( $checked );
}

##############################################################
# A radio button was clicked
# Uses : source, selectedId
sub handle_RadioClick 
{
	my( $self, $event ) = @_;
    local $self->{ignorechanges} = 1;
	my $selectedId = $event->selectedId;

    DEBUG and 
        xdebug "RadioClick source=", 
                   ($event->source->id||$event->source), 
                    " selectedId=$selectedId";
    my $radiogroup = $event->source;
    my $radio = $self->getElementById( $selectedId );

    die "Can't find element $selectedId for RadioClick"
            unless $radio;

    $event->event( 'Click' );
    foreach my $C ( $radiogroup->children ) {
        if( $C == $radio ) {
            $C->setAttribute( 'selected', 1 );
            DEBUG and xdebug "Found $selectedId\n";
            # If there was a Click handler on the Radio, we 
            # revert to the former behaviour of running that handler
            # xdebug "Going to C=$C id=", $C->id;
            $event->bubble_to( $radiogroup );
            $event->__source_id( $C->id );
        }
        elsif( $C->selected ) {
            $C->removeAttribute( 'selected' );
        }
    }
}

##############################################################
# A list item was selected
# Uses: source, selectedIndex, value
sub handle_Select 
{
	my( $self, $event ) = @_;
    local $self->{ignorechanges} = 1;

    my $menulist = $event->source;

    if( $menulist->tagName eq 'tree' ) {
        return $self->handle_TreeSelect( $event );
    }

    my $I = $event->selectedIndex;
                              # selecting text in a textbox!
    return unless defined $I and $I ne 'undefined'; 
    my $oI = $menulist->selectedIndex;

    DEBUG and 
        xdebug "Select was=$oI, now=$I";

    if( defined $I and $I == -1 ) {
        xdebug "Change Combo I=$I value=", $event->value;
        $menulist->selectedIndex( $I );
        $menulist->value( $event->value );
        return;
    }
    elsif( $menulist->editable and $oI and $oI == -1 ) {
        xdebug "Change Combo remove 'value'";
        $menulist->removeAttribute( 'value' );
    }

    $self->Select_choose( $event, $oI, 'selected', 0 );
    $menulist->selectedIndex( $I );
    my $item = $self->Select_choose( $event, $I, 'selected', 1 );

    if( $item ) {
        xdebug "Select $I.label=", $item->label;
        # The event should go to the item first, then the "parent"
        $event->bubble_to( $event->source );
        $event->__source_id( $item->id );
        # $menulist->value( $item->value );
    }
}


##############################################################
# Turn one menuitem on/off
sub Select_choose
{
    my( $self, $event, $I, $att, $value ) = @_;
    my $list = $event->source;
    return unless $list;
    return unless $list->first_child;
    return unless defined $I;

    my $item = $list->getItemAtIndex( $I );
    return unless $item;

    local $self->{ignorechanges} = 0;
    if( $value ) {
        $item->setAttribute( $att, $value );
    }
    else {
        $item->removeAttribute( $att );
    }
    return $item;
}

##############################################################
# User picked a colour
sub handle_Pick 
{
	my( $self, $event ) = @_;
    local $self->{ignorechanges} = 1;
	$event->source->color($self->color);
}

##############################################################
# Image src="" callbackup
sub handle_Callback
{
	my( $self, $event ) = @_;
    my $node = $event->source;
    my $key = $event->attribute;
    # xdebug( "Callback $key" );
    my $cb = $node->getAttribute( $key );
    if( blessed $cb ) {
        DEBUG and xwarn "Callback with $cb";
        $event->response->content_type( 
                                $cb->mime_type
                            );
        if( $cb->can( 'as_xml' ) ) {
            $event->data_response( $cb->as_xml );
        }
        else {
            $event->data_response( $cb->as_string );
        }
    }
    elsif( ref $cb ) {
        if( 'CODE' eq ref $cb ) {
            $cb->( $node, $event );
        }
        else {
            # xdebug( join '/', @$cb );
            $POE::Kernel::poe_kernel->call( @$cb, $node, $event );
        }
    }
    else {
        $event->response->content_type( 
                                $node->getAttribute( 'content-type' ) 
                            );
        $event->data_response( $cb );
    }
}

##############################################################
# A row of a tree was selected
# Uses: source, selectedIndex, value
sub handle_TreeSelect
{
	my( $self, $event ) = @_;

    local $self->{ignorechanges} = 1;

    my $tree = $event->source;
    my $rowN = $event->selectedIndex;

    # Handle user sorting of RDF trees
    if( $event->primary_col ) {
        xdebug "primary_col=", $event->primary_col;
        xdebug "primary_text=", $event->primary_text;
        my $rdf = $tree->getAttribute( 'hidden-datasources' );
        xdebug "rdf: $rdf";
        if( blessed( $rdf ) and $rdf->can( 'index_of' ) ) {
            $rowN = $rdf->index_of( $event->primary_col, $event->primary_text );
            xdebug "true index is $rowN";
            $tree->selectedIndex( $rowN );
            $event->selectedIndex( $rowN );
            return;
        }
    }

    $tree->selectedIndex( $rowN );

    # Find the xul:treechildren node
    my $treechildren;
    foreach my $node ( $tree->children ) {
        next unless $node->tagName eq 'treechildren';
        $treechildren = $node;
        last;
    }

    unless( $treechildren ) {
        # This happens when a tree has a datasource, like RDF
        DEBUG and xdebug "Select on a tree w/o treechildren";
        return;
    }

    DEBUG and
        xdebug "treechildren=$treechildren";
    
    # Find the row nodes.  This could be xul:treeitem or xul::treerow
    my @rows;
    foreach my $treeitem ( $treechildren->children ) {
        my $first = $treeitem->first_child;
        if( $first and $first->tagName eq 'treerow' ) {
            push @rows, $first;
        }
        else {
            push @rows, $treeitem;
        }
    }
    DEBUG and
        xdebug "Found ", 0+@rows, " rows";

    for( my $r = 0 ; $r<=$#rows ; $r++ ) {
        my $prop = $rows[$r]->properties;
        if( $r == $rowN ) {
            $prop =~ s/\s*selected\s*//g;
            if( $prop ) { $prop .= ' selected' }
            else        { $prop = 'seelected' }
            DEBUG and xdebug "Row $r properties=$prop";
            $rows[$r]->properties( $prop );
            $event->bubble_to( $tree );
            $event->__source_id( $rows[$r]->id );
        }
        elsif( $prop =~ s/\s*selected\s*//g ) {
            DEBUG and xdebug "Row $r properties=$prop";
            $rows[$r]->properties( $prop||'' );
        }
    }

    return;
}






##############################################################
sub Prepend
{
    my( $self, $cmd ) = @_;
    push @{ $self->{prepend} }, $cmd;
    return 0+@{ $self->{prepend} };
}

##############################################################
sub flush_to_prepend
{
    my( $self ) = @_;
    my $out = $self->flush;
    return unless @$out;
    push @{ $self->{prepend} }, @$out;
    return 0+@{ $self->{prepend} };
}

##############################################################
sub timeslice
{
    my( $self ) = @_;
    $self->Prepend( [ 'timeslice' ] );
}

##############################################################
sub popup_window
{
    my( $self, $name, $features ) = @_;
    $name     ||= $WIN_NAME++;
    $features ||= {};
    croak "Features must be a hashref" unless 'HASH' eq ref $features;
    $self->Prepend( [ 'popup_window', $name, $features ] );
    return $name;
}

##############################################################
sub close_window
{
    my( $self, $name ) = @_;
    $self->Prepend( [ 'close_window', $name ] );
}

##############################################################
# Send some instructions to Runner.js.  Or other control of the CM
sub instruction
{
    my( $self, $inst ) = @_;

    my( $op, @param );
    if( ref $inst ) {
        ( $op, @param ) = @$inst;
    }
    else {
        $op = $inst;
    }

    if( $op eq 'flush' ) {                  # flush changes to output buffer
        return $self->flush_to_prepend;
    }
    elsif( $op eq 'empty' ) {               # empty all changes
        return $self->flush;
    }
    elsif( $op eq 'timeslice' ) {           # give up a timeslice
        return $self->timeslice;
    }
    elsif( $op eq 'popup_window' ) {
        return $self->popup_window( @param );
    }
    elsif( $op eq 'close_window' ) {
        return $self->close_window( @param );
    }
    else {
        die "Unknown instruction: $op";
    }
}

1;

__END__

=head1 NAME

POE::XUL::ChangeManager - Keep POE::XUL in sync with the browser DOM

=head1 SYNOPSIS

Not used directly.  See L<POE::XUL> and L<POE::XUL::Event>.

=head1 DESCRIPTION

The ChangeManager is responsible for tracking and sending all changes to a
L<POE::XUL::Node> to its corresponding DOM element.  It also handles any
side-effects of a DOM event that was sent from the browser.

There is only one ChangeManager per application.  The application never
accesses the ChangeManager directly, but rather by manipulating
L<POE::XUL::Node>.  

Because there may be multiple application instances within a given process,
the link between L<POE::XUL::Node> and the ChangeManager is handled by
L<POE::XUL::Event>.  Changes to a node B<must> happen within
L<POE::XUL::Event/wrap>.  This is done for you in the initial POE event.  It
B<must> be done explicitly if you chain the initial POE event to furthur POE
events.

=head1 METHODS

There is only one method that will be useful for application writers:

=head2 instruction

    pxInstructions( @instructions );
    $CM->instruction( $inst );
    $CM->instruction( [ $inst, @params ] );

Send instructions to the javascript client library.  Instructions are a HACK
to quickly work around XUL and/or POE::XUL::Node limitations.

C<$inst> may be simply an instruction name, or an arrayref, the first
element of which is the instruction name.

Current instructions are:

=over 4

=item empty

Empties all pending changes, returns the arrayref of those changes.

=item flush

All currently known commands are put into the output buffer.  Combined with
C<timeslice>, it allows some control over the order in which commands are
executed.

=item timeslice

Tells the javascript client library to give up a C<timeslice>.  The idea is
to give the browser time to I<render> any new XBL.  Because it is impossible
to find out when all XBL has finished rendering, the C<timeslice> is handled
by pausing for 5 milliseconds.

To be very useful, you should preceed this with a L</flush>.

=item popup_window

    pxInstruction( [ popup_window => $id, $features ] );

PLEASE USE L<POE::XUL::Window/open> INSTEAD.

Tell the client library to create a new window.  The new window's name will
be C<$id>.  The new window will be created with the features defined in
C<$features>: 
C<width>, 
C<height>, 
C<location>,
C<menubar>,
C<toolbar>,
C<status>,
C<scrollbars>.
The following features are always C<yes>:
C<resizable>,
C<dependent>.
See L<http://developer.mozilla.org/en/docs/DOM:window.open> for an explanation
of what they mean.

Once the window is opened, it will load C</popup.xul?app=$APP&SID=$SID> (where
C<$APP> is the current application and C<$SID> is the session ID of the
current application instance).  C<popup.xul> will then send a C<connect>
event.  See L<POE::XUL/connect>.



=item close_window

    pxInstruction( [ close_window => $id ] );

PLEASE USE L<POE::XUL::Window/close> INSTEAD.

Closes the window C<$id>.  This will provoke a C<disconnect> event.
See L<POE::XUL/disconnect>.


=back


=head1 AUTHOR

Philip Gwyn E<lt>gwyn-at-cpan.orgE<gt>

=head1 CREDITS

Based on XUL::Node by Ran Eilam.

=head1 COPYRIGHT AND LICENSE

Copyright 2007-2010 by Philip Gwyn.  All rights reserved;

Copyright 2003-2004 Ran Eilam. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=head1 SEE ALSO

perl(1), L<POE::XUL>, L<POE::XUL::Event>.

=cut



