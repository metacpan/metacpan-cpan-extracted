require 5.006_001;
BEGIN {
  $Orignal::VERSION = "0.04";
}
package Orignal;
use Carp();
use Exporter ();
BEGIN {
  @ISA = qw(Exporter);
  @EXPORT    = ();
  @EXPORT_OK = qw(%Orignal);
}
use strict;
use warnings;
sub attributes {
    my $class = shift;
    
  
    # Make sure it is not called out of a 'modual' context;
    Carp::croak("ERROR: Orignal::$class->attributes, Somehow you managed to call this outside a modual!") if (ref($class));
    my $self = {};
    bless( $self, ( ref($class) || $class ) );
    my ($attributes) = @_;
   # Check $attributes
   ref($attributes) eq 'HASH' || Carp::croak("ERROR: Orignal::$class->attributes, argument must be a 'HASH' reference.");
   if (!exists($attributes->{SCALARS}) and
       !exists($attributes->{HASHES}) and
       !exists($attributes->{ARRAYS}) and
       !exists($attributes->{ORDERED_HASHES})){
      Carp::croak("ERROR: Orignal::$class->attributes, argument 'HASH' reference must has at least one key of 'SCALARS','HASHES' or 'ARRAYS'.");
   }
   if ( exists($attributes->{SCALARS}) and ref($attributes->{SCALARS}) ne 'ARRAY') {
      Carp::croak("ERROR: Orignal::$class->attributes 'SCALARS', must be an 'ARRAY' reference.");
   }
   if ( exists($attributes->{HASHES}) and ref($attributes->{HASHES}) ne 'ARRAY') {
      Carp::croak("ERROR: Orignal::$class->attributes 'HASHES', must be an 'ARRAY' reference.");
   }
   if ( exists($attributes->{ORDERED_HASHES}) and ref($attributes->{ORDERED_HASHES}) ne 'ARRAY') {
      Carp::croak("ERROR: Orignal::$class->attributes 'ORDERED_HASHES', must be an 'ARRAY' reference.");
   }
   if ( exists($attributes->{ARRAYS}) and ref($attributes->{ARRAYS}) ne 'ARRAY') {
      Carp::croak("ERROR: Orignal::$class->attributes 'ARRAYS', must be an 'ARRAY' reference.");
   }
   
   $self->_install_perlish($class,$attributes);
   return;
}
sub new {
    my $class = shift;
    my $self = {};
    bless( $self, ( ref($class) || $class ) );
    $self->_initialize(@_);
    return( $self );
}
sub _attr_to_string {
   my $self = shift;
   my ($attributes) = @_;
   my $return;
   foreach my $type (keys(%{$attributes})) {
      $return.= $type."=>[";
      foreach my $attr (@{$attributes->{$type}}){
           $return.="'$attr',";
      }
      $return.='],';
   }
   return $return;
}
sub _install_perlish {
   my $self = shift;
   my ($imp_class,$attributes) = @_;
   
   # set the my_attributes first;
   
   if (!$self->can('my_attributes')){
     my $attributes_method= "$imp_class\::my_attributes";
     my $attributes_code = "sub {
	  return {".$self->_attr_to_string($attributes)."};
	};";
     {
       no strict qw(refs);
       my $attributes_ref = eval qq{ #line 1 "$imp_class $attributes_method "\n$attributes_code};
       *$attributes_method = $attributes_ref;
     }
   }
    #do the scalars next
   my %fields;
   foreach my $field (@{$attributes->{SCALARS}}) {
      $fields{$field} = 'SCALARS';
      my $set_method= "$imp_class\::$field";
      my $set_code = "sub {
	  my \$self = shift;
	  if (\@_) {
	    \$self->validate_$field(\@_)
	        if \$self->can('validate_$field');
 	    \$self->{$field} = shift;
	    return 1;
	  }
	  return \$self->{$field};
	};";
     {
       no strict qw(refs);
       my $set_code_ref   = eval qq{#line 1 "$imp_class $set_method "\n$set_code};
       *$set_method 	   = $set_code_ref;
     }
   }
   if (exists($attributes->{HASHES})) {
      $self->_install_hashes($imp_class,$attributes->{HASHES},\%fields);
   }
   if (exists($attributes->{ORDERED_HASHES})) {
      $self->_install_ordered_hashes($imp_class,$attributes->{ORDERED_HASHES},\%fields);
   }
   if (exists($attributes->{ARRAYS})) {
      $self->_install_arrays($imp_class,$attributes->{ARRAYS},\%fields);
   }
   $self->{attributes} = $attributes;
   return;
 }
 sub _install_hashes {
   #do the hashes next
   my $self = shift;
   my ($imp_class,$attributes,$fields) = @_;
   foreach my $field (@{$attributes}) {
     if ($fields->{$field}){
        Carp::croak("ERROR: Orignal::$imp_class->attributes, argument 'HASHES' field '$field' is also a SCALARS field!");
     }
     $fields->{$field}  = 'HASHES';
     my $set_get_method = "$imp_class\::$field";
     my $delete_method  = "$imp_class\::delete_$field";
     my $keys_method    = "$imp_class\::keys_$field";
     my $values_method  = "$imp_class\::values_$field";
     my $exists_method  = "$imp_class\::exists_$field";
     my $set_get_code = "sub {
			my \$self = shift;
			my (\$index) = \@_;
			unless (\$index) {
			   if (\$self->{$field}{HASH}){
 			     return(wantarray ? \%{\$self->{$field}{HASH}}:scalar(\%{\$self->{$field}{HASH}}));
 			   }
 			   
			}
			if (ref(\$index) eq 'HASH') {
			   unless (scalar(\%{\$index})){
			      \$self->{$field}{HASH}={};
		           }
		           else {
			      \$self->validate_$field(\$index)
			          if \$self->can('validate_$field');
		              if (\$self->{$field}{HASH}){
		                \$self->{$field}{HASH}={\%{\$self->{$field}{HASH}},\%{\$index}};
			      }
			      else {
                                \$self->{$field}{HASH}=	\$index;
			      }
			   }
			   return(wantarray ? \%{\$self->{$field}{HASH}}:scalar(\%{\$self->{$field}{HASH}}));
			}
			if (scalar(\@_)){
			   my \%ret=();
			   foreach my \$key (\@_){
			      last if(!\$key);
			      next if (!exists(\$self->{$field}{HASH}{\$key} ) );
			      \$ret{\$key} = \$self->{$field}{HASH}{\$key};
			   }
			   return(wantarray ? \%ret : scalar(\%ret));
 			}
		     };";
     my $keys_code = "sub {
			my \$self = shift;
			return(wantarray ? keys(\%{\$self->{$field}{HASH}}):scalar(keys(\%{\$self->{$field}{HASH}})));
		     };";
     my $values_code = "sub {
			my \$self = shift;
			return(wantarray ? values(\%{\$self->{$field}{HASH}}):scalar(values(\%{\$self->{$field}{HASH}})));
		     };";
     my $delete_code = "sub {
			my \$self = shift;
			my \@ret_val =();
			foreach my \$val (\@_) {
			   next if (!exists( \$self->{$field}{HASH}{\$val}));
			   push(\@ret_val,\$self->{$field}{HASH}{\$val});
                           delete(\$self->{$field}{HASH}{\$val});
                        }
                        return wantarray ? \@ret_val : pop(\@ret_val);
                      };";
     my $exists_code = "sub {
			my \$self = shift;
			my \$count = 0;
			foreach my \$val (\@_) {
			   \$count += exists( \$self->{$field}{HASH}{\$val});
			}
			return(\$count);
		      };";
      {
	 no strict qw(refs);
	 my $set_get_code_ref = eval qq{#line 1  "$imp_class $set_get_method "\n$set_get_code};
	 my $delete_code_ref  = eval qq{#line 1  "$imp_class $delete_method "\n$delete_code};
	 my $keys_code_ref    = eval qq{#line 1  "$imp_class $keys_method "\n$keys_code};
         my $values_code_ref  = eval qq{#line 1  "$imp_class $values_method "\n$values_code};
         my $exists_code_ref  = eval qq{#line 1  "$imp_class $exists_method "\n$exists_code};
         *$exists_method  = $exists_code_ref;
	 *$set_get_method = $set_get_code_ref;
	 *$delete_method  = $delete_code_ref;
	 *$keys_method    = $keys_code_ref;
	 *$values_method  = $values_code_ref;
      }
    }
}
sub _install_ordered_hashes {
   #do the hashes next
   my $self = shift;
   my ($imp_class,$attributes,$fields) = @_;
   foreach my $field (@{$attributes}) {
     if ($fields->{$field}){
        Carp::croak("ERROR: Orignal::$imp_class->attributes, argument 'ORDERED_HASHES' field '$field' is also a $fields->{$field} field!");
     }
     $fields->{$field}  = 'ORDERED_HASHES';
     my $set_get_method = "$imp_class\::$field";
     my $delete_method  = "$imp_class\::delete_$field";
     my $keys_method    = "$imp_class\::keys_$field";
     my $values_method  = "$imp_class\::values_$field";
     my $exists_method  = "$imp_class\::exists_$field";
     my $set_get_code = "sub {
			my \$self    = shift;
			my (\$index) = \@_;
			unless (\$index) {
			   if(\$self->{$field}{HASH}){
			      return(wantarray ? \%{\$self->{$field}{HASH}} : scalar(\%{\$self->{$field}{HASH}}));
			   }
			}

			if (ref(\$index) eq 'HASH') {
			   unless (scalar(\%{\$index})){
			      \$self->{$field}{HASH} ={};
			      \$self->{$field}{ARRAY}=[];
		           }
		           else {
			      \$self->validate_$field(\$index)
			         if \$self->can('validate_$field');
			      foreach my \$key (keys(\%\$index)){
			        push(\@{\$self->{$field}{ARRAY}},\$key)
			          unless (exists(\$self->{$field}{HASH}{\$key}));
			        \$self->{$field}{HASH}{\$key} = \$index->{\$key};
			      }                  
			   }
			   return(wantarray ? \%{\$self->{$field}{HASH}} : scalar(\%{\$self->{$field}{HASH}}));
			}
			if (scalar(\@_)){
			   my \%ret=();
			   foreach my \$key (\@_){
			      last if (!\$key);
			      next if (!exists(\$self->{$field}{HASH}{\$key} ) );
			      \$ret{\$key} = \$self->{$field}{HASH}{\$key};
			   }
			   if (scalar(\@_) == 1 and \$_[0]){
			      return(wantarray ? \%ret : \$ret{\$_[0]});
			   }
			   return(wantarray ? \%ret : scalar(\%ret));
            		}
		     };";
     my $keys_code = "sub {
			my \$self = shift;
			return(wantarray ? \@{\$self->{$field}{ARRAY}}:scalar(\@{\$self->{$field}{ARRAY}}));
		     };";
     my $values_code = "sub {
			my \$self = shift;
			my \@ret  = ();
			foreach my \$key (\@{\$self->{$field}{ARRAY}}){
			   push(\@ret,\$self->{$field}{HASH}{\$key});
			}
			return(wantarray ? \@ret : scalar(\@ret));
		     };";
     my $delete_code = "sub {
			my \$self     = shift;
			my \@ret_val =();
			my \$del_index = 0;
			foreach my \$val (\@_) {
			   \$del_index = 0;
			   foreach my \$item (\@{\$self->{$field}{ARRAY}}){
			      next if (!exists( \$self->{$field}{HASH}{\$val}));
			      if (\$item eq \$val){
				  push(\@ret_val,\$self->{$field}{HASH}{\$val});
				  splice( \@{\$self->{$field}{ARRAY}},\$del_index,1);
				  delete(\$self->{$field}{HASH}{\$val});
			      }
			      \$del_index++;
			   }
                        }
                        return wantarray ? \@ret_val : pop(\@ret_val);
		      };";
     my $exists_code = "sub {
			my \$self = shift;
			my \$count = 0;
			foreach my \$val (\@_) {
			   \$count += exists( \$self->{$field}{HASH}{\$val});
			}
			return(\$count);
		      };";
      {
	 no strict qw(refs);
	 my $set_get_code_ref = eval qq{#line 1 "$imp_class $set_get_method "\n$set_get_code};
	 my $delete_code_ref  = eval qq{#line 1 "$imp_class $delete_method "\n$delete_code};
	 my $keys_code_ref    = eval qq{#line 1 "$imp_class $keys_method "\n$keys_code};
         my $values_code_ref  = eval qq{#line 1 "$imp_class $values_method "\n$values_code};
         my $exists_code_ref  = eval qq{#line 1 "$imp_class $exists_method "\n$exists_code};
         *$exists_method  = $exists_code_ref;
	 *$set_get_method = $set_get_code_ref;
	 *$delete_method  = $delete_code_ref;
	 *$keys_method    = $keys_code_ref;
	 *$values_method  = $values_code_ref;
      }
    }
}
 sub _install_arrays {
   my $self = shift;
   my ($imp_class,$attributes,$fields) = @_;
    #do the arrays next
   foreach my $field (@{$attributes}) {
      if ($fields->{$field}){
         Carp::croak("ERROR: Orignal::$imp_class->attributes, argument 'ARRAYS' field '$field' is also a $fields->{$field} field!");
      }
      my $pop_method     = "$imp_class\::pop_$field";
      my $push_method    = "$imp_class\::push_$field";
      my $shift_method   = "$imp_class\::shift_$field";
      my $unshift_method = "$imp_class\::unshift_$field";
      my $set_get_method = "$imp_class\::$field";
      my $set_get_code = "sub {
	                my \$self = shift;
	                my (\$index) = \@_;
	                
			if (ref(\$index) eq 'ARRAY') {
			  unless (scalar(\@{\$index})){
			    \$self->{$field}{ARRAY}=[];
		          }
		          else {
		  	      \$self->validate_$field(\$index)
		  	          if \$self->can('validate_$field');
		              push(\@{\$self->{$field}{ARRAY}},\@{\$index});
			  }
			  return(wantarray ? \@{\$self->{$field}{ARRAY}} : scalar(\@{\$self->{$field}{ARRAY}}));
			}
			if (!\$index){
			  if (\$self->{$field}{ARRAY}){
		            return(wantarray ? \@{\$self->{$field}{ARRAY}} : scalar(\@{\$self->{$field}{ARRAY}}));
  			  }
  			  else {
  			    return(wantarray ? () : 0);
  			    
  			  }
			}
			else {
			   my \@ret=();
			   foreach my \$index (\@_){
			      push(\@ret,\$self->{$field}{ARRAY}[\$index]);
			   }
			   return(wantarray ? \@ret : scalar(\@ret));
			}
			
		     };";
      my $pop_code   = "sub {
			  my \$self = shift;
			  return(pop( \@{ \$self->{$field}{ARRAY} } ));
                        };";
      my $push_code  = "sub {
			  my \$self = shift;
			  my (\$index) = \@_;
			  my \$return_count = 0;
			  if (ref(\$index) eq 'ARRAY') {
			     \$self->validate_$field(\$index)
		  	        if \$self->can('validate_$field');
			     \$return_count = push( \@{ \$self->{$field}{ARRAY}}, \@{\$index} );
			  }
			  else {
			     foreach my \$val (\@_) {
			       \$self->validate_$field(\$val)
		  	          if \$self->can('validate_$field');
			       \$return_count = push( \@{ \$self->{$field}{ARRAY}}, \$val );
			     }
			  }
			  return(\$return_count);
                        };";
      my $shift_code = "sub {
			  my \$self = shift;
			  my \$index;
			  return(shift( \@{ \$self->{$field}{ARRAY}} ));
                        };";
       my $unshift_code = "sub {
			   my \$self = shift;
			   my (\$index) = \@_;
			   my \$return_count = 0;
			   if (ref(\$index) eq 'ARRAY') {
			     \$self->validate_$field(\$index)
		  	        if \$self->can('validate_$field');
			     \$return_count = unshift( \@{ \$self->{$field}{ARRAY}}, \@{\$index} );
			   }
			   else {
			     foreach my \$val (\@_) {
			       \$return_count = unshift( \@{ \$self->{$field}{ARRAY}}, \$val );
			     }
			  }
			  return(\$return_count);
                          };";
       {
          no strict qw(refs);
          my $pop_code_ref     = eval qq{#line 1  "$imp_class $pop_method "\n$pop_code};
          my $push_code_ref    = eval qq{#line 1  "$imp_class $push_method "\n$push_code};
          my $shift_code_ref   = eval qq{#line 1  "$imp_class $shift_method "\n$shift_code};
          my $unshift_code_ref = eval qq{#line 1  "$imp_class $unshift_method "\n$unshift_code};
          my $set_get_code_ref = eval qq{#line 1  "$imp_class $set_get_method "\n$set_get_code};
          *$unshift_method = $unshift_code_ref;
          *$pop_method     = $pop_code_ref;
          *$push_method    = $push_code_ref;
          *$shift_method   = $shift_code_ref;
          *$set_get_method = $set_get_code_ref;
       }
     }
}
sub _initialize {
    my $self = shift;
    my $opt = defined($_[0]) ? shift : {};
    # Check $opt
    ref($opt) eq 'HASH' || Carp::croak("ERROR: Orignal::$self, first argument must be 'HASH' reference.");
    foreach my $field (keys(%{$opt})) {
       if ($self->can($field)){
	  my $validate = 'validate_'.$field;
	  if ($self->can($validate)){
	       $self->$validate($opt->{$field});
          }
 	  $self->$field($opt->{$field});
       }
       # else {
          # Carp::croak("ERROR: Orignal::".ref($self)."::new, Field $field not defined!");
       # }
    }
}

1;
__END__
=pod

=head1 NAME 

Orignal - Very simple properties/attributes/fields for Perl

head1 SYNOPSIS

  package house;
  use parent  qw(Orignal);
     
  house->attributes({SCALARS 	    =>[qw(address style type)],
                     ORDERED_HASHES =>[qw(owners)],
                     HASHES         =>[qw(rooms)],
                     ARRAYS         =>[qw(occupants pets)]});
                     
  1;
  
  use house;
  
  my $big_house = house->new({address=>'1313 Mockingbird', 
			      type   =>'Mansion'
			      style  =>'Gothic'
                              owners =>{present=>'Lily Munster',past=>'Sam Dracula',builder=>'V. Frankenstein'}
                              rooms  =>{bathrooms=>0,bedrooms=>5,playroom=>1, dungeon=>1, lab=>1},
                              occupants=>[qw(Herman Lilly Grandpa Eddie Marilyn)]},
                              pets     =>[qw(Spot Kitty)]);
  
   my $address = $big_house->address();
   my @people  = $big_house->occupants();
   my %rooms   = $big_house->rooms();
     
=head1 DESCRIPTION

When I said simple I meant very simple. It basically just gives you a very easy way to create class level attributes that
encapsulate class data, enforcing unique field names and has the added bonus of an
ordered hash.

Simply think of it as the base class for other classes and you got the concept. Still unclear
well if you are like me and hate writing setters and getters then this is the mod for you, as
this is all it does.

The main goal of Orignal is to be light and easy to use, the code is less than 20k and
has no dependencies on other modules. I created it out of frustration of liking perl 5.14 attributes 
but being stuck with coding in perl 5.6.

=head1 Usage

Orignal should always be used as part of a larger class or module never on its own. Simply
use Orignal and then call the 'attributes' method directly on your package with an attributes hash
that contains the correct attribute keys.

  package something;
  use Orignal;
  something->{SCALARS=>[qw(nothing)];
  
There are four Attribute keys SCALARS, HASHES, ORDERED_HAHSES and ARRAYS and each key if used must point to
an array reference of fields.  Orignal takes the fields and then creates the code references for each them that you
can then use as if the code was actually in the module.

=head1 Class Methods
       
=head3 attributes

Use only when defining your package. Any other use will result in a die. For example

  package house;
  use parent  qw(Orignal);
     
  house->attributes({SCALARS 	    =>[qw(address style type)],
                     ORDERED_HASHES =>[qw(owners)],
                     HASHES         =>[qw(rooms)],
                     ARRAYS         =>[qw(occupants pets)]});
                     
  1;

Will create a package called house that you can use like this

  use house;
  
  my $big_house = house->new({address=>'1313 Mockingbird', 
			      type   =>'Mansion'
			      style  =>'Gothic'
                              owners =>{present=>'Lily Munster',past=>'Sam Dracula',builder=>'V. Frankenstein'}
                              rooms  =>{bathrooms=>0,bedrooms=>5,playroom=>1, dungeon=>1, lab=>1},
                              occupants=>[qw(Herman Lilly Grandpa Eddie Marilyn)]},
                              pets     =>[qw(Spot Kitty)]);
                              
                              
=head3  new

This is your standard new that takes a hash ref and if a Key in that hash matches a key the name of an attribute the attribute is
set to that value.  If a hash ref key does not match it is simply ignored. It also does not care if you do not match all the attribute
names. 

 my $dho_house = house->new({address=>'472 Evergreen Terrace', 
			     type   =>'Small',
			     style  =>'Clapboard',
                             owners =>{present=>'H. J. Simpson',past=>'Ned Flanders'},
                             pets   =>[qw(snowball5,santas little helper)]);
    
=head3  my_attributes
       
This will return the attribute hash ref used in the creation of the class.
 
  my $attrb = $big_house->my_attributes(); 
  
  $attrb would point to this hash  
		    {SCALARS 	    =>['address','style','type'],
                     ORDERED_HASHES =>['owners'],
                     HASHES         =>['rooms'],
                     ARRAYS         =>['occupants','pets']}
  
     
=head2 Attribute Methods

=head3 SCALARS 

Simple Perl scalars. 

=head4 Getter

A perlish getter for these that uses the field name.

  print $big_house->address();

Will return the value stored in 'address' attribute;

=head4 Setter 

A simple perlish setter that uses the field name.

  $big_house->address('472 Evergreen Terrace');

Will set the value of the 'address' attribute to '472 Evergreen Terrace';

=head4 Validate

You can add an optional validator sub to a SCALAR attribute.  You can validate any condition you want 
but you will have to follow this design pattern  ATTRIBUTE_NAME_validate for the sub name, a shift to get the class, 
then the @_ to get the values passed into to validation sub from the setter, Finally use die if you fail validation. 
See the examples below;  

   #address must not be undef
   sub address_validate {
       my $self = shift;
       my ($new_address) = @_;
       die("ERROR: SomeMode::House::address, cannot be empty.")
         unless ($new_address);
   }       
   #address cannot be "NO" 
   sub address_validate {
       my $self = shift;
       my ($new_address) = @_;
       die("ERROR: SomeMode::House::address, cannot be 'NO'.")
         if ($new_address eq 'NO'); 
   }
 
=head3 HASHES and ORDERED_HASHES 

Simple Perl hashes of scalars.  Orignal has two types unordered and ordered they share all the same methods. 

=head4 Getter

A little more complex this time but still uses the field name.
  
  my %some_rooms = $big_house->rooms();
  my $some_rooms = $big_house->rooms();

will return the hash stored in the rooms attribute of $big_house when called in list context.
In scalar context it will return the hash key pair string. 

  my %bath_count = $big_house->rooms('bathrooms','dungeon');
  my $bath_count = $big_house->rooms('bathrooms','dungeon');
  
will return a hash of 2 keys and their values from the 'rooms' attribute when called in list context and in 
scalar context is will return the hash key pair string. If a key is not found it will return nothing.

Both the hash and ordered_hash work in the same manner.

=head4 Setter

Same as Scalar the field name but can take a hash ref as a parameter as well.
  
  my %owners = $big_house->rooms({kitchen =>1});
  my $owners = $big_house->rooms({kitchen =>1});
  
Will add the name values pair 'kitchen=>1' to the rooms attribute is return the new hash while in scalar context just the   
key pair string will be returned. When using an ordered_hash the order in which you enter the new key value pairs will be 
retained by Orignal except when on a new as you are passing a hash in that will not be in order.

Sending an empty hash ref to the function 

  $big_house->owners({})

will empty out the rooms attribute and return undef, both the hash and ordered_hash work in the same manner. 

=head4 Delete

Orignal defines a delete method as well which is in the format delete_field() that works in the same manner
as a normal hash delete deleting a value from a hash. 

  #  big_house->rooms = {bathrooms=>0,bedrooms=>5,playroom=>1, dungeon=>1, lab=>1}
  
  $scalar = $big_house->delete_rooms(bedrooms);                  # $scalar is 5  
  $scalar = $big_house->delete_rooms(qw(playroom bathrooms));    # $scalar is 0
  @array  = $big_house->delete_rooms(qw(dungeon playroom  lab)); # @array is (1,undef,1);
  
Both the hash and ordered_hash work in the same manner.

=head4 Exists

Orignal defines an exists method as well which is in the format exits_field() it works in the same manner
as a normal hash exits, testing whether a hash key is present. It has the added bonus if you ask for 
more than one key it will give the total count of keys present.

  #  big_house->rooms = {bathrooms=>0,bedrooms=>5,playroom=>1, dungeon=>1, lab=>1}
  
  $scalar = $big_house->exists_rooms(bedrooms);                   # $scalar is 1  
  $scalar = $big_house->exists_rooms(funroom);                   # $scalar is 0
  $array  = $big_house->exists_rooms(qw(dungeon playroom lab));  # $scalar is 3
  
Both the hash and ordered_hash work in the same manner.

=head4 Keys

Orignal defines a keys method as well which is in the format keys_field() it works in the same manner
as a normal hash keys retrieving the list of indices from a hash. However for an Ordered Hash 
they come out the same way they went in.

  #  big_house->rooms = {bathrooms=>0,bedrooms=>5,playroom=>1, dungeon=>1, lab=>1}
  
  $scalar = $big_house->keys_rooms();    # $scalar is  5 
  @array  = $big_house->keys_rooms();    # @array  is  (dungeon,lab,bedrooms,playroom,bathrooms) 
  
  # $big_house->owners ={present=>'Lily Munster',past=>'Sam Dracula',builder=>'V. Frankenstein'}
  # ordered hash
  
  $scalar = $big_house->keys_owners();    # $scalar is 3
  $array  = $big_house->keys_owners();    # @array  is (present,past,builder)
  
As you can see order hash preserves the order of the keys

=head4 Validate

You can add an optional validator sub to any HASH or ORDERED_HASH attribute.  You can validate any condition you want 
but you will have to follow this design pattern  ATTRIBUTE_NAME_validate for the sub name, a shift to get the class, 
then the @_ to get the values passed into to validation sub from the setter, Finally use die if you fail validation. 
See the examples below;  

   #address must not be empty
   sub address_validate {
       my $self = shift;
       my ($new_address) = @_;
       die("ERROR: SomeMode::House::address, cannot be empty.") 
         unless ($new_address);
   }       
   #address has to be an must a hash ref 
   sub address_validate {
       my $self = shift;
       my ($new_address) = @_;
        ref($new_address) eq 'HASH' || die("ERROR: SomeMode::House::address, must be a 'HASH' Ref.");
      
   }
    
=head4 Values

Orignal defines a values method as well which is in the format values_field() it works in the same manner
as a normal hash values returning a list of the values in a hash. However for an Ordered Hash they come
out the same way they went in.

  #  big_house->rooms = {bathrooms=>0,bedrooms=>5,playroom=>1, dungeon=>1, lab=>1}
  
  $scalar = $big_house->values_rooms();    # $scalar is  5 
  @array  = $big_house->values_rooms();    # @array  is  (1,0,5,1,0) 
  
  # $big_house->owners ={present=>'Lily Munster',past=>'Sam Dracula',builder=>'V. Frankenstein'}
  # ordered hash
  
  $scalar = $big_house->values_owners();    # $scalar is 3
  $array  = $big_house->values_owners();    # @array  is ('Lily Munster','Sam Dracula','V. Frankenstein')
  
As you can see order hash preserves the order of the values.

=head3 Arrays

Simple Perl Arrays of scalars.  

=head4 Getter

A little more complex this time but still uses the field name.
  
  my @pets = $big_house->pets();
  my $pets = $big_house->pets();

will return the array stored in the pets attribute of $big_house when called in list context.
In scalar context it will return the count of indexes on the array. 

  my @pets = $big_house->pets(0,2);
  my $pets = $big_house->pets(0,2);
  
will return an array of 2 the values from the 'pets' attribute when called in list context and in 
scalar context is will return the count. If a index is off the array it will return nothing.

=head4 Setter

Same as Scalar the field name but can also take an array ref as the parameter.
  
  my @pets = $big_house->pets(qw(Raven Igor)});
  my $pets = $big_house->pets(qw(Raven Igor));
  
Will add the values Raven and Igor to the end of the pets attribute and return the new array if called in list context.
If called in scalar context just the length of the array will be returned. Like any array values can be duplicated.

Sending an empty array ref to the method

  $big_house->pets([]);

will empty out the pets attribute and return undef.

=head4 Pop

Orignal defines a pop method as well which is in the format pop_field() it works in the same manner
as a normal array pop removing the last element from an array and returning it. 

  pets     =>[qw(Spot Kitty)])
  $scalar = $big_house->pop_pets();  # $scalar is Kitty
  @array  = $big_house->pets();      # @array is ('Spot')
  
  
=head4 Push

Orignal defines a push method as well which is in the format push_field() it works in the same manner
as a normal array push appending one or more elements to an array. 

  pets     =>[qw(Spot)])
  $scalar = $big_house->push_pets('Kitty');  # $scalar is 2, pets= ('Spot','Kitty')
  @array  = $big_house->push_pets('Kitty');    @array is ('Spot','Kitty'), pets= ('Spot','Kitty')

=head4 Shift

Orignal defines a shift method as well which is in the format shift_field() it works in the same manner
as a normal array shift removing the first element of an array, and returning it . 

  pets     =>[qw(Spot Kitty)])
  $scalar = $big_house->shift_pets();  # $scalar is Spot
  @array  = $big_house->pets();       # @array is ('Kitty')
  
=head4 Unshift

Orignal defines a unshift method as well which is in the format unshift_field() it works in the same manner
as a normal array unshift prepending more elements to the beginning of a list. 

  pets     =>[qw(Spot)])
  $scalar = $big_house->push_pets('Kitty');  # $scalar is 2, pets= ('Kitty','Spot')
  @array  = $big_house->push_pets('Kitty');    @array is ('Kitty','Spot'), pets= ('Kitty','Spot')

=head4 Validate

You can add an optional validator sub to an ARRAY attribute.  You can validate any condition you want 
but you will have to follow this design pattern  ATTRIBUTE_NAME_validate for the sub name, a shift to get the class, 
then the @_ to get the values passed into to validation sub from the setter, Finally use die if you fail validation. 
See the examples below;  

   #address must not be empty
   sub address_validate {
       my $self = shift;
       my ($new_address) = @_;
       die("ERROR: SomeMode::House::address, cannot be empty.") 
         unless ($new_address);
   }       
   #address has to be an must a array ref 
   sub address_validate {
       my $self = shift;
       my ($new_address) = @_;
       ref($new_address) eq 'ARRAY' || die("ERROR: SomeMode::House::address, must be an 'ARRAY' Ref.");
         
   }


=head1 CONTRIBUTING 
If you like Orignal and want to add to it or just complain. 
The source is available on GitHub at L<https://github.com/byterock/Orignal>
   
=head1 Bugs

I haven't found any but I am sure there are?  You can report them here L<https://rt.cpan.org/Public/Dist/Display.html?Name=Orignal> or 
here L<https://github.com/byterock/Orignal/issues>.

=head1 SUPPORT

Now there is a Wiki, but nothing there yet L<https://github.com/byterock/Orignal/wiki>.

=head1 AUTHOR

John Scoles.

L<https://github.com/byterock/Orignal>

=head1 COPYRIGHT AND LICENSE ^

Copyright 2011 By John Scoles.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut


