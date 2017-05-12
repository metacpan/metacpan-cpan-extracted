# An example of simple SAX Handler

package MyHandler;

sub new {
    my $type = shift;
    return bless {}, $type;
}

sub start_document {
    my ($self, $document) = @_;
    
    print "Starting document\n";
}

sub end_document {
    my ($self, $document) = @_;
    
    print "Ending document\n";
    return 1;
}

sub start_element {
    my ($self, $element) = @_;
    
    print "<$element->{Name} ";
    foreach (keys %{$element->{Attributes}}) {
	print "$element->{Attributes}->{$_}->{Name}=";
	print "\"$element->{Attributes}->{$_}->{Value}\" ";
    }
    print ">\n";
}

sub end_element {
    my ($self, $element) = @_;
    
    print "</$element->{Name}>\n";
}

sub characters {
    my ($self, $characters) = @_;
    
    print "$characters->{Data}\n";
}

1;
