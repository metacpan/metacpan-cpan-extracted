package Specio::Library::NoInline;

use strict;
use warnings;

use parent 'Specio::Exporter';

use Specio::Declare;
use Specio::Library::Builtins;

declare(
    'IntNI',
    parent => t('Defined'),
    where  => sub {
        (
                   defined( $_[0] )
                && !ref( $_[0] )
                && (
                do {
                    ( my $val1 = $_[0] ) =~ /\A-?[0-9]+(?:[Ee]\+?[0-9]+)?\z/;
                }
                )
            )
            || (
               Scalar::Util::blessed( $_[0] )
            && overload::Overloaded( $_[0] )
            && defined overload::Method( $_[0], '0+' )
            && do {
                ( my $val2 = $_[0] + 0 ) =~ /\A-?[0-9]+(?:[Ee]\+?[0-9]+)?\z/;
            }
            );
    },
);

1;
