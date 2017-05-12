package Seis::List;
use strict;
use warnings;
use utf8;
use 5.010_001;

package # Hide from PAUSE
    List;

sub new {
    my ($class, @ary) = @_;
    bless \@ary, $class;
}

sub Int {
    my $self = shift;
    0+@$self;
}

sub isa {
    my ($self, $stuff) = @_;
    return UNIVERSAL::isa($self, $stuff->{name}) if UNIVERSAL::isa($stuff, 'Seis::Class');
    return UNIVERSAL::isa($self, $stuff);
}

1;

