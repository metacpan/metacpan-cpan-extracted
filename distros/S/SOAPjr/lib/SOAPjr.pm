package SOAPjr;

use strict;
use warnings;
use base qw(SOAPjr::base);

use SOAPjr::request;
use SOAPjr::response;

=head1 NAME

SOAPjr - SOAP without the bloat and JR (JSON-RPC) with proper error handling and file uploads

=head1 VERSION

Version 1.1.4

=cut

our $VERSION = "1.1.4";

=head1 SYNOPSIS

    Overview
    --------
    1. Receive request message
    2. Validate request message
    3. Process request message
    4. Create response message
    5. Configure response message
    6. Send response message 

    # The assumption is that this module will be used from within a perl script (or an apache request handler)
    # - use in the module
    use SOAPjr;

    # - create the SOAPjr server object
    # NOTE: This is the equivalent of jquery on the client side and may be created in the apache perl_startup.pl script so it's persistent
    my $server = SOAPjr->new($options);
    
    # 1. Receive request message
    # - your perl script is called either directly or as a handler
    # e.g. /SOAPjr.pl

    # 2. Validate request message
    # - create the inbound request object for this request
    my $request = $server->create_request($query_params_hashref, \%ENV);
    
    # - set any settings for this inbound request object
    $request->set({ OPTIONS => { "..." => "..." } });
    
    # 3. Process request message
    # This is where your development implementation happens
    # - process the request however you need to
    # ...
    
    # 4. Create response message
    # - then when you're ready you create a response object
    my $response = $self->create_response({ ENVELOPE => { "option1" => "XXX" } });
    
    # 5. Configure response message
    # - then set any of the response values
    $response->set({ HEAD => { "option1" => "DDD" }, BODY => { "option1" => "LLL" } });

    # 6. Add any errors you need to
    # - if your processing of $request creates any errors then just add them with $response->add_error()
    # e.g. 
    # $s = $r->add_error({
    #     context => "HEAD",
    #     property => "sid",
    #         error => {
    #         code => 401,
    #         message => "Invalid session ID"
    #     }
    # });
    # NOTE: $s (e.g. the return of add_error()) is a serialised_string of the current object after the error is added
    
    # 7. Send response message 
    # - then when you're done you send back your response
    my $send_result = $response->send({ HEAD => { "option1" => "DDD" }, BODY => { "option1" => "LLL" } });
    # or you can just get a serialised string of the object at any time using $response->output();

=head1 FUNCTIONS

=head2 _init

Private method to enable inheritance via SOAPjr::base.

=cut

sub _init {
    my $self  = shift;
    my $input = shift;
    $self->set($input);
    return $self->SUPER::_init($input);
}

=head2 create_request 

Public method to enable the creation of a SOAPjr request object.

=cut

sub create_request {
    my $self           = shift;
    my $query          = shift;
    my $SOAPjr_request = SOAPjr::request->new($self, $query, @_);
    return $SOAPjr_request;
}

=head2 create_response

Public method to enable the creation of a SOAPjr response object.

=cut

sub create_response {
    my $self            = shift;
    my $SOAPjr_response = SOAPjr::response->new(@_);
    return $SOAPjr_response;
}

=head1 AUTHOR

Rob Manson, <robman[at]cpan.org>

=head1 BUGS

Please report any bugs or feature requests to C<bug-soapjr at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SOAPjr>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SOAPjr


You can also look for information at:

=over 4

=item * SOAPjr.org 

L<http://SOAPjr.org>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SOAPjr>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SOAPjr>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SOAPjr>

=item * Search CPAN

L<http://search.cpan.org/dist/SOAPjr/>

=back

=head1 TODO

Need to write t/ tests and add detailed documentation then replace t/pod-coverage.t.

Also need to create Server and Client modules ala JSON::RPC and more detailed example scripts.

=head1 ACKNOWLEDGEMENTS

See L<http://SOAPjr.org/specs.html> for further information on related RFC's and specifications.

=head1 COPYRIGHT & LICENSE

    Copyright 2008 Rob Manson, Sean McCarthy and http://SOAPjr.org, some rights reserved.

    This file is part of SOAPjr.

    SOAPjr is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    SOAPjr is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with SOAPjr.  If not, see <http://www.gnu.org/licenses/>.

=cut

1;    # End of SOAPjr
