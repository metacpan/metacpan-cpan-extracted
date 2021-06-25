package Net::Payment::CCAvenue::NonSeamless::Response;

use Moose;
extends 'Net::Payment::CCAvenue';


=head1 NAME

Net::Payment::CCAvenue::NonSeamless::Response - Reads the returned encoded response!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

    CCAvenue billing page (Non-Seamless) - On receiving the authorization status from the bank, CCAvenue sends the response back to your website with the transaction status.

    Query parameters are <orderNo> and <encResp>

    use Net::Payment::CCAvenue::NonSeamless::Response;

    my $foo = Net::Payment::CCAvenue::NonSeamless::Response->new(
        encryption_key => 'xxxx',
        access_code => 'xxxx',
        merchant_id => 'xxxxx',
        order_no => 'Returned orderNo query param value',
        enc_response => 'Returned encResp query param value',
    );

    # Returns true if payment was success
    $foo->is_success();

=cut

=head1 See More

=over 2

=item L<Net::Payment::CCAvenue>
=item L<Net::Payment::CCAvenue::NonSeamless>

=head1 Attributes

=head2 order_no

Order number (C<orderNo>) as query parameter returned from CCAvenue sends to callback url.

=head2 enc_response

Encrypted response (C<encResp>) as query parameter returned from CCAvenue sends to callback url.

=cut

has [qw(order_no enc_response)] => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

=head2 decoded_response

Decoded response from CCAvenue.

=cut

has decoded_response => (
    is         => 'ro',
    isa        => 'Maybe[HashRef]',
    lazy_build => 1
);

sub _build_decoded_response {
    my ($self) = @_;
    return $self->decrypt_data($self->enc_response);
}

=head2 is_valid_request

Returns C<true> if callback url get the encoded response.

=head2 is_success

Returns C<true> if payment has been processed successfully and it has bank reciept number.

=cut

has [ qw(is_valid_request is_success)] => (
    is => 'ro',
    isa => 'Bool',
    lazy_build => 1,
);

sub _build_is_valid_request {
    return 0 unless $self->decoded_response;
    return 1;
}

sub _build_is_success {
    return 0 unless $self->bank_receipt_no;
    return 1;
}

=head2 response_message

Returns response message, could be error message or any other message

=head2 bank_receipt_no

Returns bank reciept number

=head2 tracking_id

Returns bank tracking identifier

=cut

has [ qw(response_message bank_receipt_no tracking_id) ] => (
    is => 'ro',
    isa => 'Maybe[Str]',
    lazy_build => 1,
);

sub _build_response_message {
    return $self->decoded_response->{'status_message'};
}

sub _build_bank_receipt_no {
    return $self->decoded_response->{'bank_receipt_no'};
}

sub _build_tracking_id {
    return $self->decoded_response->{'tracking_id'};
}

=head1 AUTHOR

Rakesh Kumar Shardiwal, C<< <rakesh.shardiwal at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-payment-ccavenue-nonseamless at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Payment-CCAvenue-NonSeamless>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Payment::CCAvenue::NonSeamless


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-Payment-CCAvenue-NonSeamless>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-Payment-CCAvenue-NonSeamless>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-Payment-CCAvenue-NonSeamless>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-Payment-CCAvenue-NonSeamless/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2021 Rakesh Kumar Shardiwal.

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

1;    # End of Net::Payment::CCAvenue::NonSeamless
