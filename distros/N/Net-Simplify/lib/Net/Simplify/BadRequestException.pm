
package Net::Simplify::BadRequestException;

=head1 NAME

Net::Simplify::BadRequestException - Simplify Commerce exception for bad request errors

=head1 SYNOPSIS

  use Net::Simplify;

  $Net::Simplify::public_key = 'YOUR PUBLIC KEY';
  $Net::Simplify::private_key = 'YOUR PRIVATE KEY';

  eval {
      my $payment = Net::Simplify::Payment->create(...);
  };
  if ($@) {
      if ($@->isa('Net::Simplify::BadRequestException')) {
          printf "API Exception: %s %s\n", $@->message, $@->code;
          if ($@->has_field_errors) {
              foreach my $e ($@->field_errors) {
                  printf "Field error: %s %s %s\n", $e->field, $e->code, $e->message;
              }
          }
      }
  }
 
=head1 DESCRIPTION

An exception that is thrown for any API call that fails due to errors in the request.  If the request contains field errors
(for example missing fields or constraint violations) a list of field error objects can be obtained giving details on each
error.  See the base class L<Net::Simplify::ApiException> for additional of methods.

=head2 METHODS

=head3 has_field_errors()

Whether there are any field errors.

=head3 field_errors()

Returns an array of field errors (L<Net::Simplify::FieldError>).

=head3 stringify()

Returns a string representation of the exception.

=head1 SEE ALSO

L<Net::Simplify>,
L<Net::Simplify::ApiException>,
L<Net::Simplify::FieldError>,
L<http://www.simplify.com>

=head1 VERSION

1.6.0

=head1 LICENSE

Copyright (c) 2013 - 2022 MasterCard International Incorporated
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

=cut

use 5.006;
use strict;
use warnings FATAL => 'all';

use Net::Simplify::ApiException;

our @ISA = qw(Net::Simplify::ApiException);

use overload ('""' => 'stringify');

sub new {
    my ($class, $message, $status, $error_data) = @_;

    my $self = $class->SUPER::new($message, $status, $error_data);

    if ($error_data) {
        my $error = $error_data->{error};
        if (defined $error) {
            my $field_errors = $error->{fieldErrors};
            if (defined $field_errors) {
                foreach my $field_error (@{$field_errors}) {
                    push(@{$self->{field_errors}}, Net::Simplify::FieldError->new($field_error));
                }
            }
        }
    }

    bless $self, $class
}

sub has_field_errors {
    my ($self) = @_;

    my @list = @{$self->{field_errors}};
    my $size = @list;

    $size > 0;
}

sub field_errors {
    my ($self) = @_;

    @{$self->{field_errors}};    
}

sub stringify {
    my ($self) = @_;

    my $msg = $self->SUPER::stringify;
    foreach my $field_error ($self->field_errors()) {
        $msg .= $field_error;
    }

    $msg;
}


1;
