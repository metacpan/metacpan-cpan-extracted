# Copyright (c) 2016  Timm Murray
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without 
# modification, are permitted provided that the following conditions are met:
# 
#     * Redistributions of source code must retain the above copyright notice, 
#       this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright 
#       notice, this list of conditions and the following disclaimer in the 
#       documentation and/or other materials provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE 
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
# POSSIBILITY OF SUCH DAMAGE.
package SQL::Functional::FunctionClause;
$SQL::Functional::FunctionClause::VERSION = '0.3';
use strict;
use warnings;
use Moose;
use namespace::autoclean;
use SQL::Functional::Clause;
use SQL::Functional::TableClause;

with 'SQL::Functional::Clause';

has name => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);
has args => (
    is => 'ro',
    isa => 'SQL::Functional::Type::Literals',
    required => 1,
    auto_deref => 1,
    coerce => 1,
);


sub to_string
{
    my ($self) = @_;
    my $name = $self->name;
    my @args = $self->args;
    
    my $sql = $name . '(' . join( ',', map {
        $_->to_string
    } @args ) . ')';
    return $sql;
}

sub get_params
{
    my ($self) = @_;
    my @args = $self->args;
    my @params = map { $_->get_params } @args;
    return @params;
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__

