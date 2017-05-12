package MusicRoom::Album;

=head1 NAME

MusicRoom::Album - Manage the albums in a database

=head1 DESCRIPTION

=cut

use strict;
use warnings;
use Carp;

use MusicRoom;
use MusicRoom::STN;
use MusicRoom::ValidAlbums;

# Define some sizes and other things the database needs
use constant ID_LENGTH => 6;
use constant NAME_LENGTH => 30;
use constant PATH_LENGTH => 254;

use constant RESIDENT_PART => "core";
use constant TABLE_NAME => "album";
use constant USER_CLASS => "Album";
use constant PERL_CLASS => "MusicRoom::" . USER_CLASS;

sub name_valid
  {
    my($attrib,$arg,$valid_cat) = @_;

    my $nearest = map_to_valid($arg);
    return 1 if(defined $nearest && $nearest ne "");
    return undef;
  }

sub map_to_valid
  {
    my($val) = @_;

    my $nearest = MusicRoom::ValidAlbums::nearest($val,"Album module");
    return $val if($val eq $nearest);
    if(lc($nearest) eq lc($val))
      {
        return $nearest;
      }
    return undef;
  }

my @attributes =
  (
    id => 
      {
        type => "text",
        length => ID_LENGTH,
        fixed => 1,
      },
    name => 
      {
        type => "text",
        length => NAME_LENGTH,
        required => 1,
        is_valid => \&name_valid,
        is_valid_arg => TABLE_NAME,
        map_with => \&map_to_valid,
        unique => 1,
        fixed => 1,
      },
  );

######################################################################
# From here downwards is the same for all the object classes
# (I am sure there is a better way to share this code but I can't 
#   think what it is at the moment, so I do the simple thing)
#
my(%attributes,@db_fields,@db_specs,%data);

sub perl_class
  {
    reorganise_description();
    return PERL_CLASS;
  }

sub table_name
  {
    reorganise_description();
    return TABLE_NAME;
  }

sub id_spec
  {
    reorganise_description();
    return TABLE_NAME.".id";
  }

sub ref_spec
  {
    # If called like MusicRoom::Track->ref_spec() then ignore the class 
    # name
    shift @_
        if($#_ >= 0 && $_[0] eq PERL_CLASS);
    my($attrib) = @_;

    reorganise_description();
    $attrib = "id" if(!defined $attrib);

    for(my $i=0;$i<=$#attributes;$i+=2)
      {
        return %{$attributes[$i+1]}
                  if($attributes[$i] eq $attrib);
      }
    carp("Cannot find attribute $attrib");
    return undef;
  }

sub table_spec
  {
    reorganise_description();
    return
      (
        # I would like to say:
        #     TABLE_NAME => [id => "text:".(ID_LENGTH+2)...
        # but the fat comma causes the constant not to be expanded
        TABLE_NAME,\@db_specs
      );
  }

sub attribs
  {
    reorganise_description();
    my @attribs;
    for(my $i=0;$i<=$#attributes;$i+=2)
      {
        push @attribs,$attributes[$i];
      }
    return @attribs;
  }

sub reorganise_description
  {
    # Take the description in terms of an ordered list of attributes 
    # and spread the information in various structures to make later 
    # processing easier
    my @ret;

    return if(@db_fields);
    for(my $attrib_num=0;$attrib_num<=$#attributes;$attrib_num+=2)
      {
        my $attrib_name = $attributes[$attrib_num];
        my $attrib_spec = $attributes[$attrib_num+1];

        if(defined $attributes{$attrib_name})
          {
            craok("Duplicate attribute $attrib_name");
          }

        $attributes{$attrib_name} = $attrib_spec;
        my $db_name = $attrib_name;
        $db_name = $attrib_spec->{db_name} 
                               if(defined $attrib_spec->{db_name});
        my $db_spec;
        if(!defined $attrib_spec->{type})
          {
            carp("Must define type for $attrib_name");
          }
        elsif($attrib_spec->{type} eq "text")
          {
            carp("Must specify length on text field $attrib_name")
                              if(!defined $attrib_spec->{length});
            $db_spec = "text:".($attrib_spec->{length} + 2);
          }
        elsif($attrib_spec->{type} eq "boolean")
          {
            $db_spec = "boolean";
          }
        elsif($attrib_spec->{type} eq "enum")
          {
            carp("Must specify valid values for enum $attrib_name")
                              if(!defined $attrib_spec->{options});
            $db_spec = $attrib_spec->{options};
          }
        elsif($attrib_spec->{type} eq "integer")
          {
            $db_spec = "integer";
          }
        else
          {
            carp("Cannot yet translate $attrib_spec->{type} into DB spec");
          }
        push @db_specs,$db_name,$db_spec;
        push @db_fields,$db_name;
      }
  }

sub name2obj
  {
    my($nam) = @_;
    return $nam if(ref($nam) eq PERL_CLASS);

    if(ref($nam))
      {
        carp("lookup name passed non string $nam");
        return undef;
      }

    if(!defined $attributes{name})
      {
        carp(USER_CLASS." objects do not have a name attribute");
        return undef;
      }

    my @ids = select_objects(name => $nam);
    return undef if($#ids < 0);
    return $ids[0] if($#ids == 0);
    carp("Multiple matching object to $nam");
    return $ids[0];
  }

sub id2obj
  {
    my($id) = @_;
    return $id if(ref($id) eq PERL_CLASS);
    if(ref($id))
      {
        carp("lookup id passed non string $id");
        return undef;
      }
    if(!defined $attributes{id})
      {
        carp(USER_CLASS." objects do not have an id");
        return undef;
      }

    my @ids = select_objects(id => $id);
    return undef if($#ids < 0);
    return $ids[0] if($#ids == 0);
    carp("Multiple matching object to $id");
    return $ids[0];
  }

sub select_objects
  {
    # If we are called inirectly then just throw away the class name
    shift @_
        if($#_ >= 0 && $_[0] eq PERL_CLASS);

    my(@where) = @_;

    # Return a list of objects that match a where clause
    my $where;
    if($#where < 0)
      {
        $where = undef;
      }
    elsif($#where == 0)
      {
        $where = $where[0];
      }
    else
      {
        for(my $i=0;$i<=$#where;$i+=2)
          {
            $where .= " AND" if($i != 0);
            $where .= $where[$i]." = ".
                      MusicRoom::quoteSQL(RESIDENT_PART,$where[$i+1]);
          }
      }
    my @ids = MusicRoom::select(RESIDENT_PART,
                                 TABLE_NAME,['id'],$where);
    # Convert the returned ID list into objects
    my @results;
    foreach my $id (@ids)
      {
        # This is just one of those constructs you have to 
        # look up if you don't understand
        push @results,bless \$id->[0],PERL_CLASS;
      }
    return @results;
  }

sub of_type
  {
    my($attrib,$arg,$class) = @_;

    return 1 if(ref($arg) eq $class);
    return undef;
  }

######################################################################
#
# Object support below here
#

sub get
  {
    my $this = shift;
    croak("$this is not an ".USER_CLASS) if(ref($this) ne PERL_CLASS);
    croak("$this is not an ".USER_CLASS) if(length(${$this}) != ID_LENGTH);
    my(@attribs) = @_;

    reorganise_description();

    if($#attribs < 0)
      {
        carp("Must pass at least one attribute to get()");
        return undef;
      }

    foreach my $attrib (@attribs)
      {
        if(!defined $attributes{$attrib})
          {
            carp("No such attribute ($attrib)");
            return undef;
          }
      }

    my @result = MusicRoom::select(RESIDENT_PART,
                                 TABLE_NAME,\@attribs,
                                 "id=".MusicRoom::quoteSQL(RESIDENT_PART,$$this));
    if($#result != 0)
      {
        # Should only have a single row returned
        carp("Attempt to extract single row from ".TABLE_NAME.
                   "(with id=$$this) returned ".($#result+1)." rows");
        return undef;
      }
    # If we have a set of attributes we are after leave them packed into 
    # the array, if we want just one attribute then unpick it from 
    # the container
    return @{$result[0]} if($#attribs > 0);
    return $result[0]->[0];
  }

sub set
  {
    my $this = shift;
    croak("$this is not an ".USER_CLASS) if(ref($this) ne PERL_CLASS);
    croak("$this is not an ".USER_CLASS) if(length(${$this}) != ID_LENGTH);
    my(%values) = @_;

    reorganise_description();

    my $stmt = "UPDATE ".TABLE_NAME." SET ";
    my $first_loop = 1;

    foreach my $attrib (keys %values)
      {
        if(!defined $attributes{$attrib})
          {
            carp("No such attribute ($attrib)");
            next;
          }

        if(defined $attributes{$attrib}->{fixed})
          {
            carp("Cannot modify attribute $attrib");
            return "";
          }

        my $val = $values{$attrib};

        if(!_is_valid_to_assign($attrib,\$val))
          {
            next;
          }

        $stmt .= ", " if(!$first_loop);
        $first_loop = "";
        $stmt .= "$attrib = ".
                      MusicRoom::quoteSQL(RESIDENT_PART,$val);
      }

    return if($first_loop);
    MusicRoom::doSQL(RESIDENT_PART,$stmt);
  }

sub _is_valid_to_assign
  {
    my($attrib,$val_ref) = @_;

    if(!defined ${$val_ref})
      {
        carp("Cannot assign $attrib with undef");
        return "";
      }

    my $original_value = ${$val_ref};

    if(defined $attributes{$attrib}->{map_with})
      {
        ${$val_ref} = &{$attributes{$attrib}->{map_with}}(${$val_ref});
      }

    if(!defined ${$val_ref})
      {
        carp("$attrib \"$original_value\" is not valid");
        return $original_value;
      }

    if(defined $attributes{$attrib}->{is_valid})
      {
        if(!&{$attributes{$attrib}->{is_valid}}($attrib,${$val_ref},
                  $attributes{$attrib}->{is_valid_arg}))
          {
            carp("Invalid assignment to $attrib");
            return "";
          }
      }

    if($attributes{$attrib}->{type} eq "enum")
      {
        # Check that the value is valid
      }
    elsif($attributes{$attrib}->{type} eq "boolean")
      {
        # Check that the value is valid
        if(${$val_ref} eq "true" || ${$val_ref} eq "false")
          {
            # These values are OK
          }
        elsif(lc(${$val_ref}) eq "true" || lc(${$val_ref}) eq "false")
          {
            carp("boolean values are lower case");
            ${$val_ref} = lc(${$val_ref});
          }
        elsif(${$val_ref})
          {
            carp("boolean values should be defined (as \"true\" or \"false\")");
            ${$val_ref} = "true";
          }
        else
          {
            carp("boolean values should be defined (as \"true\" or \"false\")");
            ${$val_ref} = "false";
          }
      }
    elsif($attributes{$attrib}->{type} eq "integer")
      {
        # Check that the value is valid
        if(${$val_ref} =~ /^\d+$/)
          {
            # Valid value
          }
        else
          {
            carp("Interger $attrib cannot be set to \"${$val_ref}\"");
            ${$val_ref} = int(${$val_ref});
          }
      }
    return 1;
  }

sub AUTOLOAD
  {
    # Almost straight from the camel
    my $this = shift;
    croak("$this is not an ".USER_CLASS) if(ref($this) ne PERL_CLASS);
    croak("$this is not an ".USER_CLASS) if(length(${$this}) != ID_LENGTH);

    reorganise_description();

    my $name;

    # Turn off strict for a very limited length of time
      {
        no strict;
        $name = $AUTOLOAD;
      }

    $name = $1 if($name =~ /:+([^:]+)$/);

    if(!exists $attributes{$name})
      {
        carp("Attribute $name is not defined");
        return undef;
      }

    if(@_)
      {
        # We want to set an attribute, we have to write it 
        # through to the database
        my $val = shift @_;
        
        return $val if($val eq $this->{$name});
        return $this->set($name => $val);
      }
    return $this->get($name);
  }

sub new
  {
    my $class = shift;

    reorganise_description();

    my %this;
    # The required attributes must come first (in the correct order)
    # then we have optional params defined as pairs
    for(my $i=0;$i<=$#{attributes};$i+=2)
      {
        if($attributes[$i+1]->{required})
          {
            my $val = shift;

            next if(!_is_valid_to_assign($attributes[$i],\$val));
            $this{$attributes[$i]} = $val;
          }
      }

    # Now lets see which ones we have set by the caller as options
    for(my $i=0;$i<=$#_;$i+=2)
      {
        if(defined $attributes{$_[$i]})
          {
            my $val = $_[$i+1];
            next if(!_is_valid_to_assign($attributes[$i],\$val));
            $this{$_[$i]} = $val;
          }
        else
          {
            carp("Unknown attribute $_[$i]");
          }
      }

    if(defined $this{id})
      {
        # Check that this ID is unique
        my @result = MusicRoom::select(RESIDENT_PART,
                                 TABLE_NAME,['id'],
                                 "id=".MusicRoom::quoteSQL(RESIDENT_PART,$this{id}));
        if($#result >= 0)
          {
            carp("ID $this{id} is not unique");
            delete $this{id};
          }
      }

    while(!defined $this{id})
      {
        # Set the ID
        $this{id} = MusicRoom::STN::unique(undef,ID_LENGTH);
        my @result = MusicRoom::select(RESIDENT_PART,
                                 TABLE_NAME,['id'],
                                 "id=".MusicRoom::quoteSQL(RESIDENT_PART,$this{id}));
        if($#result >= 0)
          {
            delete $this{id};
          }
      }

    # Now do we have any default values we want to add in?
    for(my $i=0;$i<=$#{attributes};$i+=2)
      {
        next if(defined $this{$attributes[$i]});
        if(defined $attributes[$i+1]->{default_value})
          {
            my $val = $attributes[$i+1]->{default_value};
            if(!_is_valid_to_assign($attributes[$i],\$val))
              {
                carp("The default value for $attributes[$i] is invalid!!");
                return undef;
              }
            $this{$attributes[$i]} = $val;
          }
      }

    my @values;

    # There is a bug here, if anyone ever has a different 
    # db_column name from the attribute name this will need
    # fixing
    foreach my $attrib (@db_fields)
      {
        if(!defined $this{$attrib})
          {
            my $val = "";
            if(!_is_valid_to_assign($attrib,\$val))
              {
                carp("The empty value is invalid for $attrib (assign a default)");
                return undef;
              }
            $this{$attrib} = $val;
          }
        push @values,$this{$attrib};
      }

    my $existing_id = matching_item(%this);
    return $existing_id if(defined $existing_id);

    my $success = MusicRoom::insert(RESIDENT_PART,TABLE_NAME,
                                    \@db_fields,\@values);
    if(!defined $success || $success eq "-1")
      {
        carp("Failed to INSERT into ".TABLE_NAME);
        return undef;
      }
    my $id = $this{id};
    return bless \$id,$class;
  }

sub matching_item
  {
    # Find an existing item that matches the spec we have just been given
    my(%spec) = @_;

    my %where_clause;
    foreach my $attrib (@db_fields)
      {
        if(defined $attributes{$attrib}->{unique} &&
                                               $attributes{$attrib}->{unique})
          {
            if(!defined $spec{$attrib})
              {
                carp("Spec passed to matching_item is missing \"$attrib\"");
                next;
              }
            my @ids = MusicRoom::select(RESIDENT_PART,
                                 TABLE_NAME,['id'],
                                 "${attrib}=".MusicRoom::quoteSQL(RESIDENT_PART,
                                                           $spec{$attrib}));
            carp("Multiple rows returned on unique ${attrib}")
                              if($#ids > 0);
            if($#ids >= 0)
              {
                my $id = $ids[0]->[0];
                return bless \$id,PERL_CLASS;
              }
          }
      }
    return undef;
  }

sub DESTROY
  {
  }

1;


