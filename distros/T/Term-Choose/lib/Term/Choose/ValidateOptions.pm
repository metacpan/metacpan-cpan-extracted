package Term::Choose::ValidateOptions;

use warnings;
use strict;
use 5.008003;

our $VERSION = '1.654';

use Exporter qw( import );

our @EXPORT_OK = qw( validate_options );

use Carp qw( croak );

sub validate_options {
    my ( $valid, $opt ) = @_;
    return if ! defined $opt; #
    my $sub =  ( caller( 1 ) )[3];
    $sub =~ s/^.+::(?:__)?([^:]+)\z/$1/;
    for my $key ( keys %$opt ) {
        if ( ! exists $valid->{$key} ) {
            croak "$sub: '$key' is not a valid option name";
        }
        next if ! defined $opt->{$key};
        if ( $valid->{$key} eq 'ARRAY' ) {
            croak "$sub: option '$key' => the passed value has to be an ARRAY reference." if ref $opt->{$key} ne 'ARRAY';
            {
                no warnings 'uninitialized';
                for ( @{$opt->{$key}} ) {
                    /^[0-9]+\z/ or croak "$sub: option '$key' => $_ is an invalid array element";
                }
            }
            if ( $key eq 'lf' ) {
                croak "$sub: option '$key' => too many array elements." if @{$opt->{$key}} > 2;
            }
        }
        elsif ( ref $opt->{$key} ) {
            croak "$sub: option '$key' => a reference is not a valid value.";
        }
        elsif ( $valid->{$key} eq 'Str' ) {
        }
        elsif ( $opt->{$key} !~ m/^$valid->{$key}\z/x ) {
            croak "$sub: option '$key' => '$opt->{$key}' is not a valid value.";
        }
    }
}






1;
