package Net::EPP::Parser;
use base qw(XML::LibXML);
use strict;
use warnings;

sub new {
    my $package = shift;
    my $self = bless($package->SUPER::new(@_), $package);
    return $self;
}

1;
