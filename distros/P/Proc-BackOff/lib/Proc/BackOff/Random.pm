package Proc::BackOff::Random;

# Inheritance
use base qw( Proc::BackOff );

# Set up get/set fields
# 2 ^ 5
# 2 is the base
# 5 is the exponent

__PACKAGE__->mk_accessors( 'min',
                           'max',
);

# standard pragmas
use warnings;
use strict;

# standard perl modules

# CPAN & others

our $VERSION = '0.02';

=head1 NAME

Proc::BackOff::Random

=head1 SYNOPSIS

Usage:

 use Proc::BackOff::Random;

 my $obj = Proc::BackOff::Random->new( { min => 5 , max => 100 } );
 # On N'th failure delay would be set to:
 # 1st failure  :  a random number between 5 and 100 inclusive.
 #                 (5 is a possible value)
 # 2nd failure  :  a random number between 5 and 100 inclusive.
 # 3rd failure  :  a random number between 5 and 100 inclusive.

See L<Proc::BackOff> for further documentation.

=head1 Overloaded Methods

=head2 new()

Check for variables being set: min & max.  If they are not set, you will get a
warning and undef will be returned.

=cut

sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;
    my $obj = $class->SUPER::new(@_);

    if ( ! defined $obj->min() || ! $obj->valid_number_check($obj->min())) {
        warn "$proto: Minimum value not set";
        return undef;
    }

    if ( ! defined $obj->max() || ! $obj->valid_number_check($obj->max())) {
        warn "$proto: Maximum value not set";
        return undef;
    }

    if ( $obj->min() ne 'count' && $obj->max() ne 'count' && $obj->min() > $obj->max()) {
        warn "$proto: Minimum is greater than Maximum";
        return undef;
    }

    return $obj;
}

=head2 calculate_back_off()

Returns the new back off value.

=cut

sub calculate_back_off {
    my $self = shift;

    # this is an Random back off
    my $min = $self->min();
    my $max = $self->max();

    $min = $self->failure_count() if $min eq 'count';
    $max = $self->failure_count() if $max eq 'count';

    return int (rand($max-$min) + $min);
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
