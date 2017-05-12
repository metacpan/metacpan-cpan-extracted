package Net::Works::Types;

use strict;
use warnings;

our $VERSION = '0.22';

use Carp qw( confess );
use Exporter qw( import );
use Scalar::Util ();
use Sub::Quote qw( quote_sub );

our @EXPORT_OK = qw(
    Int
    IPInt
    IPVersion
    PrefixLength
    NetWorksAddress
    PackedBinary
    Str
);

## no critic (ValuesAndExpressions::ProhibitImplicitNewlines, NamingConventions::Capitalization)
{
    my $t = quote_sub(
        q{
( defined $_[0] && !ref $_[0] && $_[0] =~ /^[0-9]+\z/ )
    or Net::Works::Types::_confess(
    '%s is not a valid integer for an IP address',
    $_[0]
    );
}
    );

    sub Int () { $t }
}

{
    my $t = quote_sub(
        q{
(
    defined $_[0] && ( ( !ref $_[0] && $_[0] =~ /^[0-9]+\z/ )
        || ( Scalar::Util::blessed( $_[0] )
            && ( $_[0]->isa('Math::UInt128') || $_[0]->isa('Math::BigInt') ) )
        )
    )
    or Net::Works::Types::_confess(
    '%s is not a valid integer for an IP address',
    defined $_[0] ? $_[0] : 'undef'
    );
}
    );

    sub IPInt () { $t }
}

{
    my $t = quote_sub(
        q{
( defined $_[0] && !ref $_[0] && ( $_[0] == 4 || $_[0] == 6 ) )
    or Net::Works::Types::_confess(
    '%s is not a valid IP version (4 or 6)',
    defined $_[0] ? $_[0] : 'undef'
    );
        }
    );

    sub IPVersion () { $t }
}

{
    my $t = quote_sub(
        q{
( !ref $_[0] && defined $_[0] && $_[0] =~ /^[0-9]+\z/ && $_[0] <= 128 )
    or Net::Works::Types::_confess(
    '%s is not a valid IP network prefix length (0-128)',
    defined $_[0] ? $_[0] : 'undef'
    );
}
    );

    sub PrefixLength () { $t }
}

{
    my $t = quote_sub(
        q{
( Scalar::Util::blessed( $_[0] ) && $_[0]->isa('Net::Works::Address') )
    or Net::Works::Types::_confess(
    '%s is not a Net::Works::Address object',
    $_[0]
    );
}
    );

    sub NetWorksAddress () { $t }
}

{
    my $t = quote_sub(
        q{
( defined $_[0] && !ref $_[0] )
    or Net::Works::Types::_confess( '%s is not binary data', $_[0] );
}
    );

    sub PackedBinary () { $t }
}

{
    my $t = quote_sub(
        q{
( defined $_[0] && !ref $_[0] )
    or Net::Works::Types::_confess( '%s is not a string', $_[0] );
}
    );

    sub Str () { $t }
}
## use critic

## no critic (Subroutines::ProhibitUnusedPrivateSubroutines, Variables::ProhibitPackageVars)
sub _confess {
    local $Carp::Internal{__PACKAGE__} = 1;

    confess sprintf(
        $_[0],
        defined $_[1] ? $_[1] : 'undef'
    );
}
## use critic

1;
