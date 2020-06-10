#line 1
package Test2::Event::Bail;
use strict;
use warnings;

our $VERSION = '1.302175';


BEGIN { require Test2::Event; our @ISA = qw(Test2::Event) }
use Test2::Util::HashBase qw{reason buffered};

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

sub facet_data {
    my $self = shift;
    my $out = $self->common_facet_data;

    $out->{control} = {
        global    => 1,
        halt      => 1,
        details   => $self->{+REASON},
        terminate => 255,
    };

    return $out;
}

1;

__END__

#line 109
