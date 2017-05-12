package MooseX::Locked::Class;

use 5.008;
use strict;
use warnings FATAL => 'all';

use Moose::Role;
use Hash::Util ();

around new_object => sub {
    my $orig = shift;
    my $class = shift;
    my $self = $class->$orig(@_);
    Hash::Util::lock_keys %$self, $class->_all_attr_names;
    $self
};

around _inline_extra_init => sub {
    my $orig = shift;
    my $self = shift;
    my @code = $self->$orig(@_);

    my @k = $self->_all_attr_names
      or return @code;
    die "Too lazy to inline oddly named attribute(s): @k" if grep /'/, @k;
    my $qk = join ',', map "'$_'", @k;
    return (@code, 'Hash::Util::lock_keys %$instance, '."$qk;\n");
};

sub _all_attr_names {
    my $self = shift;
    map { $_->name } $self->get_all_attributes;
}

no Moose::Role;

1;
