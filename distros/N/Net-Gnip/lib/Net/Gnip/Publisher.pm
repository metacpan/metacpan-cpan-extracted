package Net::Gnip::Publisher;
use strict;
use base qw(Net::Gnip::Base);

=head1 NAME

Net::Gnip::Publisher - represent a publisher


=head1 SYNOPSIS

    my $publisher = Net::Gnip::Publisher->new($name);
   
    # ... or parse from xml
    my $publisher = Net::Gnip::Publisher->parse($xml);
    
    # Set the name
    $publisher->name($name);

    # Get the name
    my $name = $publisher->name

    print $publisher->as_xml;
    
=head1 METHODS

=cut

=head2 new <name>

Initializes a Net::Gnip::Publisher object

=cut

sub new {
    my $class = shift;
    my $name  = shift || die "You must pass in a name";
    my %opts  = @_;
    $opts{name} = $name;
    return bless \%opts, $class;
}

=head2 name [name]

Get or set the name 

=cut
sub name { shift->_do('name', @_) }

=head2 parse <xml>

Parse some xml into an activity.

=cut

sub parse {
    my $class  = shift;
    my $xml    = shift;
    my %opts   = @_;
    my $parser = $class->parser();
    my $doc    = $parser->parse_string($xml);
    my $elem   = $doc->documentElement();
    return $class->_from_element($elem, %opts);
}

sub _from_element {
    my $class = shift;
    my $elem  = shift;
    my %opts  = @_;
    my $no_dt  = (ref($class) && $class->{_no_dt}) || $opts{_no_dt};
    foreach my $attr ($elem->attributes()) {
        my $name = $attr->name;
        $opts{$name} = $attr->value;
    }
    return $class->new(delete $opts{name}, %opts, _no_dt => $no_dt);
}

=head2 as_xml

Return the activity as xml

=cut

sub as_xml {
    my $self       = shift;
    my $as_element = shift;
    my $element    = XML::LibXML::Element->new('publisher');
    foreach my $key (keys %$self) {
        next if '_' eq substr($key, 0, 1);
        my $value = $self->{$key};
        $element->setAttribute($key, $value);
    }
    return ($as_element) ? $element : $element->toString(1);
}

1;
