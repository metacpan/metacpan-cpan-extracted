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
package SQL::Functional::JoinClause;
$SQL::Functional::JoinClause::VERSION = '0.3';
use strict;
use warnings;
use Moose;
use Moose::Util::TypeConstraints 'enum';
use namespace::autoclean;
use SQL::Functional::Clause;
use SQL::Functional::TableClause;

with 'SQL::Functional::Clause';

enum 'POSSIBLE_TYPES', [qw{ inner left right full }];

has table => (
    is => 'ro',
    isa => 'SQL::Functional::TableClause',
    required => 1,
);
has field1 => (
    is => 'ro',
    isa => 'SQL::Functional::FieldClause',
    required => 1,
);
has field2 => (
    is => 'ro',
    isa => 'SQL::Functional::FieldClause',
    required => 1,
);
has type => (
    is => 'ro',
    isa => 'POSSIBLE_TYPES',
    default => 'inner',
);

sub to_string
{
    my ($self) = @_;
    my $type_str =
        $self->type eq 'inner' ? 'INNER JOIN' :
        $self->type eq 'left'  ? 'LEFT JOIN' :
        $self->type eq 'right' ? 'RIGHT JOIN' :
        $self->type eq 'full'  ? 'FULL JOIN' :
        'INNER JOIN'; # Don't know what it is, so just have it default
    return $type_str . ' '
        . $self->table->to_string
        . ' ON ' . $self->field1->to_string
        . ' = ' . $self->field2->to_string;
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__

