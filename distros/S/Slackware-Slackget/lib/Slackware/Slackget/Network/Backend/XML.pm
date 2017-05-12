package Slackware::Slackget::Network::Backend::XML;

use warnings;
use strict;
require Slackware::Slackget::Network::Message ;
require XML::Simple;
require Data::Dumper;

=head1 NAME

Slackware::Slackget::Network::Backend::XML - XML backend for slack-get network protocol

=head1 VERSION

Version 0.9.0

=cut

our $VERSION = '0.9.0';

=head1 SYNOPSIS

This module implements the XML backend for slack-get (sg_daemon, slack-get and more generally all Perl written parts of the slack-get project).

You should not use this module directly but you should read this documentation ;-)

This backend is a low-level one, it means that it needs access to the data structure of the Slackware::Slackget::Network::Message object it will encode (or decode but it's less critical in the decoding process). A bad idea is to encode the message with another backend which make the data structure unreadable by this one, before calling this XML backend (the Base64 backend for example)...

You should *always* remember this fact in your development. If backend_encode() cannot access to the data structure you can expect some funny behaviors...

=cut

sub new
{
	my ($class,%args) = @_ ;
	my $self = {%args};
	bless($self,$class);
	return $self;
}

=head1 DEBUG

This module is affected by the envirronement variable SG_DAEMON_DEBUG. If it's set to a true value, it will output some debug messages.

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
	my $xml_msg = shift;
	print "[Slackware::Slackget::Network::Backend::XML] call backend_decode($xml_msg).\n" if($ENV{SG_DAEMON_DEBUG}) ;
	print "[Slackware::Slackget::Network::Backend::XML] for message $xml_msg, data are :\n".$xml_msg->data."\n" if($ENV{SG_DAEMON_DEBUG}) ;
	my $data = XML::Simple::XMLin( $xml_msg->data, ForceArray => ['li'], ForceContent => 1 );
	delete($data->{version});
	return Slackware::Slackget::Network::Message->new(
		action => $data->{Enveloppe}->{Action}->{content},
		action_id => $data->{Enveloppe}->{Action}->{id},
		raw_data => $data
	);
}

=head2 backend_encode

=cut

sub backend_encode {
	my $self = shift;
	my $message = shift ;
	print "[Slackware::Slackget::Network::Backend::XML] call backend_encode($message).\n" if($ENV{SG_DAEMON_DEBUG}) ;
	sub _data_to_string {
		my $ref = shift;
		my $str = '';
		foreach my $k ( keys(%{$ref}) ){
			my $end_tag=1;
			if(ref($ref->{$k})){
				if( ref($ref->{$k}) eq 'ARRAY' ){
					$end_tag=0;
					foreach my $ai (@{$ref->{$k}}){
						if(ref($ai) eq ''){
							$str .= "<$k>$ai</$k>\n";
						}else{
							$str .= "<$k>"._data_to_string($ai)."</$k>";
						}
					}
				}
				elsif(defined($ref->{$k}->{'content'})){
					$str .= "<$k ";
					foreach my $sk ( keys(%{$ref->{$k}}) ){
						next if($sk eq 'content');
						$str .= "$sk=\"$ref->{$k}->{$sk}\" ";
					}
					$str .= ">$ref->{$k}->{'content'}";
				}else{
					$str .= "<$k>\n";
					$str .= _data_to_string($ref->{$k});
				}
			}
			$str .= "</$k>\n" if($end_tag);
		}
		return $str;
	}
	
	my $xml = "<?xml version=\"1.0\" ?>\n<SlackGetProtocol version=\"".Slackware::Slackget::Network::SLACK_GET_PROTOCOL_VERSION."\">\n";
	$xml .= _data_to_string($message->data());
	$xml .= "</SlackGetProtocol>\n";
	print "[Slackware::Slackget::Network::Backend::XML] encoded XML:\n$xml\n" if($ENV{SG_DAEMON_DEBUG});
	return Slackware::Slackget::Network::Message->new(
		action => $message->data()->{Enveloppe}->{Action}->{content},
		action_id => $message->data()->{Enveloppe}->{Action}->{id},
		raw_data => $xml,
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

1; # End of Slackware::Slackget::Network::Backend::XML