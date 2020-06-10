#line 1
package Test2::Event::Exception;
use strict;
use warnings;

our $VERSION = '1.302175';


BEGIN { require Test2::Event; our @ISA = qw(Test2::Event) }
use Test2::Util::HashBase qw{error};

sub init {
    my $self = shift;
    $self->{+ERROR} = "$self->{+ERROR}";
}

sub causes_fail { 1 }

sub summary {
    my $self = shift;
    chomp(my $msg = "Exception: " . $self->{+ERROR});
    return $msg;
}

sub diagnostics { 1 }

sub facet_data {
    my $self = shift;
    my $out = $self->common_facet_data;

    $out->{errors} = [
        {
            tag     => 'ERROR',
            fail    => 1,
            details => $self->{+ERROR},
        }
    ];

    return $out;
}


1;

__END__

#line 113
