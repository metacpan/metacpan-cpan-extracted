=head1 NAME

RT::Authen::Bitcard - Allows RT to do authentication via a service which supports the Bitcard API

=cut

package RT::Authen::Bitcard;

use v5.8.3;
use strict;
use warnings;

our $VERSION = '0.04';

use Authen::Bitcard 0.86;

sub handler {
    my $self = shift;

    die 'No Bitcard auth token provided as $BitcardToken in the RT configuration file on this server.'
        unless $RT::BitcardToken;

    my $bc = Authen::Bitcard->new;
    $bc->token( $RT::BitcardToken );
    $bc->info_required('email,username');
    $bc->info_optional('name');
    return $bc;
}

1;

=head1 AUTHOR

Kevin Riggle E<lt>kevinr@bestpractical.comE<gt>

=head1 COPYRIGHT

This extension is Copyright (C) 2005-2008 Best Practical Solutions, LLC.

It is freely redistributable under the terms of version 2 of the GNU GPL.

=cut

