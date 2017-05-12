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

package RDF::Core::Storage::DB_File;

use strict;
require Exporter;

our @ISA = qw(RDF::Core::Storage);

use Carp;
use DB_File;
require RDF::Core::Storage;
require RDF::Core::Literal;
require RDF::Core::Resource;
require RDF::Core::Statement;
require RDF::Core::Enumerator::Memory;
require RDF::Core::Enumerator::DB_File;


#There are several entities stored in one file (tied hash) _data. Their key is a prefix + generated number, value is context dependent.
#Prefixes:
#in _data hash
use constant NAMESPACE => 'ns';         #resource's namespace
use constant VALUE => 'lv';             #resource's value
use constant LITERAL => 'lt';           #object's literal value
use constant LIT_TYPE => 'ld';          #object's literal datatype
use constant LIT_LANG => 'll';          #object's literal language
use constant SUBJECT => 'su';           #subject number
use constant PREDICATE => 'pr';         #predicate number
use constant OBJECT_RES => 'or';        #object number, if object is resource
use constant OBJECT_LIT => 'ol';        #object number, if object is literal
use constant SUBJECT_SIZE => 'ss';      #number of statements where given 
                                        # resource is subject
use constant PREDICATE_SIZE => 'ps';    #number of statements where given
                                        # resource is predicate
use constant OBJECTRES_SIZE => 'os';    #number of statements where given
                                        # resource is object
use constant OBJECTLIT_SIZE => 'ls';    #number of statements where given
                                        # literal is object
use constant ALL_KEY => 'all';          #number of all statements in the model
#in idxStmt hash - it has duplicate values allowed
use constant SUBJECT_IDX => 'si';       #array of statements where given
                                        # resource is subject
use constant PREDICATE_IDX => 'pi';     #array of statements where given
                                        # resource is predicate
use constant OBJECTRES_IDX => 'oi';     #array of statements where given
                                        # resource is object
use constant OBJECTLIT_IDX => 'li';     #array of statements where given
                                        # literal is object

#There are two more hashes - idxRes and idxLit. Their key is URI or literal 
# value and their value is number of resource or literal in _data

$SIG{INT} = \&__catch_zap;  
my $writing;
my $die;
sub __catch_zap {
    my $signame = shift;
    if ($writing) {
	warn"Finishing operation...";
	$die++
    } else {
	die;	
    }

} 

sub new {
    my ($pkg, %options) = @_;
    $pkg = ref $pkg || $pkg;
    my $self = {};
    $self->{_options} = \%options;
    $self->{_steps}=0;

    $self->{_data} = {};
    $self->{_idxStmt} = {};
    $self->{_idxRes} = {};
    $self->{_idxLit} = {};
    ################################
    #set options
    #DB_File defaults
    $self->{_options}->{Name} ||= undef;
    $self->{_options}->{Flags} ||= O_CREAT|O_RDWR;
    $self->{_options}->{Mode} ||= 0666;
    #max nr of statements to be returned as in memory enumerator with getStmts
    $self->{_options}->{MemLimit} ||= 0;
    ################################
    #tie hashes
    my $file = $self->{_options}->{Name} && $self->{_options}->{Name}.'_data';
    tie %{$self->{_data}}, 'DB_File', $file, $self->{_options}->{Flags}, 
      $self->{_options}->{Mode}, $DB_HASH 
	or die "Couldn't tie ", $file || 'undef',": $!";
    $file = $self->{_options}->{Name} && $self->{_options}->{Name}.'_idxLit';
    tie %{$self->{_idxLit}}, 'DB_File', $file, $self->{_options}->{Flags}, 
      $self->{_options}->{Mode}, $DB_HASH 
	or die "Couldn't tie ", $file || 'undef',": $!";
    $file = $self->{_options}->{Name} && $self->{_options}->{Name}.'_idxRes';
    tie %{$self->{_idxRes}}, 'DB_File', $file, $self->{_options}->{Flags}, 
      $self->{_options}->{Mode}, $DB_HASH 
	or die "Couldn't tie ", $file || 'undef',": $!";
    $DB_BTREE->{'flags'} = R_DUP;
    $file = $self->{_options}->{Name} && $self->{_options}->{Name}.'_idxStmt';
    tie %{$self->{_idxStmt}}, 'DB_File', $file, $self->{_options}->{Flags}, 
      $self->{_options}->{Mode}, $DB_BTREE 
	or die "Couldn't tie ", $file || 'undef',": $!";
    ################################
    #init counter
    $self->{_data}->{+ALL_KEY} = 0;

    bless $self, $pkg;
}
sub addStmt {
    my ($self, $stmt) = @_;
    #print "Entering addStmt ",$self->_getCounter('debug'),"\n";

    $writing = 1;
    if ($self->existsStmt($stmt->getSubject,
			  $stmt->getPredicate,$stmt->getObject)) {
	$writing=0;
	die if $die;
	return 0;
    }
    #Add subject to resources
    my $subjectID;
    if (!defined($subjectID = $self->{_idxRes}->{$stmt->getSubject->getURI})) {
	$subjectID = $self->_getCounter('resource');
	$self->{_data}->{+NAMESPACE.$subjectID} = 
	  $stmt->getSubject->getNamespace;
	$self->{_data}->{+VALUE.$subjectID} = $stmt->getSubject->getLocalValue;
	$self->{_idxRes}->{$stmt->getSubject->getURI} = $subjectID;
    }
    #Add predicate to resources
    my $predicateID;
    if (!defined ($predicateID = 
		  $self->{_idxRes}->{$stmt->getPredicate->getURI})) {
	$predicateID = $self->_getCounter('resource');
	$self->{_data}->{+NAMESPACE.$predicateID} = 
	  $stmt->getPredicate->getNamespace;
	$self->{_data}->{+VALUE.$predicateID} = 
	  $stmt->getPredicate->getLocalValue;
	$self->{_idxRes}->{$stmt->getPredicate->getURI} = $predicateID;
    }
    #Add object to resources or literals
    my $objectID;
    if ($stmt->getObject->isLiteral) {
    	my $value	= $stmt->getObject->getValue;
    	my $lang	= $stmt->getObject->getLang;
    	my $dt		= $stmt->getObject->getDatatype;
    	my $idxLitKey	= sprintf("L%s<%s>%s", $value, $lang, $dt);
	if (!defined ($objectID = $self->{_idxLit}->{ $idxLitKey })) {
	    $objectID = $self->_getCounter('literal');
	    $self->{_data}->{+LITERAL.$objectID}=$stmt->getObject->getValue;
	    $self->{_data}->{+LIT_LANG.$objectID} = 
	      $stmt->getObject->getLang
		if $stmt->getObject->getLang;
	    $self->{_data}->{+LIT_TYPE.$objectID}=
	      $stmt->getObject->getDatatype
		if $stmt->getObject->getDatatype;
	    $self->{_idxLit}->{ $idxLitKey } = $objectID;
	}
    } else {
	if (!defined ($objectID = $self->{_idxRes}->{$stmt->getObject->getURI})) {
	    $objectID = $self->_getCounter('resource');
	    $self->{_data}->{+NAMESPACE.$objectID} =  $stmt->getObject->getNamespace;
	    $self->{_data}->{+VALUE.$objectID} = $stmt->getObject->getLocalValue;
	    $self->{_idxRes}->{$stmt->getObject->getURI} = $objectID;
	}
    }
    #Add statement and refresh indexes
    my $stmtID = $self->_getCounter('statement');
    $self->{_data}->{+SUBJECT.$stmtID} = $subjectID;
    $self->{_data}->{+SUBJECT_SIZE.$subjectID}++;
    $self->{_idxStmt}->{+SUBJECT_IDX.$subjectID} = $stmtID;
    $self->{_data}->{+PREDICATE.$stmtID} = $predicateID;
    $self->{_data}->{+PREDICATE_SIZE.$predicateID}++;
    $self->{_idxStmt}->{+PREDICATE_IDX.$predicateID} = $stmtID;
    if ($stmt->getObject->isLiteral) {
	$self->{_data}->{+OBJECT_LIT.$stmtID} = $objectID;
	$self->{_data}->{+OBJECTLIT_SIZE.$objectID}++;
	$self->{_idxStmt}->{+OBJECTLIT_IDX.$objectID} = $stmtID;
    } else {
	$self->{_data}->{+OBJECT_RES.$stmtID} = $objectID;
	$self->{_data}->{+OBJECTRES_SIZE.$objectID}++;
	$self->{_idxStmt}->{+OBJECTRES_IDX.$objectID} = $stmtID;
    }
    $self->{_data}->{+ALL_KEY} ++;
    $self->_synchronize;
    $writing=0;
    die if $die;
    return 1
}

sub removeStmt {
    my ($self, $stmt) = @_;
    return 0 unless
      my $key = $self->_getKey($stmt);
    $writing = 1;
    my $idxStmt = tied %{$self->{_idxStmt}};
    #Decrement number of occurences of resource/literal, delete not used 
    # resource/literal, remove statement from resource's/literal's index 
    # and index itself, if empty, remove statement
    my $subjectID = $self->{_data}->{+SUBJECT.$key};
    delete $self->{_data}->{+SUBJECT.$key};
    $idxStmt->del_dup(SUBJECT_IDX.$subjectID, $key);
    unless (--$self->{_data}->{+SUBJECT_SIZE.$subjectID}) {
	delete $self->{_data}->{+SUBJECT_SIZE.$subjectID};
    }
    unless ($self->{_data}->{+SUBJECT_SIZE.$subjectID} ||
	    $self->{_data}->{+PREDICATE_SIZE.$subjectID} ||
	    $self->{_data}->{+OBJECTRES_SIZE.$subjectID}) {
	delete $self->{_data}->{+NAMESPACE.$subjectID};
	delete $self->{_data}->{+VALUE.$subjectID};
	delete $self->{_idxRes}->{$stmt->getSubject->getURI};
    }
    my $predicateID = $self->{_data}->{+PREDICATE.$key};
    delete $self->{_data}->{+PREDICATE.$key};
    $idxStmt->del_dup(PREDICATE_IDX.$predicateID, $key);
    unless (--$self->{_data}->{+PREDICATE_SIZE.$predicateID}) {
	delete $self->{_data}->{+PREDICATE_SIZE.$predicateID};
    }
    unless ($self->{_data}->{+SUBJECT_SIZE.$predicateID} ||
	    $self->{_data}->{+PREDICATE_SIZE.$predicateID} ||
	    $self->{_data}->{+OBJECTRES_SIZE.$predicateID}) {
	delete $self->{_data}->{+NAMESPACE.$predicateID};
	delete $self->{_data}->{+VALUE.$predicateID};
	delete $self->{_idxRes}->{$stmt->getPredicate->getURI};
    }
    my $objectID;
    if ($stmt->getObject->isLiteral) {
	$objectID = $self->{_data}->{+OBJECT_LIT.$key};
	delete $self->{_data}->{+OBJECT_LIT.$key};
	$idxStmt->del_dup(OBJECTLIT_IDX.$objectID, $key);
	unless (--$self->{_data}->{+OBJECTLIT_SIZE.$objectID}) {
	    delete $self->{_data}->{+OBJECTLIT_SIZE.$objectID};
	    delete $self->{_data}->{+LITERAL.$objectID};
	    delete $self->{_data}->{+LIT_TYPE.$objectID};
	    delete $self->{_data}->{+LIT_LANG.$objectID};
	    my $value	= $stmt->getObject->getValue;
	    my $lang	= $stmt->getObject->getLang;
	    my $dt		= $stmt->getObject->getDatatype;
	    my $idxLitKey	= sprintf("L%s<%s>%s", $value, $lang, $dt);
	    delete $self->{_idxLit}->{ $idxLitKey };
	}
    } else {
	$objectID = $self->{_data}->{+OBJECT_RES.$key};
	delete $self->{_data}->{+OBJECT_RES.$key};
	$idxStmt->del_dup(OBJECTRES_IDX.$objectID, $key);
	unless (--$self->{_data}->{+OBJECTRES_SIZE.$objectID}) {
	    delete $self->{_data}->{+OBJECTRES_SIZE.$objectID};
	}
	unless ($self->{_data}->{+OBJECTRES_SIZE.$objectID} ||
		$self->{_data}->{+SUBJECT_SIZE.$objectID} ||
		$self->{_data}->{+PREDICATE_SIZE.$objectID}) {
	    delete $self->{_data}->{+NAMESPACE.$objectID};
	    delete $self->{_data}->{+VALUE.$objectID};
	    delete $self->{_idxRes}->{$stmt->getObject->getURI};
	}
    }
    $self->{_data}->{+ALL_KEY} --;
    undef $idxStmt;
    $self->_synchronize;
    $writing = 0;
    die if $die;
    return 1;
}

sub existsStmt {
    #print "Entering existsStmt\n";
    my ($self, $subject, $predicate, $object) = @_;
    my $retval = 0;
    return $self->{_data}->{+ALL_KEY} > 0 ? 1 : 0
      if !defined $subject && !defined $predicate && !defined $object;
    foreach (@{$self->_getIndexArray($subject, $predicate, $object)}) {
	my ($subURI, $predURI,  $objValue, $index);
	$index = $self->{_data}->{+SUBJECT.$_};
	$subURI = $self->{_data}->{+NAMESPACE.$index}.
	  $self->{_data}->{+VALUE.$index};
	$index = $self->{_data}->{+PREDICATE.$_};
	$predURI = $self->{_data}->{+NAMESPACE.$index}.
	  $self->{_data}->{+VALUE.$index};
	if (exists $self->{_data}->{+OBJECT_LIT.$_}) {
	    $index  =  $self->{_data}->{+OBJECT_LIT.$_};
	    $objValue = $self->{_data}->{+LITERAL.$index};
	} else {
	    $index  =  $self->{_data}->{+OBJECT_RES.$_};
	    $objValue = $self->{_data}->{+NAMESPACE.$index}.
	      $self->{_data}->{+VALUE.$index};
	}
	if ((!defined $subject || $subURI eq $subject->getURI) && 
	    (!defined $predicate || $predURI eq $predicate->getURI) && 
	    (!defined $object || $objValue eq $object->getLabel)
	   ) {
	    $retval = 1;	#found statement
	    last;
	}
    }
    #print "Returning $retval\n";
    return $retval;
}

sub getStmts {
    my ($self, $subject, $predicate, $object) = @_;
    my $enumerator;
    my $indexArray = $self->_getIndexArray($subject, $predicate, $object);
    my $processInMemory = !$self->{_options}->{MemLimit} ||
      @$indexArray < $self->{_options}->{MemLimit} || 
	(defined $subject && defined $predicate && defined $object);
    my @data;			#for gathering data in memory
    my $resultArray;		#index for DB_File enumerator
    if (!$processInMemory &&
	#if DB_File enumerator is to be returned and at least two elements of triple are undef, you already have what you need
	(!defined $subject && !defined $predicate ||
	 !defined $subject && !defined $object ||
	 !defined $predicate && !defined $object)) {
	$resultArray = $indexArray
    } else {
	#otherwise loop through index and check statements
	while (my $stmtIdx = pop @$indexArray) {
	    my ($subNS,$subLV,$predNS,$predLV, $objNS, $objLV, $objValue, 
		$litLang, $litDatatype, $index);
	    my $isLiteral;
	    $index = $self->{_data}->{+SUBJECT.$stmtIdx};
	    $subNS = $self->{_data}->{+NAMESPACE.$index};
	    $subLV = $self->{_data}->{+VALUE.$index};
	    $index = $self->{_data}->{+PREDICATE.$stmtIdx};
	    $predNS = $self->{_data}->{+NAMESPACE.$index};
	    $predLV = $self->{_data}->{+VALUE.$index};
	    if ($isLiteral = exists($self->{_data}->{+OBJECT_LIT.$stmtIdx})) {
		$index  =  $self->{_data}->{+OBJECT_LIT.$stmtIdx};
		$objValue = $self->{_data}->{+LITERAL.$index};
		$litDatatype = $self->{_data}->{+LIT_TYPE.$index};
		$litLang = $self->{_data}->{+LIT_LANG.$index};
	    } else {
		$index  =  $self->{_data}->{+OBJECT_RES.$stmtIdx};
		$objNS = $self->{_data}->{+NAMESPACE.$index};
		$objLV = $self->{_data}->{+VALUE.$index};
		$objValue = $objNS.$objLV;
	    }
	    if ((!defined $subject || $subNS.$subLV eq $subject->getURI) && 
		(!defined $predicate || $predNS.$predLV eq $predicate->getURI) && 
		(!defined $object || $objValue eq $object->getLabel)
	       ) {		#found statement
		if ($processInMemory) {
		    my $newsub = new RDF::Core::Resource($subNS,$subLV);
		    my $newpred = new RDF::Core::Resource($predNS,$predLV);
		    my $newobj;
		    if ($isLiteral) {
			$newobj = new RDF::Core::Literal($objValue, $litLang, 
							 $litDatatype);
		    } else {
			$newobj = new RDF::Core::Resource($objNS,$objLV)
		    }
		    my $statement = new RDF::Core::Statement($newsub,$newpred,$newobj);
		    push @data, $statement;
		} else {
		    push @$resultArray, $stmtIdx;
		}
	    }
	}
    }
    if ($processInMemory) {
	$enumerator = RDF::Core::Enumerator::Memory->new(\@data) ;
    } else {
	$enumerator = RDF::Core::Enumerator::DB_File->new($self->{_data},$resultArray);
    }
    return $enumerator;
}
sub countStmts {
    my ($self, $subject, $predicate, $object) = @_;
    my $count = 0;

    return ($self->{_data}->{+ALL_KEY})
      if !defined $subject && !defined $predicate && !defined $object;
    foreach (@{$self->_getIndexArray($subject, $predicate, $object)}) {
	my ($subNS,$subLV,$predNS,$predLV, $objNS, $objLV, $objValue, $index);
	my $isLiteral;
	$index = $self->{_data}->{+SUBJECT.$_};
	$subNS = $self->{_data}->{+NAMESPACE.$index};
	$subLV = $self->{_data}->{+VALUE.$index};
	$index = $self->{_data}->{+PREDICATE.$_};
	$predNS = $self->{_data}->{+NAMESPACE.$index};
	$predLV = $self->{_data}->{+VALUE.$index};
	if ($isLiteral = exists($self->{_data}->{+OBJECT_LIT.$_})) {
	    $index  =  $self->{_data}->{+OBJECT_LIT.$_};
	    $objValue = $self->{_data}->{+LITERAL.$index};
	} else {
	    $index  =  $self->{_data}->{+OBJECT_RES.$_};
	    $objNS = $self->{_data}->{+NAMESPACE.$index};
	    $objLV = $self->{_data}->{+VALUE.$index};
	    $objValue = $objNS.$objLV;
	}
	if ((!defined $subject || $subNS.$subLV eq $subject->getURI) && 
	    (!defined $predicate || $predNS.$predLV eq $predicate->getURI) && 
	    (!defined $object || $objValue eq $object->getLabel)
	   ) {			#found statement
	    $count++;
	}
    }
    return $count;
}
sub _getCounter {
    my ($self,$counterName) = @_;
    return $self->{_data}->{'_'.$counterName} = ++$self->{_data}->{'_'.$counterName} || 1;
}
sub _getKey {
    my ($self, $stmt) = @_;


    foreach (@{$self->_getIndexArray($stmt->getSubject, $stmt->getPredicate, $stmt->getObject)}) {
	my ($subURI, $predURI,  $objValue, $index);
	$index = $self->{_data}->{+SUBJECT.$_};
	$subURI = $self->{_data}->{+NAMESPACE.$index}.$self->{_data}->{+VALUE.$index};
	$index = $self->{_data}->{+PREDICATE.$_};
	$predURI = $self->{_data}->{+NAMESPACE.$index}.$self->{_data}->{+VALUE.$index};
	if ($stmt->getObject->isLiteral) {
	    $index  =  $self->{_data}->{+OBJECT_LIT.$_};
	    $objValue = $self->{_data}->{+LITERAL.$index};
	} else {
	    $index  =  $self->{_data}->{+OBJECT_RES.$_};
	    $objValue = $self->{_data}->{+NAMESPACE.$index}.$self->{_data}->{+VALUE.$index};
	}
	if ($subURI eq $stmt->getSubject->getURI && 
	    $predURI eq $stmt->getPredicate->getURI && 
	    $objValue eq $stmt->getObject->getLabel
	   ) {			#found statement
	    return $_;
	}
    }
    return 0;			#didn't find statement
}
sub _getIndexArray {
    #find the smallest index array
    my ($self, $subject, $predicate, $object) = @_;
    my $idxStmt = tied %{$self->{_idxStmt}};
    my @indexArray;
    my $found = 0;
    my $idxLength = 0;
    my $keyBest;

    if (defined $subject) {
	my $subjectID = $self->{_idxRes}->{$subject->getURI} || '';
	$found = 1;
	$idxLength = $self->{_data}->{+SUBJECT_SIZE.$subjectID} || 0;
	$keyBest = SUBJECT_IDX.$subjectID;
    }
    if (defined $predicate) {
	my $predicateID = $self->{_idxRes}->{$predicate->getURI} || '';
	if (!$found || $idxLength > 
	    ($self->{_data}->{+PREDICATE_SIZE.$predicateID} || 0)) {
	    $found = 1;
	    $idxLength = $self->{_data}->{+PREDICATE_SIZE.$predicateID} || 0;
	    $keyBest = PREDICATE_IDX.$predicateID;
	}
    }
    if (defined $object) {
	my $objectID;
	if ($object->isLiteral) {
	    my $value	= $object->getValue;
	    my $lang	= $object->getLang;
	    my $dt		= $object->getDatatype;
	    my $idxLitKey	= sprintf("L%s<%s>%s", $value, $lang, $dt);
	    $objectID = $self->{_idxLit}->{ $idxLitKey } || '';
	    $idxLength = $self->{_data}->{+OBJECTLIT_SIZE.$objectID} || 0;
	    $keyBest = OBJECTLIT_IDX.$objectID;
	} else {
	    $objectID = $self->{_idxRes}->{$object->getURI} || '';
	    $idxLength = $self->{_data}->{+OBJECTRES_SIZE.$objectID} || 0;
	    $keyBest = OBJECTRES_IDX.$objectID;
	}
	$found = 1;
    }
    if ($found) {
	@indexArray = $idxStmt->get_dup($keyBest);
    } else {
	foreach (keys %{$self->{_data}}) {
	    my $prefix = SUBJECT;
	    if (/^$prefix/) {
		push(@indexArray,$');
	    }
	}
    }
    return \@indexArray;
}

sub _synchronize {
    my ($self) = @_;
    my $sync;
    if (my $sync = $self->{_options}->{Sync}) {
	if (++$self->{_steps} > $sync) {
	    $self->{_steps} = 0;
	    foreach (($self->{_data}, $self->{_idxStmt}, $self->{_idxRes}, 
		      $self->{_idxLit})) {
		if (defined) {
		    my $t = tied %$_;
		    next unless $t;
		    $t->sync;
		}
	    }
	}
    }
}



sub DESTROY {
    my $self = shift;
    #untie hashes
    foreach (($self->{_data}, $self->{_idxStmt}, $self->{_idxRes}, 
	      $self->{_idxLit})) {
	if (defined) {
	    my $t = tied %$_;
	    next unless $t;
	    $t->sync;
	    undef $t;
	    untie %$_;
	}
    }
}

1;
__END__

=head1 NAME

RDF::Core::Storage::DB_File - Berkeley DB 1.x implementation of RDF::Core::Storage

=head1 SYNOPSIS

  require RDF::Core::Storage::DB_File;
  my $storage = new RDF::Core::Storage::DB_File(Name =>'./rdfdata',
                                                 MemLimit => 5000,
                                                );
  my $model = new RDF::Core::Model (Storage => $storage);

=head1 DESCRIPTION

The storage is based on DB_File module and is using tie mechanism to access data.

=head2 Interface

=over 4

=item * new(%options)

Available options are:

=over 4

=item * Name

The name of the storage. Several files will be created beginning with the Name.
If Name is undef, storage is held in memory. Default value is null.

=item * Flags, Mode

The options is passed to DB_File module when tying variables. Default values are O_CREAT|O_RDWR for Flags and 0666 for Mode.

=item * MemLimit

When statements are retrieved from the storage, they are passed as an in-memory implementation of enumerator RDF::Core::Enumerator::Memory or less-in-memory implementation RDF::Core::Enumerator::DB_File. Setting MemLimit to non-zero says that storage should never return Memory enumerator for number of statements larger then MemLimit. As the decision of what to return is made before the accurate count of statements returned is known, DB_File enumerator may be returned even if MemLimit is not exceeded.

=item * Sync

A number of write operations to process before synchronizing storage data cache with disk. 0 means don't force synchronizing. 

=back

=back

The rest of the interface is described in RDF::Core::Storage.




=head1 LICENSE

This package is subject to the MPL (or the GPL alternatively).

=head1 AUTHOR

Ginger Alliance, rdf@gingerall.cz

=head1 SEE ALSO

DB_File, RDF::Core::Storage, RDF::Core::Enumerator::Memory, RDF::Core::Enumerator::DB_File, RDF::Core::Model

=cut
