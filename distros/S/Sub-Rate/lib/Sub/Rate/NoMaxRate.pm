package Sub::Rate::NoMaxRate;
use strict;
use warnings;
use Any::Moose;

use List::Util 'sum';

extends 'Sub::Rate';

has '+max_rate' => 'default' => 0;

before add => sub {
    my ($self, $rate) = @_;
    $self->max_rate($self->max_rate + $rate);
};

after clear => sub {
    my ($self) = @_;
    $self->max_rate(0);
};

__PACKAGE__->meta->make_immutable;

__END__

=for stopwords SUBs sublist

=head1 NAME

Sub::Rate::NoMaxRate - auto calculate max_rate

=head1 SYNOPSIS

    my $rate = Sub::Rate::NoMaxRate->new;
    $rate->add( 10 => sub { ... } );     # sub1
    $rate->add( 20 => sub { ... } );     # sub2
    
    my $func = $rate->generate;

    # Calling this $func then:
    # sub1 will be called by rate about 10/30
    # sub2 will be called by rate about 20/30
    $func->();
    
=head1 DESCRIPTION

Sub::Rate::NoMaxRate is a subclass of L<Sub::Rate>.

This module has no C<max_rate> option and calculate it automatically.

=head1 CLASS METHODS

=head2 new(%options)

    my $obj = Sub::Rate->new;

Create Sub::Rate object.

Available options are:

=over

=item * rand_func => 'CodeRef'

Random calculate function. Default is:

    sub {
        CORE::rand($_[0]);
    };

You can change random function to your own implementation by this option.
C<max_rate> is passed as C<$_[0]> to this function.

=back

=head2 METHODS

=head2 add($rate : Number|Str, $sub :CodeRef)

    $obj->add( 10, sub { ... } );
    $obj->add( 20, sub { ... } );
    $obj->add( 'default', sub { ... } );

Add C<$sub> to internal sublist rate by C<$rate>.

If C<$rate> is not number but "default", then C<$sub> is registered as default sub.
If default sub is already registered, it will be replaced.

=head2 generate()

    my $sub = $obj->generate;

Create a new sub that dispatch functions by its rates.

=head2 clear()

    $obj->clear;

Clear all registered functions and default function.

=head1 AUTHOR

Daisuke Murase <typester@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012 KAYAC Inc. All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

