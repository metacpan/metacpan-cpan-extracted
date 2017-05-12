################################################################################
#
# $Id: StringHandleTier.pm 211 2009-05-25 06:05:50Z aijaz $
#
################################################################################



=head1 NAME

StringHandleTier - implementation class to which file handles are
tied.  See TaskForest::StringHandle;

=head1 SYNOPSIS

 my $obj = tie(*STDOUT, 'TaskForest::StringHandleTier');
                            # STDOUT is now tied to the class
 print "Booyah!";           # @$obj is ['Booyah!']
 $data = $obj->getData;     # $data eq 'Booyah!'
 undef $obj;                # get rid of reference to STDOUT
 untie(*STDOUT);            # STDOUT is 'back to normal'
 print "Hello, world!\n";   # printed to stdout

=head1 DESCRIPTION
This is a helper class that does the actual tying.  Inspired by the
examples in Chapter 14 of the Camel book.

=cut

package TaskForest::StringHandleTier;
use strict;
use warnings;

BEGIN {
    use vars qw($VERSION);
    $VERSION     = '1.30';
}


sub TIEHANDLE {
    my $class = shift;
    return bless [],  $class;
}

sub PRINT {
    my $self = shift;
    push (@$self, @_);
}

sub PRINTF {
    my $self = shift;
    my $fmt = shift;
    push @$self, sprintf $fmt, @_;
}

sub getData {
    my $self = shift;
    my $d = join("", @$self);
    @$self = ();
    return $d;
}



1;

__END__

