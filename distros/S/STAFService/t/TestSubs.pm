package TestSubs;
use strict;
use PLSTAF;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(my_submit send_request staf_register);

sub staf_register {
    my $test_name = shift;
    my $handle = STAF::STAFHandle->new($test_name); 
    if ($handle->{rc} != $STAF::kOk) { 
        print "Error registering with STAF, RC: $handle->{rc}\n"; 
        die $handle->{rc}; 
    }
    return $handle;
}

sub send_request {
    my ($handle, $srv, $request, $expected_rc, $expected_string) = @_;
    my $result = $handle->submit("local", $srv, $request); 
    my $msg = $result->{result};
    if ($result->{rc} != $expected_rc) { 
        print "Error getting result, request='$request', RC: $result->{rc}, Expected RC: $expected_rc\n"; 
        if (defined($msg) and (length($msg) != 0)) { 
            print "Additional info: $msg\n"; 
        }
        return 0;
    }
    if (defined($msg) and ($msg =~ /^$expected_string/)) {
        return 1;
    } elsif (!defined $msg and !defined $expected_string) {
        return 1;
    } else {
        my $dmsg = defined($msg)? $msg : "<undef>";
        print "Got wrong reply. Expectd: $expected_string, Got: $dmsg\n";
        return 0;
    }
}

sub my_submit {
    my ($handle, $srv, $request) = @_;
    my $result = $handle->submit("local", $srv, $request); 
    if ($result->{rc} != $STAF::kOk) { 
        print "Error getting result, request='$request', RC: $result->{rc}\n"; 
        if (defined($result->{result}) and (length($result->{result}) != 0)) { 
            print "Additional info: $result->{result}\n"; 
        } 
    } 
    return $result->{result}; 
}


1;