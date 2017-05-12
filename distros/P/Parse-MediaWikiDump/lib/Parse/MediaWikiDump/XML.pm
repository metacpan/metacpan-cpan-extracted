#this is set to become a new module on CPAN after
#testing is done and documentation is written

#this module is a thin wrapper around XML::Accumulator that
#provides a tree interface for the event handlers. The engine
#follows the tree as it receives events from XML::Accumulator
#so that context can be pulled out from the location in the 
#tree.

#Handlers for this module are also registered as callbacks but
#exist at a specific node on the tree. Each handler is invoked
#with the same information that came from the XML::Parser event
#but is also given an additional argument that is an accumulator
#variable to store data in. 
package Parse::MediaWikiDump::XML::Accumulator;

use warnings;
use strict;

sub new {
	my ($class) = @_;
	my $self = {};
	
	bless($self, $class);
}

sub engine {
	shift(@_);
	return Parse::MediaWikiDump::XML::Accumulator::Engine->new(@_);
}

sub node {
	shift(@_);
	return Parse::MediaWikiDump::XML::Accumulator::Node->new(@_);
}

sub root {
	shift(@_);
	return Parse::MediaWikiDump::XML::Accumulator::Root->new(@_);
	
}

sub textcapture {
	shift(@_);
	return Parse::MediaWikiDump::XML::Accumulator::TextCapture->new(@_);
}

package Parse::MediaWikiDump::XML::Accumulator::Engine;

use strict; 
use warnings;
use Carp qw(croak);

use Scalar::Util qw(weaken);
use XML::Parser;

sub new {
	my ($class, $root, $accum) = @_;
	my $self = {};
	
	croak "must specify a tree root" unless defined $root;
	
	eval { $root->validate; };
	die "root node failed validation: $@" if $@;
	
	bless($self, $class);
		
	$self->{parser} = $self->init_parser;
	$self->{root} = $root;
	$self->{element_stack} = [];
	$self->{accum} = $accum;
	$self->{char_buf} = [];
	$self->{node_stack} = [ $root ];
	
	return $self;
}

sub init_parser {
	my ($self) = @_;
	
	#stop a giant memory leak
	weaken($self);
	
	my $parser = XML::Parser->new(
		Handlers => {
			#Init => sub { handle_init_event($self, @_) },
			#Final => sub { handle_final_event($self, @_) },
			Start => sub { handle_start_event($self, @_) },
			End => sub { handle_end_event($self, @_) },
			Char => sub { handle_char_event($self, @_); },
		}
	);
	
	return $parser;	
}

sub parser {
	my ($self) = @_;
	
	return $self->{parser};
}

sub handle_init_event {
	my ($self, $expat) = @_;
	my $root = $self->{root};
	my $handlers = $root->{handlers};
	
	if (defined(my $cb = $handlers->{Init})) {
		&cb($self);
	}
}

sub handle_final_event {
	my ($self, $expat) = @_;
	my $root = $self->{root};
	my $handlers = $root->{handlers};
	
	if (defined(my $cb = $handlers->{Final})) {
		&cb($self);
	}
}

sub handle_start_event {
	my ($self, $expat, $element, %attrs) = @_;
	my $element_stack = $self->{element_stack};
	my $node = $self->node;
	my $matched = $node->{children}->{$element};
	my $handler; 
	
	$handler = $matched->{handlers}->{Start};
	
	$self->flush_chars;	
	defined $handler && &$handler($self, $self->{accum}, $element, \%attrs);
		
	push(@{$self->{node_stack}}, $matched);
	push(@$element_stack, [$element, \%attrs]);
	
}

sub handle_end_event {
	my ($self, $expat, $element) = @_;
	my $handler = $self->node->{handlers}->{End};
	my $node_stack = $self->{node_stack};
	
	$self->flush_chars;

	defined $handler && &$handler($self, $self->{accum}, @{$self->element});
	
	pop(@$node_stack);
	pop(@{$self->{element_stack}});
	
}

sub handle_char_event {
	push(@{$_[0]->{char_buf}}, $_[2]); 
}

sub flush_chars {
	my ($self) = @_;
	my ($handler, $cur_element);
	
	$handler = $self->node->{handlers}->{Character};
	$cur_element = $self->element;
	
	if (! defined($cur_element = $self->element)) {
		$cur_element = [];
	}
	
	defined $handler && &$handler($self, $self->{accum}, join('', @{$self->{char_buf}}), @$cur_element);
		
	$self->{char_buf} = [];
	
	return undef;
}

sub node {
	my ($self) = @_;
	my $stack = $self->{node_stack};
	my $size = scalar(@$stack);

	return $$stack[$size - 1];
}

sub element {
	my ($self) = @_;
	my $stack = $self->{element_stack};
	my $size = scalar(@$stack);
	my $return = $$stack[$size - 1];
	
	return $return;
}

sub accumulator {
	my ($self, $new) = @_;
	
	if (defined($new)) {
		$self->{accum} = $new;
	}	
	
	return $self->{accum};
}

package Parse::MediaWikiDump::XML::Accumulator::Node;

use strict;
use warnings;

use Carp qw(croak cluck);

sub new {
	my ($class, $name, %handlers)	= @_;
	my $self = {};
	
	croak("must specify a node name") unless defined $name;
	
	$self->{name} = $name;
	$self->{handlers} = \%handlers;
	$self->{children} = {};
	$self->{debug} = 1;
	
	bless($self, $class);
	
	return $self;
}

sub name {
	my ($self) = @_;
	return $self->{name};
}

sub handlers {
	my ($self) = @_;
	return $self->{handlers};
}

sub unset_handlers {
	my ($self) = @_;
	
	$self->{handlers} = undef;
	
	foreach (values(%{ $self->{children} })) {
		$_->unset_handlers;
	}
	
	return 1;
}

sub error {
	my ($self, $path, $string) = @_;
	my $name = $self->{name};
	
	if (ref($path) ne 'ARRAY') {
		cluck "must specify an array ref for node path in tree";
	}
	
	if ($self->{debug}) {
		print "Fatal error in node $name: $string\n";
		print "Node tree path:\n";
		
		$self->print_path($path);
	}
		
	die "fatal error: $string";
}

sub print_path {
	my ($self, $path) = @_;
	my $i = 0;
	
	foreach (@$path) {
			my ($name) = $_->name;
			print "$i: $name\n";	
	}
	
	return undef;
}

sub validate {
	my ($self, $path) = @_;
	my ($handlers) = $self->{handlers};
	my (%ok);
	
	map({$ok{$_} = 1} $self->ok_handlers);
	
	if (! defined($path)) {
		$path = [];
	}
	
	push(@$path, $self);
	
	foreach (keys(%$handlers)) {
		my $check = $handlers->{$_};
		
		if (! defined($check) || ref($check) ne 'CODE') {
			$self->error($path, "Handler $_: not a code reference");
			next;
		}
		
		if (! $ok{$_}) {
			$self->error($path, "$_ is not a valid event name");
			next;
		}
	}
	
	foreach (values(%{$self->{children}})) {
		$_->validate($path);
	}

	return undef;
}

sub ok_handlers {
		return qw(Character Start End);
	
}

sub print {
	my ($self, $level) = @_;
	
	if (! defined($level)) {
		$level = 1;
	}	

	print '  ' x $level, "$level: ", $self->name, "\n";
	
	$level++;
	
	foreach (values(%{$self->{children} } )) {
		$_->print($level);
	}
	
	$level--;
}

sub add_child {
	my ($self, @children) = @_;
	
	foreach my $child (@children) {
			my $name = $child->{name};
			$self->{children}->{$name} = $child;	
	}
	
	return $self;
}

package Parse::MediaWikiDump::XML::Accumulator::Root;

use strict; 
use warnings;

use base qw(Parse::MediaWikiDump::XML::Accumulator::Node);

sub new {
	my ($class) = @_;
	my $self = $class->SUPER::new('[root container]');
	
	bless($self, $class);
}

sub ok_handlers {
		return qw(Init Final);
}

package Parse::MediaWikiDump::XML::Accumulator::TextCapture;

use base qw(Parse::MediaWikiDump::XML::Accumulator::Node);

use strict;
use warnings;

sub new {
	my ($class, $name, $store_as) = @_;
	my $self = $class->SUPER::new($name);
		
	bless($self, $class);

	if (! defined($store_as)) {
		$store_as = $name;		
	}
	
	$self->{handlers} = {
		Character => sub { char_handler($store_as, @_); }, 
	};
	
	return $self;	
}

sub char_handler {
	my ($store_as, $parser, $a, $chars, $element) = @_;
	
	$a->{$store_as} = $chars;
}

1;
