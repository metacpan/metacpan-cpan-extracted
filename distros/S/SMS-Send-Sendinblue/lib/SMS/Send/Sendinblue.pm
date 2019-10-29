package SMS::Send::Sendinblue;

use 5.006;
use strict;
use warnings;

use parent 'SMS::Send::Driver';

use Carp;
use LWP::UserAgent;
use HTTP::Headers;
use JSON;

=head1 NAME

SMS::Send::Sendinblue - SMS::Send driver for Sendinblue

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

    my $sender = SMS::Send->new('Sendinblue',
        _apikey => 'apikey',
        _sender => 'Sender',
    );

    my $sent = $sender->send_sms(
        text => 'Text message',
        to => '+61 (4) 1234 5678',
    );

=cut

=head1 METHODS

=head2 new

    my $sender = SMS::Send->new('Sendinblue',
        _apikey => 'apikey',
        _sender => 'Sender',
    );

=head3 Parameters

=over

=item * C<_apikey> The API key can be retrieved from the Sendinblue account settings

=item * C<_sender> Name of the sender. Only alphanumeric characters. No more than 11 characters

=back

=cut

sub new {
    my ($class, %params) = @_;

    foreach my $param (qw(_apikey _sender)) {
        unless (exists $params{$param}) {
            croak $class . "->new requires $param parameter";
        }
    }

    my $self = \%params;
    bless $self, $class;


    return $self;
}

sub send_sms {
    my ($self, %params) = @_;

    my $request = HTTP::Request->new(POST => 'https://api.sendinblue.com/v3/transactionalSMS/sms');
    $request->content_type('application/json');
    $request->header(api_key => $self->{_apikey});

    my $body = {
        sender => $self->{_sender},
        recipient => $params{to},
        content => $params{text},
        type => 'transactional',
    };
    $request->content(encode_json($body));

    my $ua = LWP::UserAgent->new();
    my $response = $ua->request($request);

    if ($response->is_error) {
        warn "Failed to send SMS: " . $response->status_line;
        return 0;
    }

    return 1;
}

=head1 AUTHOR

Julian Maurice, C<< <julian.maurice at biblibre.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-sms-send-sendinblue at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=SMS-Send-Sendinblue>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SMS::Send::Sendinblue


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=SMS-Send-Sendinblue>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SMS-Send-Sendinblue>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/SMS-Send-Sendinblue>

=item * Search CPAN

L<https://metacpan.org/release/SMS-Send-Sendinblue>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2019 Julian Maurice.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of SMS::Send::Sendinblue
