package Module::Lazy::_::test::autoload;

use strict;
use warnings;
our $VERSION = 42;

our $AUTOLOAD;
sub AUTOLOAD {
    $AUTOLOAD =~ s/.*:://;

    my $self = shift;
    return "$self->$AUTOLOAD(@_) called";
};

sub new {
    return bless {}, shift;
};

sub DESTROY {
};

1;
