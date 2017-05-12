package Search::InvertedIndex::Query::Leaf;

# $RCSfile: Leaf.pm,v $ $Revision: 1.5 $ $Date: 1999/06/15 17:17:18 $ $Author: snowhare $

use strict;
use Carp;
use Class::NamedParms;
use Class::ParmList;
use vars qw(@ISA $VERSION);

@ISA     = qw (Class::NamedParms);
$VERSION = '1.00';

=head1 NAME

Search::InvertedIndex::Query::Leaf - A query leaf item for an inverted index search.

=head1 SYNOPSIS

=head1 DESCRIPTION

Provides an object for holding the specifics of a search term item.

=cut

####################################################################

=over 4

=item C<new($parm_ref);>

Creates and initializes a Search::InvertedIndex::Query::Leaf
object:

 Example: 
  my $leaf = Search::InvertedIndex::Query::Leaf->new({
                                             -key => 'sterling',
                                           -group => 'wineries',
                                          -weight => 1,
                                           });

 -group and -key are required, -weight is optional.

Inherits 'get','set','clear','exists' methods from Class::NamedParms

=back

=cut

sub new {
    my $proto = shift;
    my $class = ref ($proto) || $proto;
    my $self  = Class::NamedParms->new(-group, -key, -weight);

    bless $self,$class;

    # Read any passed parms
    my ($parm_ref) = {};
    if ($#_ == 0) {
        $parm_ref  = shift; 
    } elsif ($#_ > 0) { 
        %$parm_ref = @_; 
    }
    my $parms = Class::ParmList->new({ -parms => $parm_ref,
                                       -legal => [-weight],
                                    -required => [-group, -key],
                                    -defaults => { -weight => 1 },
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

Document.

=cut

1;

