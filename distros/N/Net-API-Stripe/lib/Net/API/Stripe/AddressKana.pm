##----------------------------------------------------------------------------
## Stripe API - ~/lib/Net/API/Stripe/AddressKana.pm
## Version 0.1
## Copyright(c) 2019-2020 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/11/02
## Modified 2019/11/02
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Net::API::Stripe::AddressKana;
BEGIN
{
    use strict;
    use parent qw( Net::API::Stripe::Address );
    our( $VERSION ) = '0.1';
};

1;

__END__

=encoding utf8

=head1 NAME

Net::API::Stripe::AddressKana - A Stripe Japanese Address Object

=head1 SYNOPSIS

   my $addr = $stripe->address({
       line1 => 'ちよだくくだんみなみ1-2-3',
       line2 => 'だいびる12かい',
       city => 'とうきょうと',
       postal_code => '123-4567',
       country => 'jp',
   });

=head1 VERSION

    0.1

=head1 DESCRIPTION

This module inherits everything from L<Net::API::Stripe::Address>

This is used to store the address in its kana version.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

Stripe API documentation:

L<https://stripe.com/docs/api>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
