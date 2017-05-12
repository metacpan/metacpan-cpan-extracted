package Net::Simplify::Tax;

=head1 NAME

Net::Simplify::Tax - A Simplify Commerce Tax object

=head1 SYNOPSIS

  use Net::Simplify;


  $Net::Simplify::public_key = 'YOUR PUBLIC KEY';
  $Net::Simplify::private_key = 'YOUR PRIVATE KEY';

  # Create a new Tax.
  my $tax = Net::Simplify::Tax->create{ {...});

  # Retrieve a Tax given its ID.
  my $tax = Net::Simplify::Tax->find('a7e41');

  # Delete
  my $tax = Net::Simplify::Tax->find('a7e41');
  $tax->delete();

  # Retrieve a list of objects
  my $taxs = Net::Simplify::Tax->list({max => 10});
  foreach my $v ($taxs->list) {
      # ...
  }

=head1 DESCRIPTION

=head2 METHODS

=head3 create(%params, $auth)

Creates a C<Net::Simplify::Tax> object.  The parameters are:

=over 4

=item C<%params>

Hash map containing initial values for the object.  Valid keys are:

=over 4

=item label

The label of the tax object. [max length: 255] (B<required>) 

=item rate

The tax rate.  Decimal value up three decimal places.  e.g 12.501. [max length: 6] (B<required>) 


=back

=item C<$auth>

Authentication object for accessing the API.  If no value is passed the global keys
C<$Net::Simplify::public_key> and C<$Net::Simplify::private_key> are used.

=back




=head3 delete()

Deletes the C<Net::Simplify::Tax> object.  Authentication is done using the same credentials used when the AccessToken was created.



=head3 list(%criteria, $auth)

Retrieve a list of C<Net::Simplify::Tax> objects.  The parameters are:

=over 4

=item C<%criteria>

Hash map representing the criteria to limit the results of the list operation.  Valid keys are:

=over 4

=item C<filter>

Filters to apply to the list.



=item C<max>

Allows up to a max of 50 list items to return. [min value: 0, max value: 50, default: 20]



=item C<offset>

Used in paging of the list.  This is the start offset of the page. [min value: 0, default: 0]



=item C<sorting>

Allows for ascending or descending sorting of the list.
The value maps properties to the sort direction (either C<asc> for ascending or C<desc> for descending).  Sortable properties are:

=over 4

=item C<id>

=item C<label>


=back




=back

=back



=head3 find($id, $auth)

Retrieve a C<Net::Simplify::Tax> object from the API.  Parameters are:

=over 4

=item C<$id>

Identifier of the object to retrieve.

=item C<$auth>

Authentication object for accessing the API.  If no value is passed the global keys
C<$Net::Simplify::public_key> and C<$Net::Simplify::private_key> are used.

=back





=head1 SEE ALSO

L<Net::Simplify>,
L<Net::Simplify::Domain>,
L<Net::Simplify::DomainList>,
L<Net::Simplify::Authentication>,
L<Net::Simplify::ApiException>,
L<http://www.simplify.com>

=head1 VERSION

1.5.0

=head1 LICENSE

Copyright (c) 2013 - 2016 MasterCard International Incorporated
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are 
permitted provided that the following conditions are met:

Redistributions of source code must retain the above copyright notice, this list of 
conditions and the following disclaimer.
Redistributions in binary form must reproduce the above copyright notice, this list of 
conditions and the following disclaimer in the documentation and/or other materials 
provided with the distribution.
Neither the name of the MasterCard International Incorporated nor the names of its 
contributors may be used to endorse or promote products derived from this software 
without specific prior written permission.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY 
EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES 
OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT 
SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, 
INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; 
OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER 
IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING 
IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF 
SUCH DAMAGE.

=head1 SEE ALSO

=cut

use 5.006;
use strict;
use warnings FATAL => 'all';

use Net::Simplify::Domain;
use Net::Simplify::DomainList;

our @ISA = qw(Net::Simplify::Domain);

sub create {

    my ($class, $params, $auth) = @_;
    
    $auth = Net::Simplify::SimplifyApi->get_authentication($auth);
    my $result = Net::Simplify::SimplifyApi->send_api_request("tax", 'create', $params, $auth);

    $class->SUPER::new($result, $auth);
}

sub delete {

    my ($self) = @_;

    my $auth = Net::Simplify::SimplifyApi->get_authentication($self->{_authentication});

    my $id = $self->{id};
    $self->merge(Net::Simplify::SimplifyApi->send_api_request("tax", 'delete', {id => $id}, $auth));
}

sub list {
    my ($class, $criteria, $auth) = @_;
   
    $auth = Net::Simplify::SimplifyApi->get_authentication($auth);
    my $result = Net::Simplify::SimplifyApi->send_api_request("tax", 'list', $criteria, $auth);

    Net::Simplify::DomainList->new($result, $class, $auth);
}

sub find {
    my ($class, $id, $auth) = @_;

    $auth = Net::Simplify::SimplifyApi->get_authentication($auth);
    my $result = Net::Simplify::SimplifyApi->send_api_request("tax", 'find', { id => $id }, $auth);

    $class->SUPER::new($result, $auth);
}


1;
