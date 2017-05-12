package Net::Simplify::DomainList;

=head1 NAME

Net::Simplify::DomainList - Simplify Commerce class representing a list of domain objects

=head1 SYNOPSIS

  use Net::Simplify;

  $Net::Simplify::public_key = 'YOUR PUBLIC KEY';
  $Net::Simplify::private_key = 'YOUR PRIVATE KEY';

  my $ret = Net::Simplify::Payment->list({});

  printf "Total: %d\n", $ret->total;
  foreach my $o ($ret->list) {
      printf " %s\n", $o->{id};
  }

=head1 DESCRIPTION

Class for holding results from a list method on a domain class.

=head1 METHODS

=head3 total()

The total number of domain objects matching the search criteria used to generate the list.

=head3 size()

The number of domain objects in the list.

=head3 list()

The list of domain objects.

=head1 SEE ALSO

L<Net::Simplify>,
L<Net::Simplify::Domain>,
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

=cut

use 5.006;
use strict;
use warnings FATAL => 'all';

sub new {

    my ($class, $params, $domain_class, $auth) = @_;   

    my $self = {
        total => $params->{total},
        max => $params->{max},
        offset => $params->{offset},
        filter => $params->{filter},
        sorting => $params->{sorting},
        list => []
    };

    foreach my $obj (@{$params->{list}}) {
        my $domain = $domain_class->new($obj, $auth);
        push(@{$self->{list}}, $domain);
    }
    
    bless $self, $class;
}

sub total {
    my ($self) = @_;

    $self->{total};
}

sub list {
    my ($self) = @_;

    @{$self->{list}};
}

sub size {
    my ($self) = @_;
    
    my @list = @{$self->{list}};
    
    my $size = @list;

    $size;
}

1;

