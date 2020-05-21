# -*- perl -*-
##----------------------------------------------------------------------------
## Net/API/Telegram/Location.pm
## Version 0.1
## Copyright(c) 2019 Jacques Deguest
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/05/29
## Modified 2020/05/20
## All rights reserved.
## 
## This program is free software; you can redistribute it and/or modify it 
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Net::API::Telegram::Location;
BEGIN
{
	use strict;
	use parent qw( Net::API::Telegram::Generic );
    our( $VERSION ) = '0.1';
};

sub latitude { return( shift->_set_get_number( 'latitude', @_ ) ); }

sub longitude { return( shift->_set_get_number( 'longitude', @_ ) ); }

1;

__END__

=encoding utf-8

=head1 NAME

Net::API::Telegram::Location - A point on the map

=head1 SYNOPSIS

	my $msg = Net::API::Telegram::Location->new( %data ) || 
	die( Net::API::Telegram::Location->error, "\n" );

=head1 DESCRIPTION

L<Net::API::Telegram::Location> is a Telegram Message Object as defined here L<https://core.telegram.org/bots/api#location>

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

=item B<latitude>( Float )

Latitude as defined by sender

=item B<longitude>( Float )

Longitude as defined by sender

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

