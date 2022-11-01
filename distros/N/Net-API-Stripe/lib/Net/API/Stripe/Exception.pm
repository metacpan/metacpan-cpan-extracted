##----------------------------------------------------------------------------
## Stripe API - ~/lib/HTTP/Promise/Exception.pm
## Version v0.1.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/10/18
## Modified 2022/10/18
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Net::API::Stripe::Exception;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic::Exception );
    our $VERSION = 'v0.1.0';
};

sub request_log_url { return( shift->_set_get_uri( 'request_log_url', @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Net::API::Stripe::Exception - Stripe Exception

=head1 SYNOPSIS

    use Net::API::Stripe::Exception;
    my $this = Net::API::Stripe::Exception->new( $error_message ) || 
        die( Net::API::Stripe::Exception->error, "\n" );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This class inherits all its methods from L<Module::Generic::Exception>

=head1 METHODS

Please see L<Module::Generic::Exception> for details.

=head2 request_log_url

The uri in the dashboard to get details about the error that occurred.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Module::Generic::Exception>

L<Net::API::Stripe>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
