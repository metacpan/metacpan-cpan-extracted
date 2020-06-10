#line 1
package Test2::Event::Diag;
use strict;
use warnings;

our $VERSION = '1.302175';


BEGIN { require Test2::Event; our @ISA = qw(Test2::Event) }
use Test2::Util::HashBase qw/message/;

sub init {
    $_[0]->{+MESSAGE} = 'undef' unless defined $_[0]->{+MESSAGE};
}

sub summary { $_[0]->{+MESSAGE} }

sub diagnostics { 1 }

sub facet_data {
    my $self = shift;

    my $out = $self->common_facet_data;

    $out->{info} = [
        {
            tag     => 'DIAG',
            debug   => 1,
            details => $self->{+MESSAGE},
        }
    ];

    return $out;
}

1;

__END__

#line 99
