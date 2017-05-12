package POE::XUL::Node;
# $Id: Node.pm 1566 2010-11-03 03:13:32Z fil $
# Copyright Philip Gwyn 2007-2010.  All rights reserved.
# Based on code Copyright 2003-2004 Ran Eilam. All rights reserved.



use strict;
use warnings;
use Carp;
use Scalar::Util qw( blessed );
use POE::XUL::Constants;
use POE::XUL::TextNode;
use POE::XUL::CDATA;
use POE::XUL::Style;
use POE::XUL::Window;
use Storable qw( dclone );
use HTML::Entities qw( encode_entities_numeric );

use constant DEBUG => 0;

our $VERSION = '0.0601';
our $CM;

my $ID = 0;

my @XUL_ELEMENTS = qw(
      ArrowScrollBox Box Button Caption CheckBox ColorPicker Column Columns
      Deck Description Grid Grippy GroupBox HBox Image Label ListBox
      ListCell ListCol ListCols ListHead ListHeader ListItem Menu MenuBar
      MenuItem MenuList MenuPopup MenuSeparator ProgressMeter Radio
      RadioGroup Row Rows ScrollBar Seperator Spacer Splitter Stack StatusBar
      StatusBarPanel Tab TabBox TabPanel TabPanels Tabs TextBox ToolBar
      ToolBarButton ToolBarSeperator ToolBox VBox Window

      Tree TreeChildren TreeItem TreeRow TreeCols TreeCol TreeCell
      TreeSeparator Template Rule 
);

# my %XUL_ELEMENTS = map { $_ => 1 } @XUL_ELEMENTS;

my @HTML_ELEMENTS = qw( 
    HTML_Pre HTML_H1 HTML_H2 HTML_H3 HTML_H4 HTML_A HTML_Div HTML_Br HTML_Span
);

my @DEFAULT_LABEL = 

my %DEFAULT_ATTRIBUTE = map { $_ => 'label' } qw( 
        caption button menuitem radio listitem
    );
 

my @OTHER_ELEMENTS = qw(
    Script Boot RawCmd pxInstructions
);

my %LOGICAL_ATTS = ( 
        selected => 1, 
        disabled => 1, 
        autoFill => 1,
        autocheck => 1,
        editable => 1,
#        checked => 1
    );

# creating --------------------------------------------------------------------

##############################################################
sub import 
{
    my( $package ) = @_;
	my $caller = caller();
	no strict 'refs';
	# export factory methods for each xul element type
	foreach my $sub ( @XUL_ELEMENTS, @HTML_ELEMENTS ) {
        my $tag = lc $sub;
        $tag =~ s/^html_/html:/;
        # delete ${"${caller}::$other"};
		*{"${caller}::$sub"} = sub
			{ return scalar $package->new(tag => $tag, @_) };
	}
	foreach my $other (@OTHER_ELEMENTS) {
        # delete ${"${caller}::$other"}
        *{"${caller}::$other"} = sub
            { return scalar $package->can("$other")->( $package, @_ ) };
    }

	# export the xul element constants
	foreach my $constant_name (@POE::XUL::Node::Constants::EXPORT) { 
        *{"${$caller}::$constant_name"} = *{"$constant_name"} 
    }
}

##############################################################
sub new 
{
	my ($class, @params) = @_;

	my $self;
    if( ($params[0]||'') eq 'tag' and lc($params[1]||'') eq 'window' ) {
        $self = bless {attributes => {}, children => [], events => {}}, 
                        'POE::XUL::Window';
    } else {
        $self = bless {attributes => {}, children => [], events => {}}, $class;
    }

    my $id;
    ( $id, @params ) = $self->__find_id( @params );

    $id = $self->__auto_id( $id );
    $CM->before_creation( $self ) if $CM;

    if( DEBUG and not $CM and $INC{'POE/XUL/ChangeManager.pm'} ) {
        Carp::cluck "Building a POE::XUL::Node, but no ChangeManager avaiable";
    }

	while (my $param = shift @params) {
		if( ref $param ) {
            $self->appendChild( $param );
        }
		elsif( $param =~ /\s/ or 0==@params ) {
            $self->defaultChild( $param );
        }
		elsif ($param eq 'textNode' ) { 
            $self->appendChild( shift @params );
        }
		elsif ($param =~ /^[a-z]/) { 
            $self->setAttribute( $param => shift @params );
        }
		elsif ($param =~ /^[A-Z]/) { 
            $self->attach($param => shift @params );
        }
		else { 
            croak "unrecognized param: [$param]" 
        }
	}

	return $self;
}

##############################################################
# Scan ->new()'s parameters, trying to pull out an ID
sub __find_id
{
    my( $self, @params ) = @_;
    my( $id, @out );
	while (my $param = shift @params) {
		if( ref $param or $param =~ /\s/ or 0==@params ) {
            push @out, $param;
        }
		else {
            if( $param eq 'id' ) { 
                $id = shift @params;
                next;
            }
            push @out, $param, shift @params;
        }
	}
    return ( $id, @out );
}

##############################################################
sub Script {
    my $class = shift;
    # warn "class=$class";
    # warn "script=", join "\n", @_;
    my $cdata = POE::XUL::CDATA->new( join "\n", @_ );
    return $class->new( tag=>'script', type=>'text/javascript', $cdata );
}

##############################################################
# Boot message
sub Boot
{
    my( $class, $msg ) = @_;
    if( $CM ) {
        $CM->Boot( $msg );
    }
    my $server = $POE::XUL::Application::server;
    if( $server ) {
        $server->Boot( $msg );
    }
    return;
}

##############################################################
# Send a raw command to Runner.js
sub RawCmd
{
    my( $class, $cmd ) = @_;
    if( $CM ) {
        $CM->Prepend( $cmd );
    }
    return;
}

##############################################################
# Instructions to Runner.js, via ChangeManager
sub pxInstructions
{
    my( $self, @inst ) = @_;
    unless( $CM ) {
        unless( $INC{ 'Test/More.pm' } ) {
            # carp "There is no ChangeManager.  Instructions ignored.";
        }
        return;
    }

    my $rv;
    foreach my $inst ( @inst ) {
        $rv = $CM->instruction( $inst );
    }
    return $rv;
}


##############################################################
## Assign an ID as soon as possible, so that the CM and State
## will see it
sub __auto_id
{
    my( $self, $id ) = @_;
    unless( $id ) {
        $id = "PXN$ID";
        $ID++;
        $self->{default_id} = $id;
    }
    $self->{attributes}{id} = $id;
    return $id;
}

##############################################################
sub build_text_node
{
    my( $self, $text ) = @_;
    my $textnode = POE::XUL::TextNode->new;

    $textnode->nodeValue( $text );
    return $textnode;
}
*createTextNode = \&build_text_node;


##############################################################
sub textNode
{
    my( $self, $text ) = @_;

    # Find the last text node
    my $old;
    foreach my $C ( $self->children ) {
        next unless $C->isa( 'POE::XUL::TextNode' );
        $old = $C;
    }

    unless( 2==@_ ) {
        return unless $old;
        return $old->nodeValue;
    }

    if( $old and ref $text ) {
        $self->replaceChild( $text, $old );
        return $text->nodeValue if blessed $text;
        return $text;
    }
    elsif( $old ) {
        return $old->nodeValue( $text );
    }
    else {
        return $self->appendChild( $text )->nodeValue;
    }
}


##############################################################
sub getItemAtIndex
{
    my( $self, $index ) = @_;
    return if not defined $index or $index < 0;

    if( $self->tag eq 'menulist' ) {
        $self = $self->firstChild;
    }

    my $N = 0;
    foreach my $I ( $self->children ) {
        my $t = $I->tag;
        next unless $t eq 'listitem' or $t eq 'menuitem';
        return $I if $N == $index;
        $N++;
    }
    return;
}
*get_item = \&getItemAtIndex;

# attribute-like method invocation --------------------------------------------
sub mk_method
{
    my( $name ) = @_;
    return sub { 
            my $self = shift;
            return unless $CM;
            $CM->after_method_call( $self, $name, [@_] );
        };
}
*scrollTo      = mk_method( 'scrollTo' );
*scrollBy      = mk_method( 'scrollBy' );
*scrollToLine  = mk_method( 'scrollToLine' );
*scrollByLine  = mk_method( 'scrollByLine' );
*scrollByPage  = mk_method( 'scrollByPage' );
*scrollByIndex = mk_method( 'scrollByIndex' );


# attribute handling ----------------------------------------------------------

##############################################################
sub attributes    
{ 
    my( $self ) = @_;
    my $ret = dclone $self->{attributes};
    return %$ret if wantarray;
    return $ret;
}

##############################################################
sub get_attribute 
{ 
    my( $self, $key ) = @_;
    if( $LOGICAL_ATTS{ $key } ) {
        return unless $self->{attributes}{$key};
        # 'false' is still true, in Perl
        return if $self->{attributes}{$key} eq 'false';
    }

    return $self->style if $key eq 'style';
    return $self->{attributes}{$key};
}
*getAttribute = \&get_attribute;


##############################################################
sub set_attribute 
{
    my( $self, $key, $value ) = @_;
    return $self->style( $value ) if $key eq 'style';
    if( $key eq 'tag' ) {
        $value = lc $value;
        $value =~ s/^html_/html:/;
        $value =~ s/^xul://;
    }

    if( $LOGICAL_ATTS{ $key } ) {
        if( ! $value or $value eq 'false' ) {
            $self->remove_attribute( $key );
            return;
            # remove_attribute() informs the CM, we don't have to
        }
        # 2008-09 : the following is a tad silly...
        $value = $value ? 'true' : 'false';        
    }

    if( DEBUG and $key eq 'id' ) {
        carp $self->id, ".$key=$value";
    }

    if( $key eq 'value' ) { # and $self->tag eq 'menulist' ) {
            # Carp::cluck( $self->tag . ".value=$value" );
    }

    $self->{attributes}{$key} = $value;
    $CM->after_set_attribute( $self, $key, $value ) if $CM;
    return $value;
}
*setAttribute = \&set_attribute;

##############################################################
sub remove_attribute 
{ 
    my( $self, $key ) = @_;
#    if( $key eq 'value' and $self->tag eq 'menulist' ) {
#        Carp::cluck( $self->tag . ".removeAttribute('value')" );
#    }
    croak "You may not remove the tag attribute" if $key eq 'tag';
    $CM->after_remove_attribute( $self, $key ) if $CM;
    delete $self->{attributes}{ $key }; 
}
*removeAttribute = \&remove_attribute;

##############################################################
sub is_window { 0 }

##############################################################
*id = __mk_accessor( 'id' );
*tagName = __mk_accessor( 'tag' );
#*textNode = __mk_accessor( 'textNode' );

sub __mk_accessor
{
    my( $tag ) = @_;
    return sub {
        my( $self, $value ) = @_;
        if( @_ == 2 ) {
            return $self->setAttribute( $tag, $value );
        }
        else {
            return $self->{attributes}{$tag};
        }
    }
}

##############################################################
sub style {
    my( $self, $value ) = @_;
    if( 1==@_ ) {
        return $self->get_style;
    }
    else {
        return $self->set_style( $value );
    }
}

sub get_style
{
    my( $self ) = @_;
    return $self->{style_obj} if $self->{style_obj};
    $self->{style_obj} = POE::XUL::Style->new( $self->{attributes}{style} );
    $CM->after_new_style( $self ) if $CM;
    return $self->{style_obj};
}

sub set_style
{
    my( $self, $value ) = @_;
    $self->{attributes}{style} = "$value";
    if( blessed $value ) {
        $self->{style_obj} = $value;
        $CM->after_new_style( $self ) if $CM;
    }
    else {
        delete $self->{style_obj};
        # do the following to provoke a ->after_new_style();
        $self->get_style;
    }
    return;
}

##############################################################
sub AUTOLOAD {
	my( $self, $value ) = @_;
	my $key = our $AUTOLOAD;
	return if $key =~ /DESTROY$/;
	$key =~ s/^.*:://;
#    Carp::confess $key;
    if( $key =~ /^[a-z]/ ) {
        if( @_ == 1 ) {
            return $self->getAttribute( $key );
        }
        else {
            return $self->setAttribute( $key, $value );
        }
    }
    elsif( $key =~ /^[A-Z]/ ) {
        $self->add_child( __PACKAGE__->new(tag => $key, @_[ 1..$#_ ] ) );
    }
    croak __PACKAGE__. "::AUTOLOAD cannot find method $key";
}

##############################################################
sub hide 
{
    my( $self ) = @_;
    $self->style->display( 'none' );
}

##############################################################
sub show
{
    my( $self ) = @_;
    $self->style->display( '' );
}

sub hidden
{
    my( $self ) = @_;
    return $self->style->display eq 'none';
}

# compositing -----------------------------------------------------------------

sub children    { wantarray? @{shift->{children}}: 
                             [@{shift->{children}}] }
sub child_count { scalar @{shift->{children}} }
sub hasChildNodes { return 0!= scalar @{shift->{children}} }
sub first_child { shift->{children}->[0] }
*firstChild     = \&first_child;
sub get_child   { shift->{children}->[pop] }
sub last_child { shift->{children}->[-1] }
*lastChild     = \&last_child;

##############################################################
sub add_child {
	my ($self, $child, $index) = @_;
    # This is a huge speed up, but breaks the Aspect stuff
#    unless( defined $index ) {
#        push @{$self->{children}}, $child;
#        return $child;
#    }
	my $child_count = $self->child_count;
	$index = $child_count unless defined $index;
	croak "index out of bounds: [$index:$child_count]"
		if ($index < 0 || $index > $child_count);

    if( $self->{children}[$index] ) {
        $self->remove_child( $index );
    }

	$self->_add_child_at_index($child, $index);
	return $child;
}
sub appendChild
{
    my( $self, $child ) = @_;
    $child = $self->createTextNode( $child ) unless ref $child;
	my $index = $self->child_count;
	$self->_add_child_at_index( $child, $index );
}

sub defaultChild
{
    my( $self, $text ) = @_;
    my $d_att = $DEFAULT_ATTRIBUTE{ lc $self->{attributes}{tag} || '' };
    if( $d_att ) {
        $self->setAttribute( $d_att => $text );
        return;
    }
    
    my $child = $self->createTextNode( $text );
	my $index = $self->child_count;
	$self->_add_child_at_index( $child, $index );
}

##############################################################
sub replaceChild {
	my ($self, $new, $old) = @_;

	my ($oldNode, $index) = $self->_compute_child_and_index($old);
    $CM->before_remove_child( $self, $oldNode, $index ) if $CM;
	splice @{$self->{children}}, $index, 1, $new;
    $CM->before__add_child_at_index( $self, $new, $index ) if $CM;
	$old->dispose;
	return $self;
}

##############################################################
sub remove_child {
	my ($self, $something) = @_;

	my ($child, $index) = $self->_compute_child_and_index($something);

    unless( $child and $index < @{ $self->{children} } ) {
        Carp::carp "Attempt to remove an unknown child node" unless $ENV{AUTOMATED_TESTING};
        return;
    }

    # warn "remove_child id=", $child->{attributes}{id};
    $CM->before_remove_child( $self, $child, $index ) if $CM;
	splice @{$self->{children}}, $index, 1;
	$child->dispose if blessed $child;
	return $self;
}

*removeChild = \&remove_child;

##############################################################
sub get_child_index 
{
	my ($self, $child) = @_;
	my $index = 0;
    foreach my $C ( @{ $self->{children} } ) {
        return $index if $child eq $C;
        $index++;
    }
    confess 'child not in parent';
}

##############################################################
# computes child and index from child or index
sub _compute_child_and_index 
{
	my ($self, $something) = @_;
	my $is_node = ref $something;
	my $child   = $is_node? $something: $self->get_child($something);
	my $index   = $is_node? $self->get_child_index($something): $something;
	return wantarray? ($child, $index): $child;
}

sub _add_child_at_index {
	my ($self, $child, $index) = @_;
    my $N = $#{ $self->{children} };
    my $trueindex;
    if( $index > $N ) {
        $index = -1;
        push @{ $self->{children} }, $child;
        $trueindex = $#{ $self->{children} };
    }
    else {
        splice @{$self->{children}}, $index, 0, $child;
    }
    if( $CM ) {
        $CM->after__add_child_at_index( $self, $child, $index );
        # after__add_child needs $index to be -1 for appends, so that they
        # work in Runner.  However, the state needs to remember the real, true
        # index, so we set it afterwards.  
        # 2009-02: the problem with this is that the index might differ from
        # what is happening in the client.  Client should send the index back
        # to us.  TODO when we implement AJAX
        if( defined $trueindex ) {
            $CM->set_trueindex( $self, $child, $trueindex );
        }
    }
	return $child;
}

##############################################################
sub getElementById
{
    my( $self, $id ) = @_;
    return $id if blessed $id;      # act like prototype's $()
    croak "getElementById may only be invoked on a Window"
            unless $self->is_window;
    return $CM->getElementById( $id );
}

# event handling --------------------------------------------------------------

sub attach { 
    my( $self, $name, $listener ) = @_;

    my $state;

    my $server = $POE::XUL::Application::server;
    if( $server ) {
        # auto-create the handler in the application
        $state = $server->attach_handler( $self, $name, $listener );
    }
    else {
        $state = $listener||$name;
    }
    DEBUG and warn $self->id, ".$name = $state";
    return unless $state;
    $self->{events}->{ $name } = $state;
    return 1;
}
*addEventListener = \&attach;

sub detach {
	my ($self, $name) = @_;
	my $listener = delete $self->{events}->{$name};
	croak "no listener to detach: $name" unless $listener;
    # TODO: remove the POE state if we auto-created it?
}	
*removeEventListener = \&detach;

sub event {
	my ($self, $name) = @_;
	my $listener = $self->{events}->{ $name };
	return $listener;
}

# disposing ------------------------------------------------------------------

# protected, used by sessions and by parent nodes to free node memory 
# event handlers could cause reference cycles, so we free them manually
sub dispose {
	my $self = shift;
    $self->{disposed} = 1;
    delete $self->{style_obj};
	$_->dispose for grep { blessed $_ } $self->children;
	delete $self->{events};
    $self->{children} = [];
    # TODO: remove any events that auto-created handler states
}
*destroy = \&dispose;

sub is_destroyed { !shift->{events} }

sub DESTROY
{
    my( $self ) = @_;
    # carp "DESTROY ", ($self->id||$self);
    $CM->after_destroy( $self ) if $CM;
}



#######################################################################
sub as_xml {
	my $self       = shift;
	my $level      = shift || 0;
	my $tag        = lc $self->tag;
    $tag =~ s/_/:/;
	my $attributes = $self->attributes_as_xml;
	my $children   = $self->children_as_xml($level + 1);
#	my $indent     = $self->get_indent($level);
    my $nl         = ( $tag =~ /^((h|v|group)box)|(grid|row|(field-(name|value)))$/ ? "\n" : "" );
    return qq[<$tag$attributes${\( $children? ">$nl$children</$tag": '/' )}>$nl];
}

sub attributes_as_xml {
	my $self       = shift;
	my %attributes = $self->attributes;
	my $xml        = '';

    delete $attributes{id} if $self->{default_id} and 
                              $attributes{id} eq $self->{default_id};
    
    foreach my $k ( keys %attributes ) {
        next if defined $attributes{ $k };
        warn $self->id."/$k is undef";
        $attributes{ $k } = '';
    }
	$xml .= qq[ $_='${\( encode_entities_numeric( $self->$_, "\x00-\x1f<>&\'\x80-\xff" ) )}']
		for grep { $_ ne 'tag' and $_ ne 'textNode' } keys %attributes;
#    die $xml if $xml =~ /\n/;
	return $xml;
}

sub children_as_xml {
	my $self   = shift;
	my $level  = shift || 0;
#	my $indent = $self->get_indent($level);
	my $xml    = '';
#	$xml .= qq[\n$indent${\( $_->as_xml($level) )}] for $self->children;
	$xml .= qq[${\( blessed $_ ? $_->as_xml($level) : $_ )}] for $self->children;
	return $xml;
}

sub get_indent { ' ' x (3 * pop) }

1;

__END__

=head1 NAME

POE::XUL::Node - XUL element

=head1 SYNOPSIS

  use POE::XUL::Node;

  # Flexible way of creating an element
  my $box = POE::XUL::Node->new( tag => 'HBox', 
                                 Description( "Something" ),
                                 class => 'css-class',
                                 style => $css,
                                 Click => $poe_event  
                               );

  # DWIM way
  $window = Window(                            # window with a header,
     HTML_H1(textNode => 'a heading'),         # a label, and a button
     $label = Label(FILL, value => 'a label'),
     Button(label => 'a button'),
  );

  # attributes
  $window->width( 800 );
  $window->height( 600 );

  $label->value('a value');
  $label->style('color:red');
  print $label->flex;

  # compositing
  print $window->child_count;                  # prints 2
  $window->Label(value => 'another label');    # add a label to window
  $window->appendChild(Label);                 # same but takes child as param
  $button = $window->get_child(1);             # navigate the widget tree
  $window->add_child(Label, 0);                # add a child at an index

  # events
  $window->Button(Click => sub { $label->value('clicked!') });
  $window->MenuList(
     MenuPopup(map { MenuItem( label => "item #$_", ) } 1..10 ),
     Select => sub { $label->value( $_[0]->selectedIndex ) },
  );

  # disposing
  $window->removeChild($button);                # remove child widget
  $window->remove_child(1);                     # remove child by index

=head1 DESCRIPTION

POE::XUL::Node is a DOM-like object that encapsulates a XUL element.
It uses L<POE::XUL::ChangeManager> to make sure all changes are mirrored
in the browser's DOM.


=head2 Elements

To create a UI, an application must create a C<Window> with some elements in
it.  Elements are created by calling a function or method named after their
tag:

  $button = Button;                           # orphan button with no label
  $box->Button;                               # another, but added to a box
  $widget = POE::XUL::Node->new(tag => $tag); # using dynamic tag

After creating a widget, you must add it to a parent. The widget will
show when there is a containment path between it and a window. There are
multiple ways to set an elements parent:

  $parent->appendChild($button);              # DOM-like
  $parent->replaceChild( $old, $new );        # DOM-like
  $parent->add_child($button);                # left over from XUL-Node
  $parent->add_child($button, 1);             # at an index
  $parent->Button(label => 'hi!');            # create and add in one shot
  $parent = Box(style => 'color:red', $label);# add in parent constructor


Elements can be removed from the document by removing them 
from their parent:

  $parent->removeChild($button);           # DOM-like
  $parent->remove_child(0);                 # index
  $parent->replaceChild( $old, $new );        # DOM-like


Elements have attributes. These can be set in the constructor, or via
a method of the same name:

  my $button = Button( value => 'one button' );
  $button->value('a button');
  print $button->value;                       # prints 'a button'


You can configure all attributes, event handlers, and children of a
element, in the constructor. There are also constants for commonly used
attributes. This allows for some nice code:

  Window( SIZE_TO_CONTENT,
     Grid( FLEX,
        Columns( Column(FLEX), Column(FLEX) ),
        Rows(
           Row(
              Button( label => "cell 1", Click => $poe_event ),
              Button( label => "cell 2", Click => $poe_event ),
           ),
           Row(
              Button( label => "cell 3", Click => $poe_event ),
              Button( label => "cell 4", Click => $poe_event ),
           ),
        ),
     ),
  );

Check out the XUL references (L<http://developer.mozilla.org/en/docs/XUL>)
for an explanation of available elements and their attributes.




=head2 The id attribute

POE::XUL requires each node to have a unique identifier.  If you
do not set the C<id> attribute of an node, it will assigned one.  A
node's C<id> attribute must be globally to the application, including across
windows in the same application.  This is contrary to how the DOM works,
where elements in different windows may share an id, may even not have one.

Use <POE::XUL::Window/getElementById> to find a node by its C<id>.


=head2 Events

Elements receive events from their client halves, and pass them on to
attached listeners in the application. You attach a listener to a widget
so:

  # listening to existing widget
  $textbox->attach( Change => sub { print 'clicked!' } );

  # listening to widget in constructor
  TextBox( Change => $poe_event );

You attach events by providing an event name and a listener. Possible
event names are C<Click>, C<Change>, C<Select>, and C<Pick>. Different
widgets fire different events. These are listed in L<POE::XUL::Event>.

Listener are either the name of a POE event, or a callbacks that receives a
single argument: the event object (L<POE::XUL::Event>).  POE events are
called on the application session, NOT the current session when an event is
defined.  If you want to post to another session, use
L<POE::Session/callback>.

You can query the Event object for information about the event: C<name>,
C<source>, and depending on the event type: C<checked>, C<value>, C<color>,
and C<selectedIndex>.

Here is an example of listening to the C<Select> event of a list box:

  Window(
     VBox(FILL,
        $label = Label(value => 'select item from list'),
        ListBox(FILL, selectedIndex => 2,
           (map { ListItem(label => "item #$_") } 1..10),
           Select => sub {
              $label->value
                 ("selected item #${\( shift->selectedIndex + 1 )}");
           },
        ),
     ),
  );

Events are removed with the L</detach> method:

    $button->detach( 'Click' );

=head2 Style

An element's style property is implemented by a L<POE::XUL::Style> object, 
which allows DOM-like manipulation of the element's style declaration.

    my $button = Button( style=>'color: red' );
    $button->style->color( 'puce' );


=head2 XUL-Node API vs. the XUL DOM

The XUL-Node API is different in the following ways:

=over 4

=item *

Booleans are Perl booleans, not C<true> and C<false>.

=item *

All nodes must have an C<id> attribute.  If you do not specify one, it will
be automatically generated by POE::XUL::Node.

=item *

There is little difference between attributes, properties, and methods. They
are all attributes on the L<POE::XUL::Node> object.  However, the javascript
client library handles them differently.

This means that to call a method or a property, you have to specify at least
one parameter:

    $node->blur( 0 );           # Equiv to node.blur() in JS

=item *

While all attribute and properties are mirrored from the Perl object to the
DOM object, only a select few are mirrored back (C<value>, C<selected>,
C<selectedIndex>).

=item *

You currently can not move nodes around in the DOM.

    my $node = $parent->getChild( 3 );
    my $new_node = Description( content => $node );
    $parent->removeChild( 3 );
    $parent->appendChild( $new_node );      # FAIL!

=back

=head1 ELEMENT CONSTRUCTORS

To make life funner, a bunch of constructor functions have been defined
for the most commonly used elements.  These functions are exported into
any package that uses POE::XUL::Node.

=head2 XUL Elements

ArrowScrollBox, Box, Button, Caption, CheckBox, ColorPicker, Column, Columns, 
Deck, Description, Grid, Grippy, GroupBox, HBox, Image, Label, ListBox, 
ListCell, ListCol, ListCols, ListHead, ListHeader, ListItem, Menu, MenuBar, 
MenuItem, MenuList, MenuPopup, MenuSeparator, ProgressMeter, Radio, 
RadioGroup, Row, Rows, Seperator, Spacer, Splitter, Stack, StatusBar, 
StatusBarPanel, Tab, TabBox, TabPanel, TabPanels, Tabs, TextBox, ToolBar, 
ToolBarButton, ToolBarSeperator, ToolBox, VBox, Window.

It is of course possible to create any other XUL element with:

    POE::XUL::Node->new( tag => $tag );


=head2 HTML Elements

HTML_Pre, HTML_H1, HTML_H2, HTML_H3, HTML_H4, HTML_A, HTML_Div, HTML_Br, 
HTML_Span.

It is of course possible to create any other HTML element with:

    POE::XUL::Node->new( tag => "html:$tag" );


=head1 SPECIAL ELEMENTS

There are 4 special elements:

=head2 Script

    Script( $JS );

Creates a script element, with C<type="text/javascript">, and a single
L<POE::XUL::CDATA> child.  The client library will C<eval()> the script.

=head2 Boot

    Boot( $text );

Sends the boot command to the client library.  Currently, the client library 
calls C<$status.title( $text );>, if the C<$status> object exists.  Your
application must create C<$status>.

=head2 RawCmd

    RawCmd( \@cmd );

Allows you to send a raw command to the Javascript client library.  Use at
your own risk.

=head2 pxInstructions

    pxInstructions( @instructions );

Send instructions to the ChangeManager.  This is a slightly higher-level
form of L</RawCmd>.  Its presence indicates the immaturity of POE::XUL as a
whole.  These instructions are subject to change/removal in the future.

L<@instructions> is an array instructions for the ChangeManager.  
See L<POE::XUL::ChangeManager/instrction> for details.


=head1 METHODS

=head2 createTextNode

Creates and populates a L<POE::XUL::TextNode>.  Returns the new node.

    my $tn = window->createTextNode( 'Some text' );

=head2 textNode

Sets or changes the text of a node, such as
L<description|http://developer.mozilla.org/en/docs/XUL:description>. If the
node has multiple children (aka <i>mixed-mode</i>) then it will replace the
first textNode it finds.  If there are none, it will append a new text node.
See L<POE::XUL::TextNode>.

    my $d = Description( textNode => 'Hello world!' );
    $d->textNode( 'This is different' );


=head2 children

Find a given node's child nodes.  Returns array in array context, an array
reference in scalar context.  Modifying the arrayref will NOT modify the
node's list of children.

    foreach my $node ( $box->children ) {
        # ...
    }

=head2 child_count

Returns the number of child nodes of an node.

=head2 hasChildNodes

Returns true if a node has child nodes.

=head2 add_child

    $parent->add_child( $node, $index );

=head2 appendChild

    $parent->appendChild( $node );

=head2 firstChild / first_child

    my $node = $parent->firstChild;

=head2 get_child

    my $node = $parent->get_child( $index );

Use <POE::XUL::Window/getElementById> to find a node by its C<id>.

=head2 getItemAtIndex / get_item

    my $node = $menu->getItemAtIndex( $index );

Like L</get_child>, but works for C<menulist> and C<menupopup>.

=head2 lastChild / last_child

    my $node = $parent->lastChild;

=head2 removeChild / remove_child

    $parent->removeChild( $node );
    $parent->removeChild( $index );

=head2 replaceChild

    $parent->replaceChild( $old, $new );

=head2 attributes

    my %hash = $node->attributes;
    my $hashref = $node->attributes;

Note that even if you manipulate C<$hashref> directly, changes will not be
mirrored in the node.

=head2 getAttribute / get_attribute

    my $value = $node->getAttribute( $name );

=head2 setAttribute / set_attribute

    $node->setAttribute( $name => $value );

=head2 removeAttribute / remove_attribute

    $node->removeAttribute( $name );



=head2 hide

    $node->hide;

Syntatic sugar that does the following:

    $node->style->display( 'none' );

=head2 show

    $node->show;

Syntatic sugar that does the following:

    $node->style->display( '' );

=head2 attach

    $node->attach( $Event => $listener );
    $node->attach( $Event => $coderef );
    $node->attach( $Event );

Attaches an event listener to a node.  When C<$Event> happens (normaly in
response to a DOM event) the C<$poe_event> is posted to the application
session.  Alternatively, the C<$coderef> is called.  In both cases, an
L<POE::XUL::Event> object is passed as the first parameter.  C<$poe_event>
defaults to C<$Event>.

C<attach()> will auto-create handlers for C<POE::XUL::Application>.

=head2 detach

    $node->detach( $Event );

Removes the event listener for C<$Event>.  Auto-created handlers are
currently not removed.

=head2 event

    my $listener = $node->event( $Event );

Gets the node's event listener for C<$Event>.  A listener is either a
coderef, or the name of a POE event handler in the application's session. 
Application code will rarely need to call this method.

=head2 dispose / distroy

Calls C<dispose> on all the child nodes, and drops all events.

=head2 as_xml

Returns this element and all its child elements as an unindented XML string.
Useful for debuging.

=head1 LIMITATIONS

=over 4

=item *

Some elements are not supported yet: tree, popup.

=item *

Some DOM features are not supported yet:

  * multiple selections
  * node disposal
  * color picker will not fire events if type is set to button
  * equalsize attribute will not work
  * menus with no popups may not show

=item *

Some XUL properties are implemented with XBL.  The front-end attempts to
wait for the XBL to be created before setting the property.  If the object
takes too long, the attribute is set instead.

What this means is that you can't reliably set the properties of freshly
created nodes.

=back


=head1 SEE ALSO

L<POE::XUL>.
L<POE::XUL::Event> presents the list of all possible events.

L<http://developer.mozilla.org/en/docs/XUL>
has a good XUL reference.


=head1 AUTHOR

Philip Gwyn E<lt>gwyn-at-cpan.orgE<gt>

=head1 CREDITS

Based on work by Ran Eilam.

=head1 COPYRIGHT AND LICENSE

Copyright 2007-2009 by Philip Gwyn.  All rights reserved;

Copyright 2003-2004 Ran Eilam. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
