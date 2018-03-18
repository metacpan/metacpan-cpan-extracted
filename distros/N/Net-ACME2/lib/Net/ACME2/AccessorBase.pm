package Net::ACME2::AccessorBase;

use strict;
use warnings;

our $AUTOLOAD;

sub new {
    my ($class, %opts) = @_;

    $opts{"_$_"} = delete $opts{$_} for keys %opts;

    return bless \%opts, $class;
}

sub AUTOLOAD {
    my ($self) = @_;

    $AUTOLOAD =~ m<(.+)::(.+)> or die "Weird func name: “$AUTOLOAD”!";
    my ($class, $method) = ($1, $2);

    if ( grep { $method eq $_ } $self->_ACCESSORS() ) {
        return $self->{"_$method"};
    }

    return if $method eq 'DESTROY';

    die "“$class” doesn’t define a method “$method”!";
}

1;
