package SMS::Send::Iletimerkezi;

use 5.006;
use strict;
use warnings;
use Carp;
use XML::Writer;
use LWP::UserAgent;
use Digest::SHA qw(hmac_sha256_hex);
use parent qw(SMS::Send::Driver);

our $VERSION = '0.01';
=encoding utf-8


=head1 NAME

SMS::Send::Iletimerkezi - SMS::Send driver for iletimerkezi.com

=head1 VERSION

Version 0.01

=cut



=head1 SYNOPSIS

Quick summary of what the module does.

use SMS::Send;

# create new sender object with iletimerkezi driver

my $sender = SMS::Send->new('Iletimerkezi',
    _api_key     => '<your iletimerkezi.com api key>',
    _api_secret  => '<your iletimerkezi.com api secret>',
    _sender      => 'ILT MRKZ',
    _encoding    => 'utf8',
);
# Send a message to me
my $sent = $sender->send_sms(
    text => 'Hello from Perl',
    to   => '+905321112233',
);
# Success?
if ( $sent ) {
    print "Sent test message\n";
} else {
    print "Failed to send test message\n";
}

=head2 new

The C<new> constructor takes three parameters, which should be passed
through from the L<SMS::Send> constructor.

_api_key and _api_secret can be found in your account / settings / api
_encoding: one of gsm0338|gsm0338-tr|utf8 or can be left blank to use account default
_sender: the alpha-numeric sender name you want to send message with

=cut


sub new {
    my $class  = shift;
    my %params = @_;

    # check required parameters
    for my $param (qw ( _api_key _sender _api_secret _encoding )) {
        exists $params{$param}
          or croak ($class . "->new requires $param parameter");
    }

    my $self = \%params;
    bless $self, $class;

    return $self;
}


sub create_sms_xml {
    my ($api_key, $api_secret, $encoding, $sender, $message, $recipients) = @_;
    my $sec_digest = hmac_sha256_hex($api_key, $api_secret);
    my $output;
    my $writer = new XML::Writer(OUTPUT => \$output, DATA_INDENT => 2);

    $writer->xmlDecl('UTF-8');
    $writer->startTag("request");
    $writer->startTag("authentication");
    $writer->dataElement('key', $api_key);
    $writer->dataElement('hash', $sec_digest);
    $writer->endTag('authentication');

    $writer->startTag("order");
    $writer->dataElement('sender', $sender);

    # configure encoding if given any
    if ($encoding =~ m/^(gsm0338|gsm0338-tr|utf8)$/ig){
        $writer->dataElement('encoding', $encoding);
    }

    $writer->startTag("message");
    $writer->dataElement('text', $message);

    $writer->startTag("receipents");
    $writer->dataElement('number', $recipients);
    $writer->endTag("receipents");

    $writer->endTag('message');
    $writer->endTag('order');

    $writer->endTag("request");
    $writer->end();
    # print $output;
    return $output;
}

sub send_sms {
    my $self   = shift;
    my %params = @_;

    my $message   = delete $params{text};
    my $recipient = delete $params{to};


    my $api = LWP::UserAgent->new(
        ssl_opts => { verify_hostname => 1, },
        agent    => 'Sms-Send-Iletimerkezi/'. $VERSION,
    );

    my $url = 'https://api.iletimerkezi.com/v1/send-sms';

    my $post_xml = create_sms_xml(
        $self->{_api_key},
        $self->{_api_secret},
        $self->{_encoding},
        $self->{_sender},
        $message,
        $recipient
    );

    my $response = $api->post($url,
        Content => $post_xml,
        'Content-type' => 'application/xml',
    );

    if ($response->is_success) {
        return 1;
    } else {
        croak $response->status_line;
    }

    croak("Can't send sms: $response->{code} $response->{message}");
}


=head1 AUTHOR

Engin Dumlu, C<< <engindumlu at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-sms-send-iletimerkezi at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SMS-Send-Iletimerkezi>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SMS::Send::Iletimerkezi


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SMS-Send-Iletimerkezi>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SMS-Send-Iletimerkezi>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SMS-Send-Iletimerkezi>

=item * Search CPAN

L<http://search.cpan.org/dist/SMS-Send-Iletimerkezi/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2018 Engin Dumlu.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see L<http://www.gnu.org/licenses/>.


=cut

1; # End of SMS::Send::Iletimerkezi
