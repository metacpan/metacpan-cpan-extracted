package SMS::Send::AT::SmsAt;

use warnings;
use strict;
use Carp;
use LWP::UserAgent;
use XML::XPath;
use XML::Writer;
use SMS::Send::Driver;

use version; our $VERSION = qv('0.0.5');

use base 'SMS::Send::Driver';

sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;
    my $self = { @_ };

    $self->{"_$_"} or croak "no $_ specified" for qw(login password);

    return bless $self, $class;
}

sub send_sms {
    my $self = shift;
    my %params = @_;

    croak 'no recipient specified' unless $params{to};
    $params{to} =~ s/\A\+//;
    $params{to} =~ s/\A0/43/; # Austria as default country

    my $text = unpack 'H*', $params{text} or croak 'no message specified';

    my $ua = LWP::UserAgent->new();
    my $message;
    my $writer = XML::Writer->new(OUTPUT => \$message, DATA_MODE => 1, DATA_INDENT => 4);

    $writer->xmlDecl();
    $writer->startTag('Request');
        $writer->dataElement('AccountLogin', $self->{_login}, Type => 'email');
        $writer->dataElement('AccountPass', $self->{_password});

        $writer->startTag('Message', Type => 'MTSMS');
            $writer->startTag('Recipients');
                $writer->dataElement('Recipient', $params{to}, Type => 'International');
            $writer->endTag('Recipients');

            $writer->dataElement('Text', $text, AutoSegment => 'simple');
        $writer->endTag('Message');
    $writer->endTag('Request');
    $writer->end();

    my $response = $ua->post('http://gateway.sms.at/xml_interface/', 'Content-type' => 'text/xml', Content => $message);
    if ($response->is_success) {
#        warn $response->content;  # or whatever
        my $xp = XML::XPath->new(xml => $response->content);
        my $code = $xp->getNodeText('/Response/Code');
        # stringify the XML::XPath::Literal object we just got for comparison
        return 1 if "$code" == 2000 or "$code" == 2001; # success
        warn $code . ': ' . $xp->getNodeText('/Response/CodeDescription');
        return 0;
    }
    else {
        Carp::croak($response->status_line);
    }

    return 1;
}


1; # Magic true value required at end of module
__END__

=head1 NAME

SMS::Send::AT::SmsAt - driver for sending SMS through gateway.sms.at


=head1 VERSION

This document describes SMS::Send::AT::SmsAt version 0.0.1


=head1 SYNOPSIS

    use SMS::Send::AT::SmsAt;

    my $sender = SMS::Send->new('AT::SmsAt',
    	_login    => 'XXXXX',
	_password => 'YYYYY',
    );

    my $sent = $sender->send_sms(
    	text => "Test message\n",
	to   => '+43 699 999 999',
    );

    if ($sent) {
	print "successfull\n";
    } else {
	print "sending failed\n";
    }

=for author to fill in:
    Brief code example(s) here showing commonest usage(s).
    This section will be as far as many users bother reading
    so make it as educational and exeplary as possible.
  
  
=head1 DESCRIPTION

L<SMS::Send::AT::SmsAt> is a L<SMS::Send> driver for the Austrian
company sms.at's service at L<http://gateway.sms.at>

This is a commercial payed-for service.

=head1 INTERFACE 

B<See and use the API of SMS::Send>

=head2 new

The new constructor takes two parameters, which should be passed through from the SMS::Send constructor.

The params are driver-specific for now, until SMS::Send adds a standard set of params for specifying the login and password.

_login
The _login param should be your login name you registered with gateway.sms.at.

_password
The _password param should be your gateway.sms.at password.

=head2 send_sms

    # Send a message to a particular address
    my $result = $sender->send_sms(
        text => 'This is a test message',
        to   => '+61 4 1234 5678',
    );

The C<send_sms> method sends a standard text SMS message to a destination.

=head1 DIAGNOSTICS

=for author to fill in:
    List every single error and warning message that the module can
    generate (even the ones that will "never happen"), with a full
    explanation of each problem, one or more likely causes, and any
    suggested remedies.

=over

=item C<< Error message here, perhaps with %s placeholders >>

[Description of error here]

=item C<< Another error message here >>

[Description of error here]

[Et cetera, et cetera]

=back


=head1 CONFIGURATION AND ENVIRONMENT

SMS::Send::AT::SmsAt requires no configuration files or environment variables.


=head1 DEPENDENCIES

SMS::Send 0.04 from CPAN


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-sms-send-at-smsat@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Stefan Seifert  C<< <stefan.seifert@atikon.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Stefan Seifert C<< <stefan.seifert@atikon.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
