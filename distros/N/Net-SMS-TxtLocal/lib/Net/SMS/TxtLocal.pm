package Net::SMS::TxtLocal;

use Carp;
use LWP::UserAgent;
use Moose;
use namespace::autoclean;
use JSON;

use 5.006;

our $VERSION = '0.03';

=head1 NAME

Net::SMS::TxtLocal - Send SMS messages using txtlocal.co.uk

=head1 SYNOPSIS

    my $txtlocal = Net::SMS::TxtLocal->new(
        uname => 'you@domain.com',
        pword => 'secret',
        from  => 'Your Name',        # optional
    );
    
    # get the current balance
    my $balance = $txtlocal->get_credit_balance();
    
    # send a message
    $txtlocal->send_message(
        {
            message => "This is a test message from Net::SMS::TxtLocal",
            to      => [ '447890123456' ],
        }
    );

=head1 DESCRIPTION

This module is a super simple interface to the TxtLocal API which lets you send
SMS messages from your code.

=head1 ABOUT TXTLOCAL

TxtLocal is a UK based SMS service which lets you send messages to mobiles
worldwide. Their website is clean, their pricing reasonable and their API pretty
good too.

If you need to create an account and use this link some pennies might flow back
into the author's pockets: L<http://www.txtlocal.co.uk/?tlrx=52009>

If this shameless commercialism offends you use this link instead:
L<http://www.txtlocal.co.uk/>.

=cut

has uname => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has pword => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has from => (
    is  => 'ro',
    isa => 'Str',
);

has host => (
    is      => 'ro',
    isa     => 'Str',
    default => 'http://www.txtlocal.co.uk'
);

has ua => (
    is      => 'ro',
    isa     => 'Object',
    default => sub { LWP::UserAgent->new },
    lazy    => 1,
);

=head1 METHODS

=head2 new

    $txtlocal = Net::SMS::TxtLocal->new(
        uname => 'you@domain.com',
        pword => 'secret',
        from  => 'Your Name',  # optional
    );

Create a sender object. C<uname> and C<pword> are required and should be your
login to the TxtLocal system.

C<from> is optional and is added to any messages sent.

=cut

# no code here - new is provided by Moose

=head2 get_credit_balance

    my $credit_balance = $txtlocal->get_credit_balance();

Get the credit balance for this account from TxtLocal. This will try to connect
to their servers and is a good way to test that the connection is available.

=cut

sub get_credit_balance {
    my $self = shift;

    my $response = $self->_make_request(
        {
            path  => '/getcredits.php',
            query => {},
        }
    );

    my $credits = $response->{Credits} || 0;

    # clean up the repsonse and check it makes sense
    $credits =~ s{ \s* (\d+) \s* }{$1}x;
    croak "Bad credit value: '$credits' " if $credits =~ m{\D};

    return $credits + 0;
}

=head2 send_message

    $bool = $txtlocal->send_message(
        {
            message => 'the text of the message',
            to      => ['447890123456'],
        }
    );

Send a message to the numbers given in the array.

=cut

sub send_message {
    my $self = shift;
    my $args = shift;

    my $message = $args->{message}
      || croak "required parameter 'message' missing";
    my $to = $args->{to} || croak "required parameter 'to' missing";

    my $response = $self->_make_request(
        {
            path  => '/sendsmspost.php',
            query => {
                from         => $self->from,
                message      => $message,
                selectednums => join( ',', @$to ),
            },
        }
    );

    return 1;
}

=head1 PRIVATE METHODS

=head2 _make_request

    my $response = $txtlocal->_make_request(
        {
            path  => '/path/to/page.php',
            query => { foo => 'bar' },
        }
    );

Make a POST request to the TxtLocal servers. The C<uname> and C<pword> will be
added to the request and content returned - either as a string or a
datastructure.

=cut

sub _make_request {
    my $self = shift;
    my $args = shift;

    my $path  = $args->{path}  || croak "required parameter 'path' missing";
    my $query = $args->{query} || croak "required parameter 'query' missing";

    my $url        = $self->host . $path;
    my $post_query = {
        uname => $self->uname,
        pword => $self->pword,
        json  => 1,
        %$query,
    };

    my $response = $self->ua->post( $url, $post_query );
    croak "Error with request" unless $response->is_success;

    my $content = $response->content;

    # check to see if a string error has been returned.
    croak "Invalid request - please check uname and pword"
      if $content =~ m{ \A \s* invalid \s* \z }xi;

    # return the response unless it looks like JSON
    return $content unless $content =~ m{ \A \s* \{ \s* "\w }x;

    # decode the JSON
    my $data = decode_json($content);

    # check for the error key and croak if it is there
    croak "Error with request: '$data->{Error}'" if $data->{Error};

    return $data;
}

=head1 BUGS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-net-sms-txtlocal@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 CONTRIBUTING

The repository for this module is hosted here:
L<http://github.com/evdb/Net-SMS-TxtLocal>

Please feel free to fork, make changes and send me a patch :)

=head1 AUTHOR

Edmund von der Burg  C<< <evdb@cpan.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2010, Edmund von der Burg C<< <evdb@cpan.org> >>. All rights reserved.

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

=cut

1;
