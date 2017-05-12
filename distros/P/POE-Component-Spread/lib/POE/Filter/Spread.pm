package POE::Filter::Spread;

use strict;
use vars qw($VERSION);

$VERSION = "0.01";

sub new {
    my $type = shift;
    my $self = bless {@_}, $type;
    return $self;
}

sub get {
    my $self = shift;
    return [ @_ ];
}

$VERSION;
