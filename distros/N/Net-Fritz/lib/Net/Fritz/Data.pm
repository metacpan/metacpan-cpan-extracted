use strict;
use warnings;
# Copyright (C) 2015  Christian Garbs <mitch@cgarbs.de>
# Licensed under GNU GPL v2 or later.

package Net::Fritz::Data;
# ABSTRACT: wraps various response data
$Net::Fritz::Data::VERSION = 'v0.0.7';

use Scalar::Util qw(blessed);

use Moo;

with 'Net::Fritz::IsNoError';


has data => ( is => 'ro' );


# prepend 'data => ' when called without hash
# (when called with uneven list)
sub BUILDARGS {
    my ( $class, @args ) = @_;
    
    unshift @args, "data" if @args % 2 == 1;
    
    return { @args };
};


sub get {
    my $self = shift;

    return $self->data;
}


sub dump {
    my $self = shift;

    my $indent = shift;
    $indent = '' unless defined $indent;

    my $text = "${indent}" . blessed( $self ) . ":\n";
    $text .= "${indent}----data----\n";
    $text .= $self->data . "\n";
    $text .= "------------\n";

    return $text;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Fritz::Data - wraps various response data

=head1 VERSION

version v0.0.7

=head1 SYNOPSIS

    my $fritz    = Net::Fritz::Box->new();
    my $device   = $fritz->discover();
    my $service  = $device->find_service('DeviceInfo:1');
    my $response = $service->call('GetSecurityPort');

    # $response is Net::Fritz::Data
    printf "SSL communication port is %d\n",
           $response->data->{NewSecurityPort};


    my $service_list = $device->find_service_names('DeviceInfo:1');

    # service_list is Net::Fritz::Data
    printf "%d services found\n",
           scalar @{$service_list->data};

=head1 DESCRIPTION

This class wraps the return data from a L<Net::Fritz::Service> call.
This is only done for consistent error checks: L<Net::Fritz::Data>
does the role L<Net::Fritz::IsNoError>, so it is possible to check for
errors during the service call with C<$response-E<gt>error> and
C<$response-E<gt>errorcheck> (see L<Net::Fritz::Error> for details).

Apart from that the response data from the service call is passed
through unaltered, so you have to know with which data type the
services answers.

This wrapper class is also used in some other methods that return
things that need to be error-checkable, like
L<Net::Fritz::Device/find_service_names>.

=head1 ATTRIBUTES (read-only)

=head2 data

Returns the response data of the service call.  For lists and hashes,
this will be a reference.

=head2 error

See L<Net::Fritz::IsNoError/error>.

=head1 METHODS

=head2 new

Creates a new L<Net::Fritz::Data> object.  You propably don't have to
call this method, it's mostly used internally.  Expects parameters in
C<key =E<gt> value> form with the following keys:

=over

=item I<data>

set the data to hold

=back

With only one parameter (in fact: any odd value of parameters), the
first parameter is automatically mapped to I<data>.

=for Pod::Coverage BUILDARGS

=head2 get

Kind of an alias for C<$response->data>: Returns the L<data|/data>
attribute.

=head2 dump(I<indent>)

Returns some preformatted multiline information about the object.
Useful for debugging purposes, printing or logging.  The optional
parameter I<indent> is used for indentation of the output by
prepending it to every line.

=head2 errorcheck

See L<Net::Fritz::IsNoError/errorcheck>.

=head1 SEE ALSO

See L<Net::Fritz> for general information about this package,
especially L<Net::Fritz/INTERFACE> for links to the other classes.

=head1 AUTHOR

Christian Garbs <mitch@cgarbs.de>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 Christian Garbs

This program is free software: you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation, either version 2 of the License, or (at your option)
any later version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along
with this program. If not, see <http://www.gnu.org/licenses/>.

=cut
