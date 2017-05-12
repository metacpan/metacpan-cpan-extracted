package SMS::OVH;

use 5.006;
use strict;
use warnings;

use OvhApi;
use Moose;
use namespace::autoclean;

has [qw( app_key app_secret cons_key serviceName sender )] => (
    isa      => 'Str',
    is       => 'ro',
    required => 1
);

has 'receivers' => (
    is       => 'rw',
    isa      => 'ArrayRef',
    required => 1,
    lazy     => 1,
    default  => sub { [] }
);

has 'message' => (
    isa      => 'Str',
    is       => 'rw',
    required => 1,
    lazy     => 1,
    default  => ''
);

has '_api' => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $api  = OvhApi->new(
            type              => OvhApi::OVH_API_EU,
            applicationKey    => $self->app_key,
            applicationSecret => $self->app_secret,
            consumerKey       => $self->cons_key
        );
        return $api;
    }
);

=head1 NAME

SMS::OVH - Send SMS using OVH API (https://api.ovh.com/)

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

This is just a little module that use OvhApi.pm to send SMS using the french provider API.
You'll need the OvhApi.pm module provided by OVH at:

https://eu.api.ovh.com/wrappers/OvhApi-perl-1.1.zip

OvhApi is not a CPAN modeula (yet), so you'll need to have it installed before install this module.

This module also depends on Moose (https://metacpan.org/pod/Moose)

    use SMS::OVH;

    my $sms = SMS::OVH->new(
        app_key => 'your-key',
        app_secret => 'your-secret',
        cons_key => 'your-cons-key',
        serviceName => 'a-service-name',
        sender => 'a-sender-name',
        receivers => ['+33123123123'],
        message => 'This is a test text message.'
    );

    $sms->send();

=head1 METHODS

=head2 send

This is the only method. It just tries to complete the API request.
It takes no arguments, just uses the parameters set when the instance is created.

=cut

sub send {
    my $self = shift;
    my $url  = "/sms/" . $self->serviceName . "/jobs";
    my %body = (
        message      => $self->message,
        sender       => $self->sender,
        noStopClause => 'true',
        receivers    => $self->receivers
    );
    return $self->_api->rawCall(
        path   => $url,
        method => 'post',
        body   => \%body
    );
}

=head1 AUTHOR

Paco Esteban, C<< <paco at onna.be> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-sms-ovh at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SMS-OVH>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SMS::OVH


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SMS-OVH>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SMS-OVH>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SMS-OVH>

=item * Search CPAN

L<http://search.cpan.org/dist/SMS-OVH/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Paco Esteban.
                  and
               Powerspace Advertising SL <http://powerspace.com/>

This program is distributed under the (Revised) BSD License:
L<http://www.opensource.org/licenses/BSD-3-Clause>

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

* Redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.

* Neither the name of Paco Esteban's Organization
nor the names of its contributors may be used to endorse or promote
products derived from this software without specific prior written
permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1;    # End of SMS::OVH
