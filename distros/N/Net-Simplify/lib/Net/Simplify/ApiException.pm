
package Net::Simplify::ApiException;

=head1 NAME

Net::Simplify::ApiException - Simplify Commerce exception base class.

=head1 SYNOPSIS

  use Net::Simplify;

  $Net::Simplify::public_key = 'YOUR PUBLIC KEY';
  $Net::Simplify::private_key = 'YOUR PRIVATE KEY';

  eval {
      my $payment = Net::Simplify::Payment->create(...);
  };
  if ($@) {
      if ($@->isa('Net::Simplify::ApiException')) {
          my $message = $@->message;
          my $code = $@->code;
          printf "API Exception: %s %s\n", $@->message, $@->code;
      }
  }
 
=head1 DESCRIPTION

All exceptions thrown when using the API have the ApiException as their base class.

=head3 status()

Returns the HTTP status code for the API exception (if any).

=head3 code()

Returns error code for the API exeption (if any).

=head3 reference()

Returns the reference string for the API exception (if any).

=head3 message()

Returns the error message for the API exception.

=head3 stringify()

Returns a string representation of the exception.

=head3 longmess()

Returns the callstack.

=head1 SEE ALSO

L<Net::Simplify>,
L<Net::Simplify::IllegalArgumentException>,
L<Net::Simplify::AuthorizationException>,
L<Net::Simplify::ObjectNotFoundException>,
L<Net::Simplify::NotAllowedException>,
L<Net::Simplify::BadRequestException>,
L<Net::Simplify::SystemException>,
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

use Carp;
use overload ('""' => 'stringify');

sub new {
    my ($class, $message, $status, $error_data) = @_;

    my $self = {
        message => $message,
        status => $status,
        longmess => Carp::longmess,
        errorData => $error_data,
        field_errors => []
    };

    if ($error_data) {
        $self->{reference} = $error_data->{reference};
        my $error = $error_data->{error};
        if (defined $error) {
            $self->{code} = $error->{code};
        }
        $self->{message} = $error->{message} if defined $error->{message};
    }
    bless $self, $class;
}

sub status {
    my ($self) = @_;
    $self->{status};
}

sub code {
    my ($self) = @_;
    $self->{code};
}

sub reference {
    my ($self) = @_;
    $self->{reference};
}

sub message {
    my ($self) = @_;
    $self->{message};
}

sub longmess {
    my ($self) = @_;
    $self->{longmess};
}

sub stringify {
    my ($self) = @_;

    my $class = ref $self;
    my $status = defined $self->{status} ? $self->{status} : 'n/a';
    my $code = defined $self->{code} ? $self->{code} : 'n/a';
    my $reference = defined $self->{reference} ? $self->{reference} : 'n/a';
    my $message = $self->{message};

    "${class}: '${message}' (status: ${status}, code: ${code}, reference ${reference})\n";
}

1;
