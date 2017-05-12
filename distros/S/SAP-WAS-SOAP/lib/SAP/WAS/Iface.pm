package SAP::WAS::Iface;

use strict;
use vars qw($VERSION $AUTOLOAD);


# Globals

# Valid parameters
my $VALID = {
   NAME => 1,
   PARAMETERS => 1,
   TABLES => 1,
   EXCEPTIONS => 1
};

$VERSION = '0.02';

# empty destroy method to stop capture by autoload
sub DESTROY {
}

sub AUTOLOAD {

  my $self = shift;
  my @parms = @_;
  my $type = ref($self)
          or die "$self is not an Object in autoload of Iface";
  my $name = $AUTOLOAD;
  $name =~ s/.*://;

# Autoload parameters and tables
  if ( exists $self->{PARAMETERS}->{uc($name)} ) {
      &Parm($self, $name);
  } elsif ( exists $self->{TABLES}->{uc($name)} ) {
      &Tab($self, $name);
  } else {
      die "Parameter $name does not exist in Interface - no autoload";
  };
}


# Construct a new SAP::Interface object
sub new {

  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self = {
  	PARAMETERS => {},
  	TABLES => {},
  	EXCEPTIONS => {},
	@_
  };
  die "No RFC Name supplied to Interface !" if ! exists $self->{NAME};

# Validate parameters
  map { delete $self->{$_} if ! exists $VALID->{$_} } keys %{$self};
  $self->{NAME} = $self->{NAME};

# create the object and return it
  bless ($self, $class);
  return $self;
}


# get the name
sub name {

  my $self = shift;
  return $self->{NAME};

}


# Add an export parameter Object
sub addParm {

  my $self = shift;
  die "No parameter supplied to Interface !" if ! @_;
  my $parm;
  if (my $ref = ref($_[0])){
      die "This is not an Parameter for the Interface - $ref ! "
	  if $ref ne "SAP::WAS::Parms";
      $parm = $_[0];
  } else {
      $parm = SAP::WAS::Parms->new( @_ );
  };

  return $self->{PARAMETERS}->{$parm->name()} = $parm;

}


# Access the export parameters
sub Parm {

  my $self = shift;
  die "No parameter name supplied for interface" if ! @_;
  my $parm = uc(shift);
  die "Export $parm Does not exist in interface !"
           if ! exists $self->{PARAMETERS}->{$parm};
  return $self->{PARAMETERS}->{$parm};

}


# Return the parameter list
sub Parms {

  my $self = shift;
  return sort { $a->name() cmp $b->name() } values %{$self->{PARAMETERS}};

}


# Add an Table Object
sub addTab {

  my $self = shift;
  die "No Table supplied for interface !" if ! @_;
  my $table;
  if ( my $ref = ref($_[0]) ){
      die "This is not a Table for interface: $ref ! "
	  if $ref ne "SAP::WAS::Tab";
      $table = $_[0];
  } else {
      $table = SAP::WAS::Tab->new( @_ );
  };
  return $self->{TABLES}->{$table->name()} = $table;

}


# Access the Tables
sub Tab {

  my $self = shift;
  die "No Table name supplied for interface" if ! @_;
  my $table = uc(shift);
  die "Table $table Does not exist in interface  !"
     if ! exists $self->{TABLES}->{ $table };
  return $self->{TABLES}->{ $table };

}


# Return the Table list
sub Tabs {

  my $self = shift;
  return sort { $a->name() cmp $b->name() } values %{$self->{TABLES}};

}


# Empty The contents of all tables in an interface
sub emptyTables {

  my $self = shift;
  map {
      my $table = $self->{TABLES}->{ $_ };
      $table->empty();
  } keys %{$self->{TABLES}};

}


=head1 NAME

SAP::WAS::Iface - Perl extension for parsing and creating an Interface Object.  The interface object would then be passed to the SAP::WAS::SOAP object to carry out the actual call, and return of values.

=head1 SYNOPSIS

  use SAP::WAS::Iface;
  $iface = new SAP::WAS::Iface( NAME =>"SAPWAS:ServiceName" );

  NAME is mandatory.

=head1 DESCRIPTION

This class is used to construct a valid interface object ( SAP::WAS::Iface.pm ).
The constructor requires the parameter value pairs to be passed as 
hash key values ( see SYNOPSIS ). 
Generally you would not create one of these manually as it is far easier to use the "discovery" functionality of the SAP::WAS::SOAP->Iface() method.  Tis takes the name of an existing WAS service, and returns a fully formed interface object.

Methods:
new
  use SAP::WAS::Iface;
  $iface = new SAP::WAS::Iface( NAME =>"SAPWAS:ServiceName" );

Create a new Interface object.


=head1 Exported constants

  NONE

=cut

package SAP::WAS::Tab;

use strict;
use vars qw($VERSION);

# Globals

# Valid parameters
my $VALID = {
   DATA => 1,
   NAME => 1,
   STRUCTURE => 1
};

# Construct a new SAP::WAS::Table object.
sub new {

  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self = {
     DATA => [],
     TYPE => "chars",
     @_
  };

  die "Table Name not supplied !" if ! exists $self->{NAME};
  die "Table Structure not supplied !" if ! exists $self->{STRUCTURE};

# Validate parameters
  map { delete $self->{$_} if ! exists $VALID->{$_} } keys %{$self};
  $self->{NAME} = uc($self->{NAME});

# create the object and return it
  bless ($self, $class);
  return $self;

}


# Set/get the table rows - pass a reference to a anon array
sub rows {

  my $self = shift;
  $self->{DATA} = shift if @_;
  return @{$self->{DATA}};

}


# Return the next available row from a table
sub nextrow {

  my $self = shift;
  my $row = shift  @{$self->{DATA}};

  return { map {$self->structure->Fieldname( $_ ) => $row->[$_ - 1] }
  ( 1 .. scalar @{[$self->structure->Fields]} ) } if $row;

}


# Set/get the structure parameter
sub structure {

  my $self = shift;
  $self->{STRUCTURE} = shift if @_;
  return $self->{STRUCTURE};

}


# add a row
sub addrow {

  my $self = shift;
  push(@{$self->{DATA}}, @_) if @_;

}


# Delete all rows in the table
sub empty {

  my $self = shift;
  $self->{DATA} = [ ];
  return @{$self->{DATA}};

}

# Get the table name
sub name {

  my $self = shift;
  return  $self->{NAME};

}


# Get the number of rows
sub rowcount {

  my $self = shift;
  return  $#{$self->{DATA}} + 1;

}



# Autoload methods go after =cut, and are processed by the autosplit program.


=head1 NAME

SAP::WAS::Tab - Perl extension for parsing and creating Tables to be added to an RFC Iface.

=head1 SYNOPSIS

  use SAP::WAS::Tab;
  $tab1 = new SAP::WAS::Tab( NAME => XYZ, VALUE => abc );

=head1 DESCRIPTION

This class is used to construct a valid Table object to be add to an interface
object ( SAP::WAS::Iface.pm ).
The constructor requires the parameter value pairs to be passed as 
hash key values ( see SYNOPSIS ).

Methods:
new
  use SAP::WAS::Tab;
  $tab1 = new SAP::WAS::Tab( NAME => XYZ, ROWLENGTH => 1,
             DATA => [a, b, c, ..] );

rows
  @r = $tab1->rows( [ row1, row2, row3 .... ] );
  optionally set and Give the current rows of a table.

rowcount
  $c = $tab1->rowcount();
  return the current number of rows in a table object.


=head1 Exported constants

  NONE

=cut

package SAP::WAS::Parms;

use strict;
use vars qw($VERSION);

# Globals

# Valid parameters
my $VALID = {
   NAME => 1,
   PHASE => 1,
   STRUCTURE => 1,
   TYPE => 1,
   VALUE => 1
};

# Valid data types
my $VALTYPE = {
   chars => 1,
   date => 1,
   time  => 1,
   int => 1,
   decimal => 1,
   num => 1,
   float => 1
};

# Construct a new SAP::Parms parameter object.
sub new {

  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self = {
     TYPE => "chars",
     VALUE => undef,
     PHASE => 'I',
     @_
  };

  die "Parameter Name not supplied !" if ! exists $self->{NAME};
  die "Parameter Type not valid $self->{TYPE} !" 
     if ! exists $VALTYPE->{$self->{TYPE}};

# Validate parameters
  map { delete $self->{$_} if ! exists $VALID->{$_} } keys %{$self};
  $self->{NAME} = uc($self->{NAME});

# create the object and return it
  bless ($self, $class);
  return $self;
}


# Set/get the value of phase
sub phase {

  my $self = shift;
  $self->{PHASE} = shift if @_;
  return $self->{PHASE};

}


# Set/get the value of type
sub type {

  my $self = shift;
  $self->{TYPE} = shift if @_;
  die "Parameter Type not valid $self->{TYPE} !"
     if ! exists $VALTYPE->{$self->{TYPE}};
  return $self->{TYPE};

}


# Set/get the parameter value
sub value {

  my $self = shift;
  $self->{VALUE} = shift if @_;
  if ($self->{VALUE}){
      return $self->{VALUE};
  } else {
      return "";
  };

}


# Set/get the parameter structure
sub structure {

  my $self = shift;
  $self->{STRUCTURE} = shift if @_;
  return $self->{STRUCTURE};

}


# get the name
sub name {

  my $self = shift;
  return $self->{NAME};

}



# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

SAP::WAS::Parms - Perl extension for parsing and creating an SAP parameter to be added to an RFC Interface.

=head1 SYNOPSIS

  use SAP::WAS::Parms;
  $imp1 = new SAP::WAS::Parms( NAME => XYZ,
             TYPE => chars, VALUE => abc );

=head1 DESCRIPTION

This class is used to construct a valid parameter to add to an interface
object ( SAP::WAS::Iface.pm ).
The constructor requires the parameter value pairs to be passed as 
hash key values ( see SYNOPSIS ).

Methods:
new
  use SAP::WAS::Parms;
  $imp1 = new SAP::WAS::Parms( NAME => XYZ,
      TYPE => chars, VALUE => abc );

value
  $v = $imp1->value( [ val ] );
  optionally set and Give the current value.

type
  $t = $imp1->type( [ type ] );
  optionally set and Give the current value of type.

=head1 Exported constants

  NONE

=cut


package SAP::WAS::Struc;

use strict;
use vars qw($VERSION $AUTOLOAD);

#  require AutoLoader;

# Globals

# Valid parameters
my $VALID = {
   NAME => 1,
   FIELDS => 1
};

# Valid Field parameters
my $FIELDVALID = {
   NAME => 1,
   TYPE => 1,
   POSITION => 1,
   VALUE => 1
};


# Valid data types
my $VALTYPE = {
   chars => 1,
   num => 1,
   int => 1,
   date => 1,
   time => 1,
   decimal => 1,
   float => 1
};

# empty destroy method to stop capture by autoload
sub DESTROY {
}

sub AUTOLOAD {

  my $self = shift;
  my @parms = @_;
  my $type = ref($self)
          or die "$self is not an Object in autoload of Structure";
  my $name = $AUTOLOAD;
  $name =~ s/.*://;
  unless ( exists $self->{FIELDS}->{uc($name)} ) {
      die "Field $name does not exist in structure - no autoload";
  };
  &Fieldvalue($self,$name,@parms);
}

# Construct a new SAP::WAS::Struct parameter object.
sub new {

  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self = {
     FIELDS => {},
     @_
  };

  die "Structure Name not supplied !" if ! exists $self->{NAME};
  $self->{NAME} = uc($self->{NAME});

# Validate parameters
  map { delete $self->{$_} if ! exists $VALID->{$_} } keys %{$self};

# create the object and return it
  bless ($self, $class);
  return $self;

}


# Set/get structure field
sub addField {

  my $self = shift;

  my %field = @_;
  map { delete $field{$_} if ! exists $FIELDVALID->{$_} } keys %field;
  die "Structure NAME not supplied!" if ! exists $field{NAME};
  $field{NAME} = uc($field{NAME});
  $field{NAME} =~ s/ //g;
  die "Structure NAME allready exists - $field{NAME}!" 
     if exists $self->{FIELDS}->{$field{NAME}};
  $field{TYPE} =~ s/ //g;

  die "Structure TYPE not supplied!" if ! exists $field{TYPE};
  die "Structure Type not valid $field{TYPE} !" 
     if ! exists $VALTYPE->{$field{TYPE}};
  $field{POSITION} = ( scalar keys %{$self->{FIELDS}} ) + 1;

  return $self->{FIELDS}->{$field{NAME}} = 
                    { map { $_ => $field{$_} } keys %field };

}


# Delete a field from the structure
sub deleteField {

  my $self = shift;
  my $field = shift;
  die "Structure field does not exist: $field "
     if ! exists $self->{FIELDS}->{uc($field)};
  delete $self->{FIELDS}->{uc($field)};
  return $field;

}


# Set/get the field value and update the overall structure value
sub Fieldvalue {

  my $self = shift;
  my $field = shift;
  $field = ($self->Fields)[$field] if $field =~ /^\d+$/;
  die "Structure field does not exist: $field "
     if ! exists $self->{FIELDS}->{uc($field)};
  $field = $self->{FIELDS}->{uc($field)};
  if (scalar @_ > 0){
    $field->{VALUE} = shift @_;
  } 

  return $field->{VALUE};

}


# get the field name by position
sub Fieldname {

  my $self = shift;
  my $field = shift;
#  print "Number: $field \n";
  die "Structure field does not exist by array position: $field "
     if ! ($self->Fields)[$field - 1];
  return ($self->Fields)[$field - 1 ];

}


# get the name
sub Name {

  my $self = shift;
  return $self->{NAME};

}


# return the current set of field names
sub Fields {

  my $self = shift;
  return  sort { $self->{FIELDS}->{$a}->{POSITION} cmp
		  $self->{FIELDS}->{$b}->{POSITION} }
		  keys %{$self->{FIELDS}};

}


=head1 NAME

SAP::WAS::Struc - Perl extension for parsing and creating a Structure definition.   The resulting structure object is then used for SAP::WAS::Parms, and SAP::WAS::Tab objects to manipulate complex data elements.

=head1 SYNOPSIS

  use SAP::WAS::Struc;
  $struct = new SAP::WAS::Struc( NAME => XYZ, FIELDS => [......] );

=head1 DESCRIPTION

This class is used to construct a valid structure object - a structure object that would be used in an Export(Parms), Import(Parms), and Table(Tab) object ( SAP::WAS::Iface.pm ).
The constructor requires the parameter value pairs to be passed as 
hash key values ( see SYNOPSIS ).  The value of each field can either be accessed through $str->Fieldvalue(field1), or through the autoloaded method of the field name eg. $str->field1().  

Methods:
new
  use SAP::WAS::Struc;
  $str = new SAP::WAS::Struc( NAME => XYZ );


addField
  use SAP::WAS::Struc;
  $str = new SAP::WAS::Struc( NAME => XYZ );
  $str->addField( NAME => field1,
                  TYPE => chars );
  add a new field into the structure object.  The field is given a position counter of the number of the previous number of fields + 1.  Name is mandatory, but type will be defaulted to chars if omitted.


deleteField
  use SAP::WAS::Struc;
  $str = new SAP::WAS::Struc( NAME => XYZ );
  $str->addField( NAME => field1,
                  TYPE => chars );
  $str->deleteField('field1');
  Allow fields to be deleted from a structure.


Name
  $name = $str->Name();
  Get the name of the structure.


Fieldtype
  $ftype = $str->Fieldtype(field1, [ new field type ]);
  Set/Get the SAP WAS field type of a component field of the structure.  This will force the overall value of the structure to be recalculated.


Fieldvalue
  $fvalue = $str->Fieldvalue(field1,
                          [new component value]);
  Set/Get the value of a component field of the structure.  This will force the overall value of the structure to be recalculated.


Field
  $fhashref = $str->Field(field1);
  Set/Get the value of a component field of the structure.  This will force the overall value of the structure to be recalculated.


Fields
  @f = &$struct->Fields();
  Return an array of the fields of a structure sorted in positional order.


=head1 Exported constants

  NONE


=head1 AUTHOR

Piers Harding, saprfc@kogut.demon.co.uk.

But Credit must go to all those that have helped.

=head1 SEE ALSO

perl(1), SAP::WAS::SOAP(3), SAP::WAS::Iface(3)

=cut


1;

__END__
