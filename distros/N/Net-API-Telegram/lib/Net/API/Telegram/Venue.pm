# -*- perl -*-
##----------------------------------------------------------------------------
## Net/API/Telegram/Venue.pm
## Version 0.1
## Copyright(c) 2019 Jacques Deguest
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/05/29
## Modified 2020/03/28
## All rights reserved.
## 
## This program is free software; you can redistribute it and/or modify it 
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Net::API::Telegram::Venue;
BEGIN
{
	use strict;
	use parent qw( Net::API::Telegram::Generic );
    our( $VERSION ) = '0.1';
};

sub address { return( shift->_set_get_scalar( 'address', @_ ) ); }

sub foursquare_id { return( shift->_set_get_scalar( 'foursquare_id', @_ ) ); }

sub foursquare_type { return( shift->_set_get_scalar( 'foursquare_type', @_ ) ); }

sub location { return( shift->_set_get_object( 'location', 'Net::API::Telegram::Location', @_ ) ); }

sub title { return( shift->_set_get_scalar( 'title', @_ ) ); }

1;

__END__

=encoding utf-8

=head1 NAME

Net::API::Telegram::Venue - A venue

=head1 SYNOPSIS

	my $msg = Net::API::Telegram::Venue->new( %data ) || 
	die( Net::API::Telegram::Venue->error, "\n" );

=head1 DESCRIPTION

L<Net::API::Telegram::Venue> is a Telegram Message Object as defined here L<https://core.telegram.org/bots/api#venue>

This module has been automatically generated from Telegram API documentation by the script scripts/telegram-doc2perl-methods.pl.

=head1 METHODS

=over 4

=item B<new>( {INIT HASH REF}, %PARAMETERS )

B<new>() will create a new object for the package, pass any argument it might receive
to the special standard routine B<init> that I<must> exist. 
Then it returns what returns B<init>().

The valid parameters are as follow. Methods available here are also parameters to the B<new> method.

=over 8

=item * I<verbose>

=item * I<debug>

=back

=item B<address>( String )

Address of the venue

=item B<foursquare_id>( String )

Optional. Foursquare identifier of the venue

=item B<foursquare_type>( String )

Optional. Foursquare type of the venue. (For example, I<arts_entertainment/default>, I<arts_entertainment/aquarium> or I<food/icecream>.)

=item B<location>( L<Net::API::Telegram::Location> )

Venue location

=item B<title>( String )

Name of the venue

=back

=head1 COPYRIGHT

Copyright (c) 2000-2019 DEGUEST Pte. Ltd.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Net::API::Telegram>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2018-2019 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut

