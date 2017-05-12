# $Id: Relationship.pm 2014-11-14 erick.antezana $
#
# Module  : Relationship.pm
# Purpose : Relationship in the Ontology.
# License : Copyright (c) 2006-2015 by Erick Antezana. All rights reserved.
#           This program is free software; you can redistribute it and/or
#           modify it under the same terms as Perl itself.
# Contact : Erick Antezana <erick.antezana -@- gmail.com>
#
package OBO::Core::Relationship;

use Carp;
use strict;
use warnings;

sub new {
        my $class      = shift;
        my $self       = {};
        
        $self->{ID}    = undef; # required, string (1)
        $self->{TYPE}  = undef; # required, string (1)
        
        $self->{HEAD}  = undef; # required, OBO::Core::Term or OBO::Core::RelationshipType or OBO::Core::Term (1: instance_of)     or OBO::Core::Instance or OBO::Util::Datatype (TODO) or OBO::Util::Datatype (TODO: property_value: shoe_size "8" xsd:positiveInteger)
                                #                  ^^                 ^^                            ^^                                       ^^                    ^^                            ^^
                                #                  ||                 ||                            ||                                       ||                    ||                            ||
        $self->{TAIL}  = undef; # required, OBO::Core::Term or OBO::Core::RelationshipType or OBO::Core::Instance (1: instance_of) or OBO::Core::Term     or OBO::Core::Term (TODO)     or OBO::Core::Instance (TODO)
        
        bless ($self, $class);
        return $self;
}

=head2 id

  Usage    - print $relationship->id() or $relationship->id($id)
  Returns  - the relationship ID (string)
  Args     - the relationship ID (string)
  Function - gets/sets an ID
  
=cut

sub id {
	$_[0]->{ID} = $_[1] if ($_[1]);
	return $_[0]->{ID};
}

=head2 type

  Usage    - $relationship->type('is_a') or print $relationship->type()
  Returns  - the type of the relationship (string)
  Args     - the type of the relationship (string)
  Function - gets/sets the type of the relationship
  Remark   - this field corresponds to the relationship type ID (c.f. OBO::Core::RelationshipType::id())
  
=cut

sub type {
	$_[0]->{TYPE} = $_[1] if ($_[1]);
    return $_[0]->{TYPE};
}

=head2 equals

  Usage    - print $relationship->equals($another_relationship)
  Returns  - either 1 (true) or 0 (false)
  Args     - the relationship (OBO::Core::Relationship) to compare with
  Function - tells whether this relationship is equal to the parameter
  
=cut

sub equals  {
	my $result = 0;
	if ($_[1]) {
     	if ($_[1] && eval { $_[1]->isa('OBO::Core::Relationship') }) {
			my $self_id   = $_[0]->{'ID'};
			my $target_id = $_[1]->{'ID'};
			
			croak 'The ID of this relationship is not defined.' if (!defined($self_id));
			croak 'The ID of the target relationship is not defined.' if (!defined($target_id));
			
			$result = ($self_id eq $target_id);
		} else {
			croak "An unrecognized object type (not a OBO::Core::Relationship) was found: '", $_[1], "'";
		}
	}
	return $result;
}

=head2 head

  Usage    - $relationship->head($object) or $relationship->head()
  Returns  - the OBO::Core::Term (object or target) or OBO::Core::RelationshipType (object or target) targeted by this relationship
  Args     - the target term (OBO::Core::Term) or the target relationship type (OBO::Core::RelationshipType)
  Function - gets/sets the term/relationship type attached to the head of the relationship
  
=cut

sub head {
	$_[0]->{HEAD} = $_[1] if ($_[1]);
    return $_[0]->{HEAD};
}

=head2 tail

  Usage    - $relationship->tail($subject) or $relationship->tail()
  Returns  - the OBO::Core::Term (subject or source) or OBO::Core::RelationshipType (subject or source) sourced by this relationship or the OBO::Core::Instance (subject or source)
  Args     - the source term (OBO::Core::Term) or the source relationship type (OBO::Core::RelationshipType) or the source instance (OBO::Core::Instance)
  Function - gets/sets the term/relationship type/instance attached to the tail of the relationship
  
=cut

sub tail {
	$_[0]->{TAIL} = $_[1] if ($_[1]);
    return $_[0]->{TAIL};
}

=head2 link

  Usage    - $relationship->link($tail, $head) or $relationship->link()
  Returns  - the two Terms (OBO::Core::Term) or two RelationshipTypes (OBO::Core::RelationshipType) or an Instance (OBO::Core::Instance) and a Term (OBO::Core::Term) --subject and source-- connected by this relationship
  Args     - the source (tail, OBO::Core::Term/OBO::Core::RelationshipType) and target(head, OBO::Core::Term/OBO::Core::RelationshipType) term/relationship type
  Function - gets/sets the terms/relationship type attached to this relationship
  
=cut

sub link {
	($_[0]->{TAIL}, $_[0]->{HEAD}) = ($_[1], $_[2]) if ($_[1] && $_[2]);
    return ($_[0]->{TAIL}, $_[0]->{HEAD});
}

1;

__END__


=head1 NAME

OBO::Core::Relationship  - A relationship between two terms or two relationships or an instance and a term within an ontology.

A relationship is simply a triplet: tail->type->head or subject->predicate->object

     SUBJECT                 -->         PREDICATE           -->      OBJECT

 OBO::Core::Term             --> OBO::Core::RelationshipType --> OBO::Core::Term
 OBO::Core::RelationshipType --> OBO::Core::RelationshipType --> OBO::Core::RelationshipType
 OBO::Core::Instance         --> OBO::Core::RelationshipType --> OBO::Core::Term
 OBO::Core::Term             --> OBO::Core::RelationshipType --> OBO::Core::Instance
 OBO::Core::Term             --> OBO::Core::RelationshipType --> OBO::Core::Datatype (NOT IMPLEMENTED YET)
 OBO::Core::Instance         --> OBO::Core::RelationshipType --> OBO::Core::Datatype (NOT IMPLEMENTED YET)

=head1 SYNOPSIS

use OBO::Core::Relationship;
use OBO::Core::Term;
use strict;

# three new relationships
my $r1 = OBO::Core::Relationship->new();
my $r2 = OBO::Core::Relationship->new();
my $r3 = OBO::Core::Relationship->new();

$r1->id("APO:P0000001_is_a_APO:P0000002");
$r2->id("APO:P0000002_part_of_APO:P0000003");
$r3->id("APO:P0000001_has_child_APO:P0000003");

$r1->type('is_a');
$r2->type('part_of');
$r3->type('has_child');

!$r1->equals($r2);
!$r2->equals($r3);
!$r3->equals($r1);

# three new terms
my $n1 = OBO::Core::Term->new();
my $n2 = OBO::Core::Term->new();
my $n3 = OBO::Core::Term->new();

$n1->id("APO:P0000001");
$n2->id("APO:P0000002");
$n3->id("APO:P0000003");

$n1->name("One");
$n2->name("Two");
$n3->name("Three");

# r1(n1, n2)
$r1->head($n2);
$r1->tail($n1);

# r2(n2, n3)
$r2->head($n3);
$r2->tail($n2);

# r3(n1, n3)
$r3->head($n3);
$r3->tail($n1);

# three new relationships
my $r4 = OBO::Core::Relationship->new();
my $r5 = OBO::Core::Relationship->new();
my $r6 = OBO::Core::Relationship->new();

$r4->id("APO:R0000004");
$r5->id("APO:R0000005");
$r6->id("APO:R0000006");

$r4->type("r4");
$r5->type("r5");
$r6->type("r6");

$r4->link($n1, $n2);
$r5->link($n2, $n3);
$r6->link($n1, $n3);

=head1 DESCRIPTION

A relationship between:

- two Terms (OBO::Core::Term) or 
- two RelationshipTypes (OBO::Core::RelationshipType) or 
- an Instance (OBO::Core::Instance) and a Term (OBO::Core::Term)

OBO::Core::Term or OBO::Core::RelationshipType or OBO::Core::Term (1)
      ^^                 ^^                            ^^
      ||                 ||                            ||
OBO::Core::Term or OBO::Core::RelationshipType or OBO::Core::Instance (1)

Relationships must have a unique ID (e.g. 'APO:P0000028_is_a_APO:P0000005'), 
a type (e.g. 'is_a') and it must known the linking terms (tail and head).

=head1 AUTHOR

Erick Antezana, E<lt>erick.antezana -@- gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2015 by Erick Antezana. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut