package Protocol::DBus::Address;

use strict;
use warnings;

use Call::Context;

# Not a very choosy parser, and it doesn’t try to validate anything.
sub parse {
    Call::Context::must_be_list();

    return map {
        my $str = $_;

        my $xport = substr( $_, 0, 1 + index($_, ':'), q<> );
        chop $xport;

        my %kvs = (
            map { split m<=>, $_ } (split m<,>, $_),
        );

        s<%(..)><chr hex $1>ge for values %kvs;

        bless { _str => $str, _transport => $xport, _attrs => \%kvs }, __PACKAGE__;
    } ( split m<;>, $_[0] );
}

#----------------------------------------------------------------------

sub transport {
    return $_[0]{'_transport'};
}

sub to_string {
    return $_[0]{'_str'};
}

sub attribute {
    return $_[0]{'_attrs'}{$_[1]};
}

1;
