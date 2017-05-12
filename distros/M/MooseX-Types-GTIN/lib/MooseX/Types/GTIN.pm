package MooseX::Types::GTIN;
our $VERSION = '0.03';

=head1 NAME

MooseX::Types::GTIN - Moose types for Global Trade Identifiers.

=head1 SYNOPSIS

    use MooseX::Types::GTIN qw/ GTIN ISBN10 /;

    is_GTIN(829410333658); # returns true
    to_GTIN("  829410333658 "); # returns 829410333658

    is_ISBN10(0974514055); # returns true
    to_GTIN(0974514055); # returns 9780974514055

    use Moose;
    has barcode => ( is => "rw", isa => GTIN );
    has isbn =>    ( is => "rw", isa => ISBN10 );

=head1 DESCRIPTION

This package provides L<Moose> types for "Global Trade Identifiers, also
known as UPCs and EANs.  8, 12, 13 and 14 digital varients of GTINs are
supported, along with 10 digit ISBN numbers.  The checksum of GTINs are
validated, ISBN numbers are only checked for the correct form.

=head1 SEE ALSO

=over

=item *

L<MooseX::Types>

=item *

L<http://www.gs1.org/barcodes/support/check_digit_calculator>

=back

=head1 AUTHOR

=over

=item *

Dave Lambley <davel@state51.co.uk>, on behalf of his employer,
L<http://www.state51.co.uk>.

=back

=cut

use MooseX::Types::Moose qw/Int Str/;
use MooseX::Types
    -declare => [qw(
        GTIN
        ISBN10
    )];

# import builtin types
use Moose::Util::TypeConstraints;
use MooseX::Types::GTIN::Validate;
use Try::Tiny;

subtype GTIN, as Int,
    where { try { MooseX::Types::GTIN::Validate::assert_gtin($_); 1; } },
    message { local $@; eval { MooseX::Types::GTIN::Validate::assert_gtin($_); }; my $error = $@; $error =~ / at.+/; $error };

subtype ISBN10, as Int,
    where { /^\d{9}(?:\d|X|x)$/ },
    message { "Wrong form to be a ISBN10" };

coerce GTIN,
        from ISBN10,
            via {
                $_ = '978'.substr($_, 0, -1); # Prepend 978, Throw away last digit
                $_ .= MooseX::Types::GTIN::Validate::calc_mod10_check_digit($_); # Add checksum
                return $_;
            },
        from subtype(Str => where { /\s*(?:\d{8}|\d{12,14})\s*$/ }),
            via  { # Just trim all whitespace
                    s!\s+!!g;

                    # Magic workaround for spreadsheets eating the first digit
                    # of a UPC.
                    if (length($_)==11) {
                        return "0$_";
                    }
                    else {
                        return $_;
                    }
               };

coerce ISBN10, from subtype(Str => where { /\s*\d{9}(?:\d|X|x)\s*$/ }),
               via  { # Just trim all whitespace
                    s!\s+!!g; $_;
               };

1;

