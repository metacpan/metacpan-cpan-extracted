package String::Normal::Type::State;
use strict;
use warnings;

use String::Normal::Config::States;

our $codes;

sub transform {
    my ($self,$value) = @_;

    if (length($value) > 2) {
        # convert long name to short name (with potential invalidation)
        $value = $codes->{by_long}{$value} || '';
    }
    elsif (! $codes->{by_short}{$value}) {
        # invalidate short name
        $value = '';
    }

    # now validate against country code
    # TODO: contemplate moving country awareness to a higher level
    #       if more fields require such validation (hint ... zipcodes)
#    if ($values[$schema{country}] eq 'US') {
#        $value = '' unless $us_codes->{$value};
#    }
#    elsif ($values[$schema{country}] eq 'CA') {
#        $value = '' unless $ca_codes->{$value};
#    }

    if ($value) {
        return $value;
    }
    else {
        die "invalid state";
    }

}

sub new {
    my $self = shift;
    $codes = String::Normal::Config::States::_data( @_ );
    return bless {@_}, $self;
}

1;

__END__
=head1 NAME

String::Normal::Type::State;

=head1 DESCRIPTION

This package defines substitutions to be performed on State types.

=head1 METHODS

=over 4

=item C<new( %params )>

    my $state = String::Normal::Type::State->new;

Creates a State type.

=item C<transform( $value )>

    my $new_value = $state->transform( $value );

Transforms a value according to the rules of a State type.

=back
