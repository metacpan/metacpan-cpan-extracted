##----------------------------------------------------------------------------
## REST API Framework - ~/lib/Net/API/REST/Status.pm
## Version v1.0.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/12/15
## Modified 2023/06/10
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Net::API::REST::Status;
BEGIN
{
    use strict;
    use warnings;
    use common::sense;
    use parent qw( Apache2::API::Status );
    use vars qw( $VERSION );
    our $VERSION = 'v1.0.0';
};

use strict;
use warnings;

1;
# NOTE: POD
__END__

=encoding utf8

=head1 NAME

Net::API::REST::Status - Apache2 Status Codes

=head1 SYNOPSIS

    say $Net::API::REST::Status::CODES->{429};
    # returns Apache constant Apache2::Const::HTTP_TOO_MANY_REQUESTS

    say $Net::API::REST::Status::HTTP_CODES->{fr_FR}->{429} # Trop de requête
    # In Japanese: リクエスト過大で拒否した
    say $Net::API::REST::Status::HTTP_CODES->{ja_JP}->{429}

But maybe more simply:

    my $status = Net::API::REST::Status->new;
    say $status->status_message( 429 => 'ja_JP' );
    # Or without the language code parameter, it will default to en_GB
    say $status->status_message( 429 );

    # Is success
    say $status->is_info( 102 ); # true
    say $status->is_success( 200 ); # true
    say $status->is_redirect( 302 ); # true
    say $status->is_error( 404 ); # true
    say $status->is_client_error( 403 ); # true
    say $status->is_server_error( 501 ); # true

=head1 VERSION

    v1.0.0

=head1 DESCRIPTION

As of version C<1.0.0>, this module inherits all of its methods from L<Apache2::API::Status>. Please check its documentation directly.

=head2 SEE ALSO

Apache distribution and file C<httpd-2.x.x/include/httpd.h>

L<IANA HTTP codes list|http://www.iana.org/assignments/http-status-codes/http-status-codes.xhtml>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2023 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
