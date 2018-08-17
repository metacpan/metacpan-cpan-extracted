#line 1
package Test2::Event::Bail;
use strict;
use warnings;

our $VERSION = '1.302073';


BEGIN { require Test2::Event; our @ISA = qw(Test2::Event) }
use Test2::Util::HashBase qw{reason};

sub callback {
    my $self = shift;
    my ($hub) = @_;

    $hub->set_bailed_out($self);
}

# Make sure the tests terminate
sub terminate { 255 };

sub global { 1 };

sub causes_fail { 1 }

sub summary {
    my $self = shift;
    return "Bail out!  " . $self->{+REASON}
        if $self->{+REASON};

    return "Bail out!";
}

sub diagnostics { 1 }

1;

__END__

#line 102
