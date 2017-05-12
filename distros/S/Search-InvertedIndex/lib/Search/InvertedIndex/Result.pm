package Search::InvertedIndex::Result;

# $RCSfile: Result.pm,v $ $Revision: 1.5 $ $Date: 1999/10/20 16:35:45 $ $Author: snowhare $

use strict;
use Carp;
use Class::NamedParms;
use Class::ParmList;
use vars qw (@ISA $VERSION);
@ISA     = qw (Class::NamedParms);
$VERSION = "1.00";

=head1 NAME 

Search::InvertedIndex::Result - A list of result entries from a inverted index search.

=head1 SYNOPSIS

=head1 DESCRIPTION

Contains zero or more result entries from a search. Provides access methods
to information in/from/about the entries.

=head1 CHANGES

 1.00 1999.6.16 - Initial release

 1.01 1999.6.17 - Documentation fixes

=head2 Public API

=cut

####################################################################

=head2 Initialization

=over 4

=item C<new($parm_ref);>

=back

=cut

sub new {
	my $proto = shift;
    my $class = ref ($proto) || $proto;
	my $self  = Class::NamedParms->new(qw(-inv_map -indexes -keys -use_cache -query));

	bless $self,$class;

   # Read any passed parms
    my ($parm_ref) = {};
    if ($#_ == 0) {
        $parm_ref  = shift; 
    } elsif ($#_ > 0) { 
        %$parm_ref = @_; 
    }

	my $parms = Class::ParmList->new({ -parms => $parm_ref,
    	                               -legal => [qw(-inv_map -indexes -keys -use_cache -query)],
    	                            -required => [],
    	                            -defaults => {},
                                });
   	if (not defined $parms) {
   	    my $error_message = Class::ParmList->error;
   	    croak (__PACKAGE__ . "::new() - $error_message\n");
	}

	$self->set($parms->all_parms);

	$self;
}

####################################################################

=over 4

=item C<number_of_index_entries;>

Returns the number of index entries in the result.

=back

=cut

sub number_of_index_entries {
	my  ($self) = shift;

	my $indexes = $self->get(-indexes);
	return 0 if (not defined $indexes);
	$#$indexes + 1;
}

####################################################################

=over 4

=item C<entry($parm_ref);>

In an array context, returns the index, data and ranking for the requested entry.

In a scalar context returns only the index.

Examples:

	my $index = $result->entry({ -number => 10 };

	my ($index,$data,$ranking) = $result->entry({ -number => 10 });

=back

=cut

sub entry {
	my  ($self) = shift;

   # Read passed parms
    my ($parm_ref) = {};
    if ($#_ == 0) {
        $parm_ref  = shift; 
    } elsif ($#_ > 0) { 
        %$parm_ref = @_; 
    }

	my $parms = Class::ParmList->new({ -parms => $parm_ref,
    	                               -legal => [qw(-number)],
    	                            -required => [],
    	                            -defaults => {},
                               });
   	if (not defined $parms) {
   	    my $error_message = Class::ParmList->error;
   	    croak (__PACKAGE__ . "::new() - $error_message\n");
	}
	my ($number) = $parms->get(-number);
	my $indexes = $self->get(-indexes);
	return if ((not defined $indexes) or ($number < 0) or ($number > $#$indexes) or ($number != int($number)));
	my ($inv_map) = $self->get(-inv_map);
	my ($entry)   = $indexes->[$number];
	my ($index_enum) = $entry->{-index_enum};
	my ($entry_data) = $inv_map->_get_data_for_index_enum({ -index_enum => $index_enum });
	return if (not defined $entry_data);
	if (not wantarray) {
		return $entry_data->{'-index'}; 
	}
	return ($entry_data->{'-index'},$entry_data->{-data},$entry->{-ranking});
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
