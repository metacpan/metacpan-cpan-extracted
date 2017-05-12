package Search::InvertedIndex::Query;

# $RCSfile: Query.pm,v $ $Revision: 1.7 $ $Date: 1999/10/20 16:35:45 $ $Author: snowhare $

use strict;
use Carp;
use Class::NamedParms;
use Class::ParmList;
use vars qw (@ISA $VERSION);

@ISA     = qw (Class::NamedParms);
$VERSION = '1.01';

=head1 NAME

Search::InvertedIndex::Query - A query for an inverted index search.

=head1 SYNOPSIS

=head1 DESCRIPTION

Provides methods for setting up a search query to be performed 
by the search engine.

=head1 CHANGES

 1.01 1999.06.30 - Documentation updates

=head2 Public API

Inherits 'get','set','clear' and 'exists' methods from Class::NamedParms

=cut

####################################################################

=head2 Initialization

=over 4

=item C<new($parm_ref);>

Returns and optionally initializes a new Search::InvertedIndex::Query
object.

Examples:

  my $query = Search::InvertedIndex::Query->new;

  my $query = Search::InvertedIndex::Query->new({ -logic => 'or',
                                                 -weight => 0.5,
                                                  -nodes => \@query_nodes,
                                                  -leafs => \@leaf_nodes,
                                                 });

-nodes must be 'Search::InvertedIndex::Query' objects.
-leafs must be 'Search::InvertedIndex::Query::Leaf' objects.
-logic applies to both -nodes (after search resolution) and -leafs.
       If omitted, -logic is defaults to 'and'. Allowed logic values
	   are 'and', 'or' and  'nand'.
-weight is applied to the _result_ of a search of the Query object and
        is optional (defaulted to '1' if omitted).

Inherits 'get/set' methods from Class::NamedParms - thus to 'append'
use the 'get' method on '-nodes' or '-leafs',  'push' the new
thing on the end of the anon array return, and use the 'set' method
to save the updated anon array.

=back

=cut

sub new {
    my $proto = shift;
    my $class = ref ($proto) || $proto;
    my $self  = Class::NamedParms->new(-logic, -nodes, -leafs, -weight);

    bless $self,$class;

   # Read any passed parms
    my ($parm_ref) = {};
    if ($#_ == 0) {
        $parm_ref  = shift; 
    } elsif ($#_ > 0) { 
        %$parm_ref = @_; 
    }


    my $parms = Class::ParmList->new({ -parms => $parm_ref,
                                       -legal => [-logic, -nodes, -leafs, -weight],
                                    -required => [],
                                    -defaults => { -logic => 'and',
                                                   -nodes => [],
                                                  -leafs => [],
                                                 -weight => 1,
                                              },
                               });
       if (not defined $parms) {
           my $error_message = Class::ParmList->error;
           croak (__PACKAGE__ . "::new() - $error_message\n");
    }

    $self->set($parms->all_parms);

    $self;
}

####################################################################

=head1 COPYRIGHT

Copyright 1999, Benjamin Franz (<URL:http://www.nihongo.org/snowhare/>) and 
FreeRun Technologies, Inc. (<URL:http://www.freeruntech.com/>). All Rights Reserved.
This software may be copied or redistributed under the same terms as Perl itelf.

=head1 AUTHOR

Benjamin Franz

=head1 TODO

Everything.

=cut

1;

