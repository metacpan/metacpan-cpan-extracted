package Proc::BackOff::Exponential;

# Inheritance
use base qw( Proc::BackOff );

# Set up get/set fields
# 2 ^ 5
# 2 is the base
# 5 is the exponent

__PACKAGE__->mk_accessors( 'base',
                           'exponent',
);

# standard pragmas
use warnings;
use strict;

# standard perl modules

# CPAN & others

our $VERSION = '0.01';

=head1 NAME

Proc::BackOff::Exponential

=head1 SYNOPSIS

Usage:

 use Proc::BackOff::Exponential;

 my $obj = Proc::BackOff::Exponential->new( { base => 2 , exponent=> 'count' } );
 # On N'th failure delay would be set to:
 # 1st failure  :  2^1 = 2
 # 2nd failure  :  2^2 = 4
 # 3rd failure  :  2^3 = 8
 # 4th failure  :  2^4 = 16

 # or

 my $obj = Proc::BackOff::Exponential->new( { base => 'count' , exponent=> 2 } );
 # On N'th failure delay would be set to:
 # 1st failure  :  1^2 = 1
 # 2nd failure  :  2^2 = 4
 # 3rd failure  :  3^2 = 9
 # 4th failure  :  4^2 = 16

See L<Proc::BackOff> for further documentation.

=head1 Overloaded Methods

=head2 new()

Check for variables being set

Required: base
Required: exponent

=cut

sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;
    my $obj = $class->SUPER::new(@_);

    if ( ! defined $obj->exponent() || ! $obj->valid_number_check($obj->exponent())) {
        warn "$proto: Exponent value not set";
        return undef;
    }

    if ( ! defined $obj->base() || ! $obj->valid_number_check($obj->base())) {
        warn "$proto: Base value not set";
        return undef;
    }

    return $obj;
}

=head2 calculate_back_off()

Returns the new back off value.

=cut

sub calculate_back_off {
    my $self = shift;

    # this is an exponential back off

    my $exponent = $self->exponent();
    my $base = $self->base();

    $exponent = $self->failure_count() if $exponent eq 'count';
    $base = $self->failure_count() if $base eq 'count';

    return $base ^ $exponent;
}

=cut

1;

=head1 Changes

 0.02   2007-08-12 -- Daniel Lo
        - Documentation fixes.  No code changes.

 0.01   2007-04-17 -- Daniel Lo
        - Initial Version

=head1 AUTHOR

Daniel Lo <daniel_lo@picturetrail.com>

=head1 LICENSE

Copyright (C) PictureTrail Inc. 1999-2007
Santa Clara, California, United States of America.

This code is released to the public for public use under Perl's Artisitic
licence.

=cut
