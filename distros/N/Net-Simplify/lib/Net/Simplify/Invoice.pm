package Net::Simplify::Invoice;

=head1 NAME

Net::Simplify::Invoice - A Simplify Commerce Invoice object

=head1 SYNOPSIS

  use Net::Simplify;


  $Net::Simplify::public_key = 'YOUR PUBLIC KEY';
  $Net::Simplify::private_key = 'YOUR PRIVATE KEY';

  # Create a new Invoice.
  my $invoice = Net::Simplify::Invoice->create{ {...});

  # Retrieve a Invoice given its ID.
  my $invoice = Net::Simplify::Invoice->find('a7e41');

  # Update existing Invoice.
  my $invoice = Net::Simplify::Invoice->find('a7e41');
  $invoice->{PROPERTY} = "NEW VALUE";
  $invoice->update();

  # Delete
  my $invoice = Net::Simplify::Invoice->find('a7e41');
  $invoice->delete();

  # Retrieve a list of objects
  my $invoices = Net::Simplify::Invoice->list({max => 10});
  foreach my $v ($invoices->list) {
      # ...
  }

=head1 DESCRIPTION

=head2 METHODS

=head3 create(%params, $auth)

Creates a C<Net::Simplify::Invoice> object.  The parameters are:

=over 4

=item C<%params>

Hash map containing initial values for the object.  Valid keys are:

=over 4



=item billingAddress.city

Billing address city of the location where the goods or services were supplied. [max length: 255, min length: 2] 

=item billingAddress.country

Billing address country of the location where the goods or services were supplied. [max length: 2, min length: 2] 

=item billingAddress.line1

Billing address line 1 of the location where the goods or services were supplied. [max length: 255] 

=item billingAddress.line2

Billing address line 2 of the location where the goods or services were supplied. [max length: 255] 

=item billingAddress.name

Billing address name of the location where the goods or services were supplied. Will use the customer name if not provided. [max length: 255] 

=item billingAddress.state

Billing address state of the location where the goods or services were supplied. [max length: 255] 

=item billingAddress.zip

Billing address zip of the location where the goods or services were supplied. [max length: 32] 



=item businessAddress.city

Address city of the business that is sending the invoice. [max length: 255, min length: 2] 

=item businessAddress.country

Address country of the business that is sending the invoice. [max length: 2, min length: 2] 

=item businessAddress.line1

Address line 1 of the business that is sending the invoice. [max length: 255] 

=item businessAddress.line2

Address line 2 of the business that is sending the invoice. [max length: 255] 

=item businessAddress.name

The name of the business that is sending the invoice. [max length: 255] 

=item businessAddress.state

Address state of the business that is sending the invoice. [max length: 255] 

=item businessAddress.zip

Address zip of the business that is sending the invoice. [max length: 32] 

=item currency

Currency code (ISO-4217). Must match the currency associated with your account. [max length: 3, min length: 3, default: USD] 

=item customer

The customer ID of the customer we are invoicing.  This is optional if invoiceToCopy or a name and email are provided 

=item customerTaxNo

The tax number or VAT id of the person to whom the goods or services were supplied. [max length: 255] 

=item discountRate

The discount percent as a decimal e.g. 12.5.  This is used to calculate the discount amount which is subtracted from the total amount due before any tax is applied. [max length: 6] 

=item dueDate

The date invoice payment is due.  If a late fee is provided this will be added to the invoice total is the due date has past. 

=item email

The email of the customer we are invoicing.  This is optional if customer or invoiceToCopy is provided.  A new customer will be created using the the name and email. 

=item invoiceId

User defined invoice id. If not provided the system will generate a numeric id. [max length: 255] 

=item invoiceToCopy

The id of an existing invoice to be copied.  This is optional if customer or a name and email are provided 



=item items.amount

Amount of the invoice item (the smallest unit of your currency). Example: 100 = $1.00USD (B<required>) 

=item items.description

The description of the invoice item. [max length: 1024] 

=item items.invoice

The ID of the invoice this item belongs to. 

=item items.product

The product this invoice item refers to. 

=item items.quantity

Quantity of the item.  This total amount of the invoice item is the amount * quantity. [min value: 1, max value: 999999, default: 1] 

=item items.reference

User defined reference field. [max length: 255] 

=item items.tax

The tax ID of the tax charge in the invoice item. 

=item lateFee

The late fee amount that will be added to the invoice total is the due date is past due.  Value provided must be in the smallest unit of your currency. Example: 100 = $1.00USD 

=item memo

A memo that is displayed to the customer on the invoice payment screen. [max length: 4000] 

=item name

The name of the customer we are invoicing.  This is optional if customer or invoiceToCopy is provided.  A new customer will be created using the the name and email. [max length: 50, min length: 2] 

=item note

This field can be used to store a note that is not displayed to the customer. [max length: 4000] 

=item reference

User defined reference field. [max length: 255] 



=item shippingAddress.city

Address city of the location where the goods or services were supplied. [max length: 255, min length: 2] 

=item shippingAddress.country

Address country of the location where the goods or services were supplied. [max length: 2, min length: 2] 

=item shippingAddress.line1

Address line 1 of the location where the goods or services were supplied. [max length: 255] 

=item shippingAddress.line2

Address line 2 of the location where the goods or services were supplied. [max length: 255] 

=item shippingAddress.name

Address name of the location where the goods or services were supplied. [max length: 255] 

=item shippingAddress.state

Address state of the location where the goods or services were supplied. [max length: 255] 

=item shippingAddress.zip

Address zip of the location where the goods or services were supplied. [max length: 32] 

=item suppliedDate

The date on which the goods or services were supplied. 

=item taxNo

The tax number or VAT id of the person who supplied the goods or services. [max length: 255] 

=item type

The type of invoice.  One of WEB or MOBILE. [valid values: WEB, MOBILE, default: WEB] 


=back

=item C<$auth>

Authentication object for accessing the API.  If no value is passed the global keys
C<$Net::Simplify::public_key> and C<$Net::Simplify::private_key> are used.

=back




=head3 delete()

Deletes the C<Net::Simplify::Invoice> object.  Authentication is done using the same credentials used when the AccessToken was created.



=head3 list(%criteria, $auth)

Retrieve a list of C<Net::Simplify::Invoice> objects.  The parameters are:

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

=item C<invoiceDate>

=item C<dueDate>

=item C<datePaid>

=item C<customer>

=item C<status>

=item C<dateCreated>


=back




=back

=back



=head3 find($id, $auth)

Retrieve a C<Net::Simplify::Invoice> object from the API.  Parameters are:

=over 4

=item C<$id>

Identifier of the object to retrieve.

=item C<$auth>

Authentication object for accessing the API.  If no value is passed the global keys
C<$Net::Simplify::public_key> and C<$Net::Simplify::private_key> are used.

=back




=head3 update()

Update C<Net::Simplify::Invoice> object.
The properties that can be updated are:

=over 4


=item C<billingAddress.city>

Billing address city of the location where the goods or services were supplied. [max length: 255, min length: 2] 

=item C<billingAddress.country>

Billing address country of the location where the goods or services were supplied. [max length: 2, min length: 2] 

=item C<billingAddress.line1>

Billing address line 1 of the location where the goods or services were supplied. [max length: 255] 

=item C<billingAddress.line2>

Billing address line 2 of the location where the goods or services were supplied. [max length: 255] 

=item C<billingAddress.name>

Billing address name of the location where the goods or services were supplied. [max length: 255] 

=item C<billingAddress.state>

Billing address state of the location where the goods or services were supplied. [max length: 255] 

=item C<billingAddress.zip>

Billing address zip of the location where the goods or services were supplied. [max length: 32] 

=item C<businessAddress.city>

Business address city of the business that is sending the invoice. [max length: 255, min length: 2] 

=item C<businessAddress.country>

Business address country of the business that is sending the invoice. [max length: 2, min length: 2] 

=item C<businessAddress.line1>

Business address line 1 of the business that is sending the invoice. [max length: 255] 

=item C<businessAddress.line2>

Business address line 2 of the business that is sending the invoice. [max length: 255] 

=item C<businessAddress.name>

Business address name of the business that is sending the invoice. [max length: 255] 

=item C<businessAddress.state>

Business address state of the business that is sending the invoice. [max length: 255] 

=item C<businessAddress.zip>

Business address zip of the business that is sending the invoice. [max length: 32] 

=item C<currency>

Currency code (ISO-4217). Must match the currency associated with your account. [max length: 3, min length: 3] 

=item C<customerTaxNo>

The tax number or VAT id of the person to whom the goods or services were supplied. [max length: 255] 

=item C<datePaid>

This is the date the invoice was PAID in UTC millis. 

=item C<discountRate>

The discount percent as a decimal e.g. 12.5.  This is used to calculate the discount amount which is subtracted from the total amount due before any tax is applied. [max length: 6] 

=item C<dueDate>

The date invoice payment is due.  If a late fee is provided this will be added to the invoice total is the due date has past. 

=item C<email>

The email of the customer we are invoicing.  This is optional if customer or invoiceToCopy is provided.  A new customer will be created using the the name and email. 


=item C<invoiceId>

User defined invoice id. If not provided the system will generate a numeric id. [max length: 255] 

=item C<items.amount>

Amount of the invoice item in the smallest unit of your currency. Example: 100 = $1.00USD (B<required>) 

=item C<items.description>

The description of the invoice item. [max length: 1024] 

=item C<items.invoice>

The ID of the invoice this item belongs to. 

=item C<items.product>

The Id of the product this item refers to. 

=item C<items.quantity>

Quantity of the item.  This total amount of the invoice item is the amount * quantity. [min value: 1, max value: 999999, default: 1] 

=item C<items.reference>

User defined reference field. [max length: 255] 

=item C<items.tax>

The tax ID of the tax charge in the invoice item. 

=item C<lateFee>

The late fee amount that will be added to the invoice total is the due date is past due.  Value provided must be in the smallest unit of your currency. Example: 100 = $1.00USD 

=item C<memo>

A memo that is displayed to the customer on the invoice payment screen. [max length: 4000] 

=item C<name>

The name of the customer we are invoicing.  This is optional if customer or invoiceToCopy is provided.  A new customer will be created using the the name and email. [max length: 50, min length: 2] 

=item C<note>

This field can be used to store a note that is not displayed to the customer. [max length: 4000] 

=item C<payment>

The ID of the payment.  Use this ID to query the /payment API. [max length: 255] 

=item C<reference>

User defined reference field. [max length: 255] 

=item C<shippingAddress.city>

Address city of the location where the goods or services were supplied. [max length: 255, min length: 2] 

=item C<shippingAddress.country>

Address country of the location where the goods or services were supplied. [max length: 2, min length: 2] 

=item C<shippingAddress.line1>

Address line 1 of the location where the goods or services were supplied. [max length: 255] 

=item C<shippingAddress.line2>

Address line 2 of the location where the goods or services were supplied. [max length: 255] 

=item C<shippingAddress.name>

Address name of the location where the goods or services were supplied. [max length: 255] 

=item C<shippingAddress.state>

Address state of the location where the goods or services were supplied. [max length: 255] 

=item C<shippingAddress.zip>

Address zip of the location where the goods or services were supplied. [max length: 32] 

=item C<status>

New status of the invoice. 

=item C<suppliedDate>

The date on which the goods or services were supplied. 

=item C<taxNo>

The tax number or VAT id of the person who supplied the goods or services. [max length: 255] 

Authentication is done using the same credentials used when the AccessToken was created.

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
    my $result = Net::Simplify::SimplifyApi->send_api_request("invoice", 'create', $params, $auth);

    $class->SUPER::new($result, $auth);
}

sub delete {

    my ($self) = @_;

    my $auth = Net::Simplify::SimplifyApi->get_authentication($self->{_authentication});

    my $id = $self->{id};
    $self->merge(Net::Simplify::SimplifyApi->send_api_request("invoice", 'delete', {id => $id}, $auth));
}

sub list {
    my ($class, $criteria, $auth) = @_;
   
    $auth = Net::Simplify::SimplifyApi->get_authentication($auth);
    my $result = Net::Simplify::SimplifyApi->send_api_request("invoice", 'list', $criteria, $auth);

    Net::Simplify::DomainList->new($result, $class, $auth);
}

sub find {
    my ($class, $id, $auth) = @_;

    $auth = Net::Simplify::SimplifyApi->get_authentication($auth);
    my $result = Net::Simplify::SimplifyApi->send_api_request("invoice", 'find', { id => $id }, $auth);

    $class->SUPER::new($result, $auth);
}

sub update {

    my ($self) = @_;

    my $auth = Net::Simplify::SimplifyApi->get_authentication($self->{_authentication});
    my $params = { %$self };
    delete $params->{_authentication};

    $self->merge(Net::Simplify::SimplifyApi->send_api_request("invoice", 'update', $params, $auth));
}


1;
