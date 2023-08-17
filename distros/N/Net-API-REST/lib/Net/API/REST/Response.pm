# -*- perl -*-
##----------------------------------------------------------------------------
## REST API Framework - ~/lib/Net/API/REST/Response.pm
## Version v1.0.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/09/01
## Modified 2023/06/10
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Net::API::REST::Response;
BEGIN
{
    use strict;
    use warnings;
    use common::sense;
    use parent qw( Apache2::API::Response );
    use vars qw( $VERSION );
    our $VERSION = 'v1.0.0';
};

use strict;
use warnings;

# sub init is inherited

sub request { return( shift->_set_get_object( 'request', 'Net::API::REST::Request', @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf8

=head1 NAME

Net::API::REST::Response - Apache2 Outgoing Response Access and Manipulation

=head1 SYNOPSIS

    use Net::API::REST::Response;
    ## $r is the Apache2::RequestRec object
    my $req = Net::API::REST::Request->new( request => $r, debug => 1 );
    ## or, to test it outside of a modperl environment:
    my $req = Net::API::REST::Request->new( request => $r, debug => 1, checkonly => 1 );

=head1 VERSION

    v1.0.0

=head1 DESCRIPTION

The purpose of this module is to provide an easy access to various method to process and manipulate outgoing response.

This module inherits all of its methods from L<Apache2::API::Response>. Please check its documentation directly.

For its alter ego to manipulate incoming http request, use the L<Net::API::REST::Request> module.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Apache2::API::Response>, L<Apache2::API::Request>, L<Apache2::API>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2018-2023 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
