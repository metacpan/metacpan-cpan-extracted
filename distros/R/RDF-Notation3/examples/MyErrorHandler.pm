# An example of simple SAX ErrorHandler

package MyErrorHandler;

sub new {
    my $type = shift;
    return bless {}, $type;
}

sub warning {
    my ($self, $exception) = @_;
    
    print "<SAX Warning>\n";
    print "->Exception: $exception->{Exception}\n";
    print "->Message: $exception->{Message}\n";
    print "->LineNumber: $exception->{LineNumber}\n";
}

sub error {
    my ($self, $exception) = @_;
    
    print "<SAX Error>\n";
    print "->Exception: $exception->{Exception}\n";
    print "->Message: $exception->{Message}\n";
    print "->LineNumber: $exception->{LineNumber}\n";
}

sub fatal_error {
    my ($self, $exception) = @_;
    
    print "<SAX Fatal Error>\n";
    print "->Exception: $exception->{Exception}\n";
    print "->Message: $exception->{Message}\n";
    print "->LineNumber: $exception->{LineNumber}\n";
}

1;
