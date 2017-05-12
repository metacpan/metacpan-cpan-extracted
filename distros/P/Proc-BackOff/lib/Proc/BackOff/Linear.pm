package Proc::BackOff::Linear;

# Inheritance
use base qw( Proc::BackOff );

# Set up get/set fields
__PACKAGE__->mk_accessors( 'slope',
                           'x',
                           'b',
);

# standard pragmas
use warnings;
use strict;

# standard perl modules

# CPAN & others

our $VERSION = '0.02';

=head1 NAME

Proc::BackOff::Linear

=head1 SYNOPSIS

Usage:

 use Proc::BackOff::Linear;

 my $obj = Proc::BackOff::Linear->new( { slope => 5, x => 'count', b => 0 );
 # On N'th failure delay would be set to:
 # y = slope * x + b;
 # 1st failure  :  5 * count + b = 5 * 1 + 0 = 5
 # 2nd failure  :  5 * 2 + 0 = 10
 # 3rd failure  :  5 * 3 + 0 = 15
 # 4th failure  :  5 * 4 + 0 = 20

See L<Proc::BackOff> for further documentation.

=head1 Overloaded Methods

=head2 new()

Check for variables being set:

Required: slope
 b defaults to 0
 x defaults to 'count'

=cut

sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;
    my $obj = $class->SUPER::new(@_);

    if ( ! defined $obj->slope() || ! $obj->valid_number_check($obj->slope())) {
        warn "$proto: Slope value not set";
        return undef;
    }

    if ( ! defined $obj->b() || ! $obj->valid_number_check($obj->b())) {
        warn "$proto: b value not set";
        $obj->b(0) unless defined $obj->b();
        return undef unless $obj->valid_number_check($obj->b());
    }

    if ( ! defined $obj->x() || ! $obj->valid_number_check($obj->x())) {
        warn "$proto: x value not set";
        $obj->x(0) unless defined $obj->x();
        return undef unless $obj->valid_number_check($obj->x());
    }

    return $obj;
}

=head2 calculate_back_off()

Returns the new back off value.

=cut

sub calculate_back_off {
    my $self = shift;

    # this is a linear back off
    # y = slope * x + b;
    # b = 0
    # y = slope * x ;
    # x = failure_count
    # y = timeout
    # slope = add_timeout
    # timeout = add_timeout * failure_count

    my $slope = $self->slope();
    my $x     = $self->x();
    my $b     = $self->b();

    $slope = $self->failure_count() if $slope eq 'count';
    $x     = $self->failure_count() if $x eq 'count';
    $b     = $self->failure_count() if $b eq 'count';

    return $slope * $x + $b;
}

1;

=head1 Changes

 0.02   2007-08-12 -- Daniel Lo
        - Documentation fixes.  No code changes.

 0.01    2007-04-17 -- Daniel Lo
        - Initial Version

=head1 AUTHOR

Daniel Lo <daniel_lo@picturetrail.com>

=head1 LICENSE

Copyright (C) PictureTrail Inc. 1999-2007
Santa Clara, California, United States of America.

This code is released to the public for public use under Perl's Artisitic
licence.

=cut
