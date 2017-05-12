package Net::Gnip::BaseStream;

use strict;
use base qw(Net::Gnip::Base);

=head1 NAME

Net::Gnip::BaseStream - represent a list of Gnip objects

=head1 SYNOPIS


    # Create a new stream    
    my $stream = Net::Gnip::BaseStream->new();

    # ... or parse from XML
    my $stream = Net::Gnip::BaseStream->parse($xml);

    # assume that the subclass of BaseStream 
    # has children named foo

    # set the foos
    $stream->foos(@foos);
    
    # get the filters 
    my @foos = $stream->foos;

    # or use an iterator
    while (my $foo = $stream->next) {
        print $foo->name;
    }

    $stream->reset;

    # ... now you can use it again
    while (my $foo = $stream->foo) {
        print $foo->name;
    }


=head1 METHODS

=cut

=head2 new

Create a new, empty stream

=cut

sub new {
    my $class = shift;
    my %opts  = @_;
    return bless {%opts}, ref($class) || $class;
}




=head2 children [child[ren]]

Get or set the children

=cut

sub children {
    my $self = shift;
    if (@_) {
        $self->{children} = [@_];
        $self->reset;
    }
    return @{$self->{children}||[]};
}

=head2 parse <xml>

Takes a string of XML, parses it and returns a new,
potentially populated FilterStream

=cut

sub parse {
    my $class  = shift;
    my $xml    = shift;
    my %opts   = @_;
    my $no_dt  = (ref($class) && $class->{_no_dt}) || $opts{_no_dt};
    my $parser = $class->parser; 
    my $doc    = $parser->parse_string($xml);
    my $elem   = $doc->documentElement();
    my @children;
    my $name   = $class->_child_name;
    my $cclass = "Net::Gnip::".ucfirst($name);
    my %args;
    foreach my $attr ($elem->attributes()) {
        my $name = $attr->name;
        $args{$name} = $attr->value;
    }
    foreach my $child ($elem->getChildrenByTagName($name)) {
        push @{$args{children}}, $cclass->_from_element($child, _no_dt => $no_dt);
    }
    
    return $class->new( %args );
}


=head2 next 

Returns the next Child object 

=cut

sub next {
    my $self = shift;
    return $self->{children}->[$self->{_iter}++];
}

=head2 reset

Resets the iterator

=cut

sub reset {
    my $self = shift;
    $self->{_iter} = 0;
    return 1;
}


=head2 as_xml 

Return this stream as xml

=cut 

sub as_xml {
    my $self       = shift;
    my $as_element = shift;
    my $name       = $self->_child_name;
    my $elem_name  = $self->_elem_name;
    my $element    = XML::LibXML::Element->new($elem_name);
    foreach my $child (@{delete $self->{children}}) {
        $element->addChild($child->as_xml(1));
    }

    foreach my $key (keys %$self) {
        next if '_' eq substr($key, 0, 1);
        my $value = $self->{$key};
        $element->setAttribute($key, $value);
    }

    return ($as_element) ? $element : $element->toString(1);

}

1;
