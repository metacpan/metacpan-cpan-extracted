package Net::Saasu;

use 5.010;
use Any::Moose;
use LWP::UserAgent;
use XML::TreePP;

=head1 NAME

Net::Saasu - Interface to the Saasu online accounting platform!

=head1 VERSION

Version 0.2.2.2.2.2.1

=cut

our $VERSION = '0.2';

has 'api_url' => (
    is      => 'rw',
    isa     => 'Str',
    default => 'https://secure.saasu.com/webservices/rest/r1/',
);
has 'xml' => (
    is      => 'rw',
    isa     => 'XML::TreePP',
    default => sub { new XML::TreePP },
);
has 'ua' => (
    is      => 'rw',
    isa     => 'LWP::UserAgent',
    default => sub { new LWP::UserAgent },
);
has 'debug' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);
has 'error' => (
    is        => 'rw',
    isa       => 'HashRef',
    predicate => 'has_error',
    clearer   => 'clear_error',
);
has 'key'     => (is => 'rw', isa => 'Str');
has 'file_id' => (is => 'rw', isa => 'Str');

=head1 SYNOPSIS

A very basic interface to saasu, an online accounting system
(L<http://saasu.com>). This may morph into a more complete interface
over time but for the moment this basic implementation abstracts
everything we need. Detaild API documentation can be found on the saasu
page (L<http://help.saasu.com/api/>).
    
    my $saasu = Net::Saasu->new(
        key     => 'API KEY',
        file_id => 12345,
        debug   => 1
    );

Example from the saasu docs for a POST request:

    my $hash = {
        tasks => {
            insertTransactionCategory => {
                transactionCategory => {
                    -uid     => 0,
                    type           => 'Income',
                    name           => 'Consulting Fees',
                    isActive       => 'true',
                    ledgerCode     => 'IT001',
                    defaultTaxCode => 'G1',
                }
            } 
        } 
    };

    $saasu->post($hash);
    if ( my $list = $saasu->post( $hash )){
        print Dumper($list);
    }
    else {
        print Dumper($saasu->error);
        $saasu->clear_error;
    }

=head1 SUBROUTINES/METHODS


=head2 get

Call saasu in get mode and pull data. Decodes the data and returns a
nice perl hash. In case of an error the error response is set in
$self->error and we return nothing.
    
    my $params = { IsActive => 1 };
    if(my $result = $saasu->get(Command, $params)){
        # do something with $result
    } else {
        # you got an error in $saasu->error
        # clean it up with 
        $saasu->clear_error;
    }

=cut

sub get {
    my ($self, $command, $payload) = @_;

    my $url =
          $self->api_url
        . $command
        . '?WSAccessKey='
        . $self->key
        . '&FileUid='
        . $self->file_id;

    my @args;
    foreach my $key (keys %{$payload}) {
        given ($payload->{$key}) {
            when ([qw(1 true)])  { push(@args, join('=', $key, 'true')); }
            when ([qw(0 false)]) { push(@args, join('=', $key, 'false')); }
            default { push(@args, join('=', $key, $payload->{$key})); }
        }
    }
    $url .= '&' . join('&', @args);
    return $self->_talk($url, 'GET');
}

=head2 post

Push some data to saasu.

=cut

sub post {
    my ($self, $payload) = @_;

    my $url =
          $self->api_url
        . 'tasks?WSAccessKey='
        . $self->key
        . '&FileUid='
        . $self->file_id;

    return $self->_talk($url, 'POST', $payload);
}

=head2 delete

Delete an object in saasu

=cut

sub delete {
    my ($self, $command, $id) = @_;

    my $url =
          $self->api_url
        . $command
        . '?WSAccessKey='
        . $self->key
        . '&FileUid='
        . $self->file_id . '&uid='
        . $id;

    return $self->_talk($url, 'DELETE');

}

=head2 _talk

INTERNAL: Talk to the web service

=cut

sub _talk {
    my ($self, $url, $mode, $payload) = @_;

    my $req = HTTP::Request->new($mode, $url);
    if ($mode eq 'POST') {
        $payload = { tasks => $payload }
            unless exists $payload->{tasks};
        $self->xml->set( first_out => [ 'layout', 'status' ] );
        $req->content($self->xml->write($payload));
        $req->header('Content-Type' =>
                'application/x-www-form-urlencoded; charset=utf-8');
    }
    print STDERR $req->as_string if $self->debug;

    my $res = $self->ua->request($req);

    if ($res->is_success) {
        my $hash = $self->xml->parse($res->decoded_content);
        if (exists $hash->{errors}) {
            $self->error($hash->{errors});
            return;
        }
        else {
            return $hash;
        }
    }
    $self->error({ http_error => $res->status_line, code => $res->code });
    return;
}

=head1 AUTHOR

Lenz Gschwendtner, C<< <norbu09 at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-saasu at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Saasu>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Saasu


You can also look for information at:

=over 4

=item * Github Issues: (report bugs here)

L<https://github.com/norbu09/Net-Saasu/issues>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-Saasu>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-Saasu>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-Saasu/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Lenz Gschwendtner.

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

1;    # End of Net::Saasu
