#line 1
package Test2::Event::Waiting;
use strict;
use warnings;

our $VERSION = '1.302175';


BEGIN { require Test2::Event; our @ISA = qw(Test2::Event) }
use Test2::Util::HashBase;

sub global { 1 };

sub summary { "IPC is waiting for children to finish..." }

sub facet_data {
    my $self = shift;

    my $out = $self->common_facet_data;

    push @{$out->{info}} => {
        tag     => 'INFO',
        debug   => 0,
        details => $self->summary,
    };

    return $out;
}

1;

__END__

#line 76
