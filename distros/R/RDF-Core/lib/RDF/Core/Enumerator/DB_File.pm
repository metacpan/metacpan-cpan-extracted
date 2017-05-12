# 
# The contents of this file are subject to the Mozilla Public
# License Version 1.1 (the "License"); you may not use this file
# except in compliance with the License. You may obtain a copy of
# the License at http://www.mozilla.org/MPL/
# 
# Software distributed under the License is distributed on an "AS
# IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
# implied. See the License for the specific language governing
# rights and limitations under the License.
# 
# The Original Code is the RDF::Core module
# 
# The Initial Developer of the Original Code is Ginger Alliance Ltd.
# Portions created by Ginger Alliance are 
# Copyright (C) 2001 Ginger Alliance Ltd.
# All Rights Reserved.
# 
# Contributor(s):
# 
# Alternatively, the contents of this file may be used under the
# terms of the GNU General Public License Version 2 or later (the
# "GPL"), in which case the provisions of the GPL are applicable 
# instead of those above.  If you wish to allow use of your 
# version of this file only under the terms of the GPL and not to
# allow others to use your version of this file under the MPL,
# indicate your decision by deleting the provisions above and
# replace them with the notice and other provisions required by
# the GPL.  If you do not delete the provisions above, a recipient
# may use your version of this file under either the MPL or the
# GPL.
# 

package RDF::Core::Enumerator::DB_File;

use strict;
require Exporter;

our @ISA = qw(RDF::Core::Enumerator);
use Carp;

#use constants from RDF::Core::Storage::DB_File
use constant NAMESPACE => RDF::Core::Storage::DB_File::NAMESPACE;
use constant VALUE => RDF::Core::Storage::DB_File::VALUE;
use constant LITERAL => RDF::Core::Storage::DB_File::LITERAL;
use constant LIT_LANG => RDF::Core::Storage::DB_File::LIT_LANG;
use constant LIT_TYPE => RDF::Core::Storage::DB_File::LIT_TYPE;
use constant SUBJECT => RDF::Core::Storage::DB_File::SUBJECT;
use constant PREDICATE => RDF::Core::Storage::DB_File::PREDICATE;
use constant OBJECT_RES => RDF::Core::Storage::DB_File::OBJECT_RES;
use constant OBJECT_LIT => RDF::Core::Storage::DB_File::OBJECT_LIT;


sub new {
    #Gets a hash tied to a data file (see RDF::Core::Storage::DB_File->{_data})
    # and an array of statements' indexes in the hash 
    # or undef for all statements
    my ($pkg,$data,$stmtArray)=@_;
    $pkg = ref $pkg || $pkg;
    my $self = {};
    $self->{_data} = $data;
    $self->{_stmtArray} = $stmtArray;
    $self->{_count} = 0;
    bless $self,$pkg;
}
sub getFirst {
    my $self = shift;
    #reset counter
    $self->{_count} = 0;

    return $self->getNext;
}
sub getNext {
    my $self = shift;
    my $subPrefix = SUBJECT;
    my ($key, $value);
    if (defined $self->{_stmtArray}) {
	$key = $self->{_stmtArray}->[$self->{_count}++]
    } else {
	#brute force iteration through all possible statements
	#TODO: find some better way of iteration
	do { 
	} until (defined $self->{_data}->{+SUBJECT.$self->{_count}++} || 
		 $self->{_count} > $self->{_data}->{_statements});
	#pretty dirty - {_data}->{_statements} is a private member of RDF::Core::Storage::DB_File
	#TODO: FIND SOME BETTER WAY OF ITERATION
	if ($self->{_count} > $self->{_data}->{_statements}) {
	    undef $key;
	} else {
	    $key = $self->{_count}
	}
    }
    return undef		#end of data
      unless defined $key;
    #create and return statement
    my ($subNS,$subLV,$predNS,$predLV, $objNS, $objLV, $objValue, 
	$litLang, $litDatatype, $index);
    my $isLiteral;
    $index = $self->{_data}->{+SUBJECT.$key};
    $subNS = $self->{_data}->{+NAMESPACE.$index};
    $subLV = $self->{_data}->{+VALUE.$index};
    $index = $self->{_data}->{+PREDICATE.$key};
    $predNS = $self->{_data}->{+NAMESPACE.$index};
    $predLV = $self->{_data}->{+VALUE.$index};
    if ($isLiteral = exists($self->{_data}->{+OBJECT_LIT.$key})) {
	$index  =  $self->{_data}->{+OBJECT_LIT.$key};
	$objValue = $self->{_data}->{+LITERAL.$index};
	$litDatatype = $self->{_data}->{+LIT_TYPE.$index};
	$litLang = $self->{_data}->{+LIT_LANG.$index};
    } else {
	$index  =  $self->{_data}->{+OBJECT_RES.$key};
	$objNS = $self->{_data}->{+NAMESPACE.$index};
	$objLV = $self->{_data}->{+VALUE.$index};
	$objValue = $objNS.$objLV;
    }
    my $newsub = new RDF::Core::Resource($subNS,$subLV);
    my $newpred = new RDF::Core::Resource($predNS.$predLV);
    my $newobj;
    if ($isLiteral) {
	$newobj = new RDF::Core::Literal($objValue, $litLang, 
					 $litDatatype);

    } else {
	$newobj = new RDF::Core::Resource($objNS,$objLV)
    }
    my $statement = new RDF::Core::Statement($newsub,$newpred,$newobj);
    return $statement;
}
sub close {
    $_[0]->{_stmtArray} = undef;
}

1;

__END__

=head1 NAME

RDF::Core::Enumerator::DB_File - Enumerator that can be used with DB_File storage.

=head1 DESCRIPTION

Enumerator is a set of statements retrieved from a model.
When DB_File enumerator is created, it references statements in it's storage rather then making in-memory copy of all data, so it's vulnerable to adding / removing statements.

=head2 Interface

=over 4

=item * new(\%data, \@stmtArray)

%data is a hash tied to RDF::Core::Storage::DB_File data and @stmtArray is an array of statements indexes in %data.

=back

The rest of the interface is described in RDF::Core::Enumerator.

=head1 LICENSE

This package is subject to the MPL (or the GPL alternatively).

=head1 AUTHOR

Ginger Alliance, rdf@gingerall.cz

=head1 SEE ALSO

  RDF::Core::Enumerator, RDF::Core::Model, RDF::Core::Storage

=cut

