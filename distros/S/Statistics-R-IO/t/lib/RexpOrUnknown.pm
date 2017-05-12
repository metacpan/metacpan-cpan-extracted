package RexpOrUnknown;
# ABSTRACT: Utility class that is equal to a specified object or XT_UNKNOWN

use 5.010;

use Scalar::Util qw(blessed);

use Statistics::R::REXP::Unknown;

use Class::Tiny::Antlers qw(-default around);
use namespace::clean;

has obj => (
    is => 'ro',
);

use overload
    '""' => sub {
        my $self = shift;
        'maybe ' . $self->obj
    },
    eq => sub {
        my ($self, $obj) = @_;
        return $self->obj eq $obj ||
            blessed $obj && $obj->isa('Statistics::R::REXP::Unknown')
    };

sub BUILDARGS {
    my $class = shift;
    if ( scalar @_ == 1 ) {
        if ( ref $_[0] eq 'HASH' ) {
            return $_[0];
        }
        else {
            return { obj => $_[0] }
        }
    }
    else {
        return @_
    }
}

sub BUILD {
    my ($self, $args) = (shift, shift);
    die 'Attribute (obj) is required' unless exists $args->{obj};
}

1; # end of RexpOrUnknown
