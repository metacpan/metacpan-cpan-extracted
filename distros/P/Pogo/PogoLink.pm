# PogoLink.pm - bidirectional relationship class for Pogo
# 2000 Sey Nakajima <sey@jkc.co.jp>
use Pogo;

# Abstract base class 
package PogoLink;
use Carp;
use strict;
use vars qw(@Fields %Fields);

BEGIN {
	@Fields = qw(OBJECT LINK LINKCLASS INVFIELD KEYFIELD SIZE LINKCLASSISARRAY);
	%Fields = map { $Fields[$_], $_+1 } (0 .. $#Fields);
	sub FIELDHASH { \%Fields }
}

sub new {
	my($class, $object, $linkclass, $invfield, $keyfield, $size) = @_;
	my $type = (Pogo::type_of($object))[0];
	croak "Hash or array object required" 
		unless $type eq 'HASH' || $type eq 'ARRAY';
	my $self = new_tie Pogo::Harray 8, $object, $class;
	$self->{OBJECT}    = $object;
	$self->{LINK}      = undef;
	$self->{LINKCLASS} = $linkclass;
	$self->{INVFIELD}  = $invfield;
	$self->{KEYFIELD}  = $keyfield;
	$self->{SIZE}      = $size;
	$self->{LINKCLASSISARRAY} = $invfield =~ /^\d+$/;
	$self;
}
sub clear {
	my $self = shift;
	my @objects = $self->getlist;
	return unless @objects;
	my $invfield = $self->{INVFIELD};
	Pogo::tied_object($self)->begin_transaction;
	for my $object(@objects) {
		$self->_del($object);
		if( $self->{LINKCLASSISARRAY} ) {
			$object->[$invfield]->_del($self->{OBJECT});
		} else {
			$object->{$invfield}->_del($self->{OBJECT});
		}
	}
	Pogo::tied_object($self)->end_transaction;
}
sub del {
	my($self, $object) = @_;
	return unless $object && ref($object);
	return unless $self->find($object);
	my $invfield = $self->{INVFIELD};
	Pogo::tied_object($self)->begin_transaction;
	$self->_del($object);
	if( $self->{LINKCLASSISARRAY} ) {
		$object->[$invfield]->_del($self->{OBJECT});
	} else {
		$object->{$invfield}->_del($self->{OBJECT});
	}
	Pogo::tied_object($self)->end_transaction;
}
sub add {
	my($self, $object) = @_;
	return unless $object && ref($object);
	my $linkclass = $self->{LINKCLASS};
	croak "Class mismatch" if $linkclass && !$object->isa($linkclass);
	return if $self->find($object);
	my $invfield = $self->{INVFIELD};
	my $type = (Pogo::type_of($object))[0];
	croak "Hash object required" 
		unless $type eq 'HASH' || 
			($type eq 'ARRAY' && (Pogo::type_of($object->[0]))[0] eq 'HASH');
	my $invfieldvalue = $self->{LINKCLASSISARRAY} ? 
			$object->[$invfield] : $object->{$invfield};
	if( !$invfieldvalue && $object->can("INIT_$invfield") ) {
		my $initmethod = "INIT_$invfield";
		no strict 'refs';
		$object->$initmethod();
	}
	$invfieldvalue = $self->{LINKCLASSISARRAY} ? 
			$object->[$invfield] : $object->{$invfield};
	croak "Inverse attribute must be a PogoLink::* object" 
		unless (Pogo::type_of($invfieldvalue))[1] =~ /^PogoLink::/;
	Pogo::tied_object($self)->begin_transaction;
	$self->_add($object);
	$invfieldvalue->_add($self->{OBJECT});
	Pogo::tied_object($self)->end_transaction;
}

package PogoLink::Scalar;
use Carp;
use strict;
use vars qw(@ISA);
@ISA = qw(PogoLink);
sub get {
	my $self = shift;
	$self->{LINK};
}
sub getlist {
	my $self = shift;
	return () unless $self->{LINK};
	($self->{LINK});
}
sub find {
	my($self, $object) = @_;
	Pogo::equal($self->{LINK}, $object);
}
sub _del {
	my($self, $object) = @_;
	$self->{LINK} = undef if Pogo::equal($self->{LINK}, $object);
}
sub _add {
	my($self, $object) = @_;
	my $invfield = $self->{INVFIELD};
	if( $self->{LINK} ) {
		if( $self->{LINKCLASSISARRAY} ) {
			$self->{LINK}->[$invfield]->_del($self->{OBJECT});
		} else {
			$self->{LINK}->{$invfield}->_del($self->{OBJECT});
		}
	}
	$self->{LINK} = $object;
}

package PogoLink::Array;
use Carp;
use strict;
use vars qw(@ISA);
@ISA = qw(PogoLink);
sub get {
	my($self, $idx) = @_;
	return undef unless $self->{LINK};
	defined $idx ? $self->{LINK}->[$idx] : @{$self->{LINK}};
}
sub getlist {
	my $self = shift;
	return () unless $self->{LINK};
	@{$self->{LINK}};
}
sub find {
	my($self, $object) = @_;
	return 0 unless $self->{LINK};
	grep Pogo::equal($_, $object), @{$self->{LINK}};
}
sub _del {
	my($self, $object) = @_;
	return unless $self->{LINK};
	@{$self->{LINK}} = grep !Pogo::equal($_, $object), @{$self->{LINK}};
}
sub _add {
	my($self, $object) = @_;
	unless( $self->find($object) ) {
		$self->{LINK} = new Pogo::Array($self->{SIZE})
			unless $self->{LINK};
		push @{$self->{LINK}}, $object;
	}
}

package PogoLink::Hash;
use Carp;
use strict;
use vars qw(@ISA);
@ISA = qw(PogoLink);
sub get {
	my($self, $key) = @_;
	return undef unless $self->{LINK};
	defined $key ? $self->{LINK}->{$key} : values %{$self->{LINK}};
}
sub getlist {
	my $self = shift;
	return () unless $self->{LINK};
	values %{$self->{LINK}};
}
sub getkeylist {
	my $self = shift;
	return () unless $self->{LINK};
	keys %{$self->{LINK}};
}
sub find {
	my($self, $object) = @_;
	return 0 unless $self->{LINK};
	my $key = $self->{LINKCLASSISARRAY} ? 
		$object->[$self->{KEYFIELD}] : $object->{$self->{KEYFIELD}};
	exists $self->{LINK}->{$key};
}
sub _del {
	my($self, $object) = @_;
	return unless $self->{LINK};
	my $key = $self->{LINKCLASSISARRAY} ? 
		$object->[$self->{KEYFIELD}] : $object->{$self->{KEYFIELD}};
	delete $self->{LINK}->{$key};
}
sub _add {
	my($self, $object) = @_;
	unless( $self->find($object) ) {
		$self->{LINK} = new Pogo::Hash($self->{SIZE})
			unless $self->{LINK};
		my $key = $self->{LINKCLASSISARRAY} ? 
			$object->[$self->{KEYFIELD}] : $object->{$self->{KEYFIELD}};
		$self->{LINK}->{$key} = $object;
	}
}

package PogoLink::Htree;
use Carp;
use strict;
use vars qw(@ISA);
@ISA = qw(PogoLink::Hash);
sub _add {
	my($self, $object) = @_;
	unless( $self->find($object) ) {
		$self->{LINK} = new Pogo::Htree($self->{SIZE})
			unless $self->{LINK};
		my $key = $self->{LINKCLASSISARRAY} ? 
			$object->[$self->{KEYFIELD}] : $object->{$self->{KEYFIELD}};
		$self->{LINK}->{$key} = $object;
	}
}

package PogoLink::Btree;
use Carp;
use strict;
use vars qw(@ISA);
@ISA = qw(PogoLink::Hash);
sub _add {
	my($self, $object) = @_;
	unless( $self->find($object) ) {
		$self->{LINK} = new Pogo::Btree unless $self->{LINK};
		my $key = $self->{LINKCLASSISARRAY} ? 
			$object->[$self->{KEYFIELD}] : $object->{$self->{KEYFIELD}};
		$self->{LINK}->{$key} = $object;
	}
}

package PogoLink::Ntree;
use Carp;
use strict;
use vars qw(@ISA);
@ISA = qw(PogoLink::Hash);
sub _add {
	my($self, $object) = @_;
	unless( $self->find($object) ) {
		$self->{LINK} = new Pogo::Ntree unless $self->{LINK};
		my $key = $self->{LINKCLASSISARRAY} ? 
			$object->[$self->{KEYFIELD}] : $object->{$self->{KEYFIELD}};
		$self->{LINK}->{$key} = $object;
	}
}

1;
__END__

=head1 NAME

PogoLink - Bidirectional relationship class for objects in a Pogo database

=head1 SYNOPSIS

  use PogoLink;
  # Define relationships
  package Person;
  sub new {
      my($class, $name) = @_;
      my $self = new_tie Pogo::Hash 8, undef, $class;
      %$self = (
          NAME     => $name,
          FATHER   => new PogoLink::Scalar($self, 'Man',    'CHILDREN'),
          MOTHER   => new PogoLink::Scalar($self, 'Woman',  'CHILDREN'),
          FRIENDS  => new PogoLink::Btree ($self, 'Person', 'FRIENDS', 'NAME'),
      );
      $self;
  }
  package Man;
  @ISA = qw(Person);
  sub new {
      my($class, $name) = @_;
      my $self = $class->SUPER::new($name);
      $self->{CHILDREN} = new PogoLink::Array ($self, 'Person', 'FATHER');
      $self->{WIFE}     = new PogoLink::Scalar($self, 'Woman',  'HUS');
      $self;
  }
  package Woman;
  @ISA = qw(Person);
  sub new {
      my($class, $name) = @_;
      my $self = $class->SUPER::new($name);
      $self->{CHILDREN} = new PogoLink::Array ($self, 'Person', 'MOTHER');
      $self->{HUS}      = new PogoLink::Scalar($self, 'Man',    'WIFE');
      $self;
  }

  # Use relationships
  $Dad = new Man   'Dad';
  $Mom = new Woman 'Mom';
  $Jr  = new Man   'Jr';
  $Gal = new Woman 'Gal';
  # Marriage 
  $Dad->{WIFE}->add($Mom);     # $Mom->{HUS} links to $Dad automatically
  # Birth
  $Dad->{CHILDREN}->add($Jr);  # $Jr->{FATHER} links to $Dad automatically
  $Mom->{CHILDREN}->add($Jr);  # $Jr->{MOTHER} links to $Mom automatically
  # Jr gets friend
  $Jr->{FRIENDS}->add($Gal);   # $Gal->{FRIENDS} links to $Jr automatically
  # Oops! Gal gets Dad
  $Gal->{HUS}->add($Dad);      # $Dad->{WIFE} links to $Gal automatically
                               # $Mom->{HUS} unlinks to $Dad automatically

=head1 DESCRIPTION

PogoLink makes single-single or single-multi or multi-multi bidirectional 
relationships between objects in a Pogo database. The relationships are 
automatically maintained to link each other correctly. You can choose one 
of Pogo::Array, Pogo::Hash, Pogo::Htree, Pogo::Btree and Pogo::Ntree to make 
a multi end of link.

=over 4

=head2 Classes

=item PogoLink::Scalar

This class makes a single end of link.

=item PogoLink::Array

This class makes a multi end of link as an array. It uses Pogo::Array to 
have links.

=item PogoLink::Hash, PogoLink::Htree, PogoLink::Btree, PogoLink::Ntree

These classes make a multi end of link as a hash. Each uses corresponding 
Pogo::* to have links.

=head2 Methods

=item new PogoLink::* $selfobject, $linkclass, $invfield, $keyfield, $size

Constructor. Class method. $selfobject is a object in the database which 
possesses this link. It must be a object as a hash reference. 
$linkclass is a class name of linked object. If $linkclass defaults, 
any class object is allowed. $invfield is a field (i.e. hash key) name 
of the linked object which links inversely. $keyfield is only necessary for 
PogoLink::Hash, PogoLink::Htree, PogoLink::Btree, PogoLink::Ntree. 
It specifies a field name of the linked object thats value is used as 
the key of this link hash. $size may be specified for PogoLink::Array,
PogoLink::Hash or PogoLink::Htree. $size will be used when internal linking 
Pogo::Array, Pogo::Hash or Pogo::Htree object will be constructed.

NOTE: You cannot use PogoLink::* constructors as follows in a class constructor.

  sub new {
      my($class) = @_;
      my $self = {};
      bless $self, $class;
      $self->{FOO} = new PogoLink::Scalar $self, 'Foo', 'BAR';
      $self;
  }

Because the self-object which is passed to PogoLink::* constructors must be 
tied to a Pogo::* object. In the above sample, $self is a Perl object on the 
memory yet.
The right way is as follows.

  sub new {
      my($class) = @_;
      my $self = new_tie Pogo::Hash 8, undef, $class;
      $self->{FOO} = new PogoLink::Scalar $self, 'Foo', 'BAR';
      $self;
  }

You can make a blessed reference which is tied to specified Pogo::* object by 
using new_tie which takes a class name as arguments.

=item get $idx_or_key

Get the linked object. For PogoLink::Scalar, $idx_or_key is not necessary. For 
PogoLink::Array, $idx_or_key is an array index number. For other, $idx_or_key
is a hash key string.

=item getlist

Get the linked object list.

=item getkeylist

Get the hash key list of linked objects. Only available for PogoLink::Hash, 
PogoLink::Htree, PogoLink::Btree, PogoLink::Ntree. 

=item find $object

Test the link if it links to $object.

=item clear

Unlink to all objects in the link.

=item del $object

Unlink to $object.

=item add $object

Link to $object. The inverse field (it's name was specified as $invfield by 
new()) of $object must be a PogoLink::* object. If the inverse field is not 
defined yet and $object has INIT_fieldname method (e.g. the field name is 
'FIELD', the method name is 'INIT_FIELD'), this method calls 
$object->INIT_fieldname() to initialize the inverse field before linking.

=back

=head1 AUTHOR

Sey Nakajima <nakajima@netstock.co.jp>

=head1 SEE ALSO

Pogo(3). 
sample/person.pl.
