package Sub::Rate;
use strict;
use warnings;
use Any::Moose;
use Carp;

our $VERSION = '0.05';

has max_rate => (
    is      => 'rw',
    default => 100,
);

has rand_func => (
    is      => 'rw',
    default => sub {
        return sub { rand($_[0]) };
    },
);

has sort => (
    is      => 'rw',
    default => 0,
);

has _func => (
    is      => 'rw',
    default => sub { [] },
);

has _default_func => (
    is => 'rw',
);

no Any::Moose;

sub add {
    my ($self, $rate, $func) = @_;

    if ($rate eq 'default') {
        $self->_default_func($func);
    }
    else {
        my $total_rate = 0;
        $total_rate += $_->[0] for @{ $self->_func };

        if ($total_rate + $rate > $self->max_rate) {
            croak sprintf 'Exceed max_rate, current:%s max:%s',
                $total_rate + $rate, $self->max_rate;
        }

        push @{ $self->_func }, [ $rate, $func ];
    }
}

sub generate {
    my ($self) = @_;

    my @sorted_funcs = @{ $self->_func };
    @sorted_funcs = sort { $a->[0] <=> $b->[0] } @sorted_funcs if $self->sort;

    my $rand         = $self->rand_func;
    my $max_rate     = $self->max_rate;
    my $default_func = $self->_default_func;

    sub {
        my @args = @_;

        my $index  = $rand->( $max_rate );
        my $cursor = 0;

        for my $f (@sorted_funcs) {
            $cursor += $f->[0];

            if ($index <= $cursor) {
                return $f->[1]->(@args);
            }
        }

        if ($default_func) {
            return $default_func->(@args);
        }
        else {
            return;
        }
    };
}

sub clear {
    my ($self) = @_;
    $self->_func([]);
    $self->_default_func(undef);
}

__PACKAGE__->meta->make_immutable;

__END__

=for stopwords SUBs sublist

=head1 NAME

Sub::Rate - Rate based sub dispatcher generator

=head1 SYNOPSIS

    my $rate = Sub::Rate->new( max_rate => 100 );
    $rate->add( 10 => sub { ... } );     # sub1
    $rate->add( 20 => sub { ... } );     # sub2
    $rate->add( default => sub { ... }); # default sub
    
    my $func = $rate->generate;

    # Calling this $func then:
    # sub1 will be called by rate about 10/100 (10%),
    # sub2 will be called by rate about 20/100 (20%),
    # default sub will be called in rest case (70%),
    $func->();
    
=head1 DESCRIPTION

Sub::Rate generates a SUB that will dispatch some SUBs by specified rate.

=head1 CLASS METHODS

=head2 new(%options)

    my $obj = Sub::Rate->new;

Create Sub::Rate object.

Available options are:

=over

=item * max_rate => 'Number'

Max rate. (Default: 100)

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

