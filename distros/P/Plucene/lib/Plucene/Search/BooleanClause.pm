package Plucene::Search::BooleanClause;

=head1 NAME 

Plucene::Search::BooleanClause - A clause in a boolean query

=head1 DESCRIPTION

A clause in a boolean query.

=head1 METHODS

=cut

use strict;
use warnings;

use base 'Class::Accessor::Fast';

=head2 query / required / prohibited

Get / set these attributes

=cut

__PACKAGE__->mk_accessors(qw(query required prohibited));

1;
