package Slackware::Slackget::Network::Backend::Gzip;

use warnings;
use strict;
require Slackware::Slackget::Network::Message ;
require Compress::Zlib ;
require IO::Uncompress::Gunzip;

=head1 NAME

Slackware::Slackget::Network::Backend::Gzip - Gzip (Zlib) backend for slack-get network protocol

=head1 VERSION

Version 0.8.0

=cut

our $VERSION = '0.8.1';

=head1 SYNOPSIS

Still to do

=cut

sub new
{
	my ($class,%args) = @_ ;
	my $self = {%args};
	bless($self,$class);
	print "[Slackware::Slackget::Network::Backend::Gzip] constructing a new object (version: $VERSION).\n" if($ENV{SG_DAEMON_DEBUG}) ;
	return $self;
}

=head1 CONSTRUCTOR

=head2 new

Still to do

=head1 FUNCTIONS

All methods return a Slackware::Slackget::Network::Message (L<Slackware::Slackget::Network::Message>) object, and if the remote slack-getd return some data they are accessibles via the data() accessor of the Slackware::Slackget::Network::Message object.

=cut

=head2 backend_decode

=cut

sub backend_decode {
	my $self = shift;
	my $Gzip_msg = shift;
	print "[Slackware::Slackget::Network::Backend::Gzip] call backend_decode($Gzip_msg).\n" if($ENV{SG_DAEMON_DEBUG}) ;
	my $raw = $Gzip_msg->data();
	print "[Slackware::Slackget::Network::Backend::Gzip] raw data are : \n$raw.\n" if($ENV{SG_DAEMON_DEBUG}) ;
	my $raw_bis = $raw;
	print Compress::Zlib::memGunzip( $raw_bis );
	my $data = Compress::Zlib::memGunzip( $raw );
	print "[Slackware::Slackget::Network::Backend::Gzip] decoded data are :\n".$data."\n" if($ENV{SG_DAEMON_DEBUG}) ;
	return Slackware::Slackget::Network::Message->new(raw_data => $data);
}

=head2 backend_encode

=cut

sub backend_encode {
	my $self = shift;
	my $message = shift ;
	print "[Slackware::Slackget::Network::Backend::Gzip] call backend_encode($message).\n" if($ENV{SG_DAEMON_DEBUG}) ;
	my $raw = $message->data();
# 	my $Gzip = `gzip -c < $raw`;
	my $Gzip = Compress::Zlib::memGzip( $raw ) ;
	print "[Slackware::Slackget::Network::Backend::Gzip] encoded Gzip:\n$Gzip\n" if($ENV{SG_DAEMON_DEBUG});
	return Slackware::Slackget::Network::Message->new(
		action => $message->action,
		action_id => $message->{action_id},
		raw_data => $Gzip,
	);
}



=head1 AUTHOR

DUPUIS Arnaud, C<< <a.dupuis@infinityperl.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-Slackware-Slackget@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Slackware-Slackget>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Slackware::Slackget


You can also look for information at:

=over 4

=item * Infinity Perl website

L<http://www.infinityperl.org/category/slack-get>

=item * slack-get specific website

L<http://slackget.infinityperl.org>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Slackware-Slackget>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Slackware-Slackget>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Slackware-Slackget>

=item * Search CPAN

L<http://search.cpan.org/dist/Slackware-Slackget>

=back

=head1 ACKNOWLEDGEMENTS

Thanks to Bertrand Dupuis (yes my brother) for his contribution to the documentation.

=head1 SEE ALSO

L<Slackware::Slackget::Network::Message>, L<Slackware::Slackget::Status>, L<Slackware::Slackget::Network::Connection>

=head1 COPYRIGHT & LICENSE

Copyright 2005 DUPUIS Arnaud, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Slackware::Slackget::Network::Backend::Gzip