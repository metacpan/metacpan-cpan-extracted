# ##############################################################################
#
# $Id: StringHandle.pm 211 2009-05-25 06:05:50Z aijaz $
#
# ##############################################################################

=head1 NAME

StringHandle - intercept text sent to stdout or stderr

=head1 SYNOPSIS

 $text1 = "This should go to STDOUT\n";
 $text2 = "This is the second line\n";

 $sh = TaskForest::StringHandle->start(*STDOUT);
                          # stdout is being captured as a string
 print $text1;            # nothing is printed to stdout
 $stdout1 = $sh->read();  # $stdout1 eq $text1
 $stdout2 = $sh->read();  # $stdout2 eq ''
 print $text2;            # nothing is printed now either
 $stdout3 = $sh->stop();  # $stdout3 eq $text2, capture stopped
 print "Hello, world!\n"; # this is printed to stdout

=head1 DESCRIPTION

This is a simple class that you can use to intercept any text that
would have been written to stdout or stderr or any file handle and
saves it instead locally.  You can then retrieve the text and use it
to examine what would have been sent to stdout (or stderr).  It was
developed primarily to help with the test cases.

=cut

package TaskForest::StringHandle;
use strict;
use warnings;
use TaskForest::StringHandleTier;
use Carp;
  
BEGIN {
    use vars qw($VERSION);
    $VERSION     = '1.30';
}


# this is a constructor
sub start {
    my ($class, $handle) = @_;
    my $obj = tie($handle, 'TaskForest::StringHandleTier');
    my $self = { obj => $obj, handle => $handle};
    bless $self, $class;
}

sub read {
    my $self = shift;
    return $self->{obj}->getData();
    
}

sub stop { 
    my $self = shift;

    my $d = $self->read();
    undef $self->{obj};
    untie($self->{handle});
    return $d;
}

1;

__END__



