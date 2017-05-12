package MooseX::Types::NetAddr::IP;

use strict;
use warnings;

our $VERSION = '0.07';

use Module::Runtime      qw/use_module/;
use MooseX::Types::Moose qw/Str ArrayRef/;
use namespace::clean;
use MooseX::Types -declare => [qw( NetAddrIP NetAddrIPv4 NetAddrIPv6 )];

class_type 'NetAddr::IP';

subtype NetAddrIP,   as 'NetAddr::IP';  # can be either IPv4 or IPv6
subtype NetAddrIPv4, as 'NetAddr::IP';  # can be only IPv4
subtype NetAddrIPv6, as 'NetAddr::IP';  # can be only IPv6

coerce NetAddrIP, 
    from Str, 
    via { 
        return use_module('NetAddr::IP')->new( $_ )
            || die "'$_' is not an IP address.\n";
    };

coerce NetAddrIP, 
    from ArrayRef[Str], 
    via { 
        return use_module('NetAddr::IP')->new( @$_ )
            || die "'@$_' is not an IP address.\n";
    };

sub createAddress ($@) {
    my $version = shift;

    my $ipaddr = use_module('NetAddr::IP')->new( @_ )
        || die "'@_' is not an IPv$version address.\n";

    die "'@_' is not an IPv$version address."
        unless $ipaddr->version == $version;

    return $ipaddr;
}

coerce NetAddrIPv4,
    from Str,
    via { createAddress 4 => $_ };

coerce NetAddrIPv4,
    from ArrayRef[Str],
    via { createAddress 4 => @$_ };

coerce NetAddrIPv6,
    from Str,
    via { createAddress 6 => $_ };

coerce NetAddrIPv6,
    from ArrayRef[Str],
    via { createAddress 6 => @$_ };

1;
__END__

=head1 NAME

MooseX::Types::NetAddr::IP - NetAddr::IP related types and coercions for Moose

=head1 SYNOPSIS

  use MooseX::Types::NetAddr::IP qw( NetAddrIP NetAddrIPv4 NetAddrIPv6 );

=head1 DESCRIPTION

This package provides internet address types for Moose.

=head2 TYPES

NetAddrIP

    Coerces from Str and ArrayRef via "new" in NetAddr::IP. 

NetAddrIPv4

    Coerces from Str and ArrayRef via "new" in NetAddr::IP.

NetAddrIPv6

    Coerces from Str and ArrayRef via "new" in NetAddr::IP.

=head1 SEE ALSO

L<NetAddr::IP>, L<MooseX::Types>

=head1 AUTHOR

Todd Caine, E<lt>todd.caine@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Todd Caine

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
