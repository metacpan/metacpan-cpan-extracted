package Term::Choose::ValidateOptions;

use warnings;
use strict;
use 5.10.1;

our $VERSION = '1.775';

use Exporter qw( import );

our @EXPORT_OK = qw( validate_options );

use Carp qw( croak );


sub validate_options {
    my ( $valid, $opt, $caller ) = @_;
    return if ! defined $opt; #
    if ( ! defined $caller ) { #
        $caller = '';
    };
    for my $key ( keys %$opt ) {
        if ( ! exists $valid->{$key} ) {
            croak "$caller: '$key' is not a valid option name";
        }
        next if ! defined $opt->{$key};
        if ( $valid->{$key} =~ /^Array/ ) {
            croak "$caller: option '$key' => the passed value has to be an ARRAY reference." if ref $opt->{$key} ne 'ARRAY';
            if ( $valid->{$key} eq 'Array_Int' ) {
                for ( @{$opt->{$key}} ) {
                    defined or croak "$caller: option '$key' => undefined array element";
                    /^[0-9]+\z/ or croak "$caller: option '$key' => $_ is an invalid array element";
                }
            }
        }
        elsif ( $valid->{$key} =~ /^Regexp/ ) {
            croak "$caller: option '$key' => the passed value has to be a regex quoted with the 'qr' operator." if ref $opt->{$key} ne 'Regexp';
        }
        elsif ( ref $opt->{$key} ) {
            croak "$caller: option '$key' => a reference is not a valid value.";
        }
        elsif ( $valid->{$key} eq 'Str' ) {
        }
        elsif ( $opt->{$key} !~ m/^$valid->{$key}\z/x ) {
            croak "$caller: option '$key' => '$opt->{$key}' is not a valid value.";
        }
    }
}






1;
