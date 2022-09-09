package Net::Simplify::Domain;

=head1 NAME

Net::Simplify::Domain - Simplify Commerce domain object base class

=head1 DESCRIPTION

Base class for all Simplify Commerce domain object classes.   Each domain object is represented
as a hierarchy of hash maps.

=head2 METHODS

=head3 C<merge($hash)>

Merges the hash map C<$hash> into the hash map of the object overwriting existing key mappings.

=head3 C<clear()>

Removes all entries from the object's hash map.

=head1 SEE ALSO

L<Net::Simplify>,
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

sub new {

    my ($class, $params, $auth) = @_;
    
    $params->{_authentication} = $auth;

    bless $params, $class
}


sub merge {
    my ($self, $hash) = @_;

    for my $k (keys %$hash) {
        if (ref $hash->{$k} eq 'HASH') {
            if (!defined $self->{$k}) {
                $self->{$k} = $hash->{$k};
            } else {
                if (ref $self->{$k} ne 'HASH') {
                    $self->{$k} = {};
                }
                merge($self->{$k}, $hash->{$k});
            }   
        } else {
            $self->{$k} = $hash->{$k};
        }
    }
}

sub clear {
    my ($self) = @_;

    foreach my $k (keys %{$self}) {
        delete $self->{$k};
    }
}

1;

