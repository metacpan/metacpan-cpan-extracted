

package Tcl::pTk::Listbox;

our ($VERSION) = ('1.02');

@Tcl::pTk::Listbox::ISA = (Tcl::pTk::Widget);

use strict;

use Carp;

# Overriden version of configure that handles storing and tie-ing the  any -listvariable option,
sub configure{
        my $self = shift;
        
        
        my %args = @_;
        
        if( defined($args{-listvariable})  ){
                my $listvariable = $args{-listvariable};
                #     
                if( defined($listvariable) and ref($listvariable) eq 'ARRAY'){
                        
                        my @listVars = @$listvariable;  # Save the values for reseting after the tie
                        # Tie the list var, so that changes to it will be reflected in the
                        #   Listbox
                        tie @$listvariable, 'Tcl::pTk::Listbox', $self;
                        
                        @$listvariable = @listVars; # set the values after the tie
                        
                        
                }
                
                # Untie the currently tied listvar, if it exists
                my $currentListVar;
                if( !defined($listvariable) && 
                     defined( $currentListVar = $self->Tcl::pTk::Derived::_cget(-listvariable)) &&
                     tied($$currentListVar)){
                        untie($$currentListVar);
                }
                        
                
                # Store listvariable in the configuration store, for retreival later
                $self->Tcl::pTk::Derived::_configure(-listvariable, $listvariable);

                
        }
        
        return $self->SUPER::configure(%args);
        
}


# Overridden cget to return the -listvariable ref, if it has been setgrent
# reference it.)
sub cget {
    my $self = shift;
    my @args = @_;
    
    my $option = $args[0];
    
    if( $option eq '-listvariable'){  # return the store list variable
        return $self->Tcl::pTk::Derived::_cget(-listvariable);        
    }
    
    # Otherwise call the parent cget
    return $self->SUPER::cget(@args);
}
    
# Method to enable balloons to be attached to individual items
#   in a listbox by supplying an array as -msg (See the balloon.pl demo for example)
sub BalloonInfo
{
 my ($listbox,$balloon,$X,$Y,@opt) = @_;
 my ($x,$y) = $listbox->pointerxy;
 $x = $x - $listbox->rootx;
 $y = $y - $listbox->rooty;
 #print STDERR "x = $x/$y\n";
 my $index = $listbox->index('@' . $x . ',' . $y);
 foreach my $opt (@opt)
  {
   my $info = $balloon->GetOption($opt,$listbox);
   if ($opt =~ /^-(statusmsg|balloonmsg)$/ && UNIVERSAL::isa($info,'ARRAY'))
    {
     $balloon->Subclient($index);
     if (defined $info->[$index])
      {
       return $info->[$index];
      }
     return '';
    }
   return $info;
  }
}


############### Methods to implement the tied scalar and array interface #########
####              Copied from perltk Tk::Listbox #######
#
sub TIEARRAY {
  my ( $class, $obj, %options ) = @_;
  return bless {
	    OBJECT => \$obj,
	    OPTION => \%options }, $class;
}

sub TIESCALAR {
  my ( $class, $obj, %options ) = @_;
  return bless {
	    OBJECT => \$obj,
	    OPTION => \%options }, $class;
}

# FETCH
# -----
# Return either the full contents or only the selected items in the
# box depending on whether we tied it to an array or scalar respectively
sub FETCH {
  my $class = shift;

  my $self = ${$class->{OBJECT}};
  my %options = %{$class->{OPTION}} if defined $class->{OPTION};;

  # Define the return variable
  my $result;

  # Check whether we are have a tied array or scalar quantity
  if ( @_ ) {
     my $i = shift;
     # The Tk:: Listbox has been tied to an array, we are returning
     # an array list of the current items in the Listbox
     $result = $self->get($i);
  } else {
     # The Tk::Listbox has been tied to a scalar, we are returning a
     # reference to an array or hash containing the currently selected items
     my ( @array, %hash );

     if ( defined $options{ReturnType} ) {

        # THREE-WAY SWITCH
        if ( $options{ReturnType} eq "index" ) {
           $result = [$self->curselection];
        } elsif ( $options{ReturnType} eq "element" ) {
	   foreach my $selection ( $self->curselection ) {
              push(@array,$self->get($selection)); }
           $result = \@array;
	} elsif ( $options{ReturnType} eq "both" ) {
	   foreach my $selection ( $self->curselection ) {
              %hash = ( %hash, $selection => $self->get($selection)); }
           $result = \%hash;
	}
     } else {
        # return elements (default)
        foreach my $selection ( $self->curselection ) {
           push(@array,$self->get($selection)); }
        $result = \@array;
     }
  }
  return $result;
}

# FETCHSIZE
# ---------
# Return the number of elements in the Listbox when tied to an array
sub FETCHSIZE {
  my $class = shift;
  return ${$class->{OBJECT}}->size();
}

# STORE
# -----
# If tied to an array we will modify the Listbox contents, while if tied
# to a scalar we will select and clear elements.
sub STORE {

  if ( scalar(@_) == 2 ) {
     # we have a tied scalar
     my ( $class, $selected ) = @_;
     my $self = ${$class->{OBJECT}};
     my %options = %{$class->{OPTION}} if defined $class->{OPTION};;

     # clear currently selected elements
     $self->selectionClear(0,'end');

     # set selected elements
     if ( defined $options{ReturnType} ) {

        # THREE-WAY SWITCH
        if ( $options{ReturnType} eq "index" ) {
           for ( my $i=0; $i < scalar(@$selected) ; $i++ ) {
              for ( my $j=0; $j < $self->size() ; $j++ ) {
                  if( $j == $$selected[$i] ) {
	             $self->selectionSet($j); last; }
              }
           }
        } elsif ( $options{ReturnType} eq "element" ) {
           for ( my $k=0; $k < scalar(@$selected) ; $k++ ) {
              for ( my $l=0; $l < $self->size() ; $l++ ) {
                 if( $self->get($l) eq $$selected[$k] ) {
	            $self->selectionSet($l); last; }
              }
           }
	} elsif ( $options{ReturnType} eq "both" ) {
           foreach my $key ( keys %$selected ) {
              $self->selectionSet($key)
	              if $$selected{$key} eq $self->get($key);
	   }
	}
     } else {
        # return elements (default)
        for ( my $k=0; $k < scalar(@$selected) ; $k++ ) {
           for ( my $l=0; $l < $self->size() ; $l++ ) {
              if( $self->get($l) eq $$selected[$k] ) {
	         $self->selectionSet($l); last; }
           }
        }
     }

  } else {
     # we have a tied array
     my ( $class, $index, $value ) = @_;
     my $self = ${$class->{OBJECT}};

     # check size of current contents list
     my $sizeof = $self->size();

     if ( $index <= $sizeof ) {
        # Change a current listbox entry
        $self->delete($index);
        $self->insert($index, $value);
     } else {
        # Add a new value
        if ( defined $index ) {
           $self->insert($index, $value);
        } else {
           $self->insert("end", $value);
        }
     }
   }
}

# CLEAR
# -----
# Empty the Listbox of contents if tied to an array
sub CLEAR {
  my $class = shift;
  ${$class->{OBJECT}}->delete(0, 'end');
}

# EXTEND
# ------
# Do nothing and be happy about it
sub EXTEND { }

# PUSH
# ----
# Append elements onto the Listbox contents
sub PUSH {
  my ( $class, @list ) = @_;
  ${$class->{OBJECT}}->insert('end', @list);
}

# POP
# ---
# Remove last element of the array and return it
sub POP {
   my $class = shift;

   my $value = ${$class->{OBJECT}}->get('end');
   ${$class->{OBJECT}}->delete('end');
   return $value;
}

# SHIFT
# -----
# Removes the first element and returns it
sub SHIFT {
   my $class = shift;

   my $value = ${$class->{OBJECT}}->get(0);
   ${$class->{OBJECT}}->delete(0);
   return $value
}

# UNSHIFT
# -------
# Insert elements at the beginning of the Listbox
sub UNSHIFT {
   my ( $class, @list ) = @_;
   ${$class->{OBJECT}}->insert(0, @list);
}

# DELETE
# ------
# Delete element at specified index
sub DELETE {
   my ( $class, @list ) = @_;

   my $value = ${$class->{OBJECT}}->get(@list);
   ${$class->{OBJECT}}->delete(@list);
   return $value;
}

# EXISTS
# ------
# Returns true if the index exist, and undef if not
sub EXISTS {
   my ( $class, $index ) = @_;
   return undef unless ${$class->{OBJECT}}->get($index);
}

# SPLICE
# ------
# Performs equivalent of splice on the listbox contents
sub SPLICE {
   my $class = shift;

   my $self = ${$class->{OBJECT}};

   # check for arguments
   my @elements;
   if ( scalar(@_) == 0 ) {
      # none
      @elements = $self->get(0,'end');
      $self->delete(0,'end');
      return wantarray ? @elements : $elements[scalar(@elements)-1];;

   } elsif ( scalar(@_) == 1 ) {
      # $offset
      my ( $offset ) = @_;
      if ( $offset < 0 ) {
         my $start = $self->size() + $offset;
         if ( $start > 0 ) {
	    @elements = $self->get($start,'end');
            $self->delete($start,'end');
	    return wantarray ? @elements : $elements[scalar(@elements)-1];
         } else {
            return undef;
	 }
      } else {
	 @elements = $self->get($offset,'end');
         $self->delete($offset,'end');
         return wantarray ? @elements : $elements[scalar(@elements)-1];
      }

   } elsif ( scalar(@_) == 2 ) {
      # $offset and $length
      my ( $offset, $length ) = @_;
      if ( $offset < 0 ) {
         my $start = $self->size() + $offset;
         my $end = $self->size() + $offset + $length - 1;
	 if ( $start > 0 ) {
	    @elements = $self->get($start,$end);
            $self->delete($start,$end);
	    return wantarray ? @elements : $elements[scalar(@elements)-1];
         } else {
            return undef;
	 }
      } else {
	 @elements = $self->get($offset,$offset+$length-1);
         $self->delete($offset,$offset+$length-1);
         return wantarray ? @elements : $elements[scalar(@elements)-1];
      }

   } else {
      # $offset, $length and @list
      my ( $offset, $length, @list ) = @_;
      if ( $offset < 0 ) {
         my $start = $self->size() + $offset;
         my $end = $self->size() + $offset + $length - 1;
	 if ( $start > 0 ) {
	    @elements = $self->get($start,$end);
            $self->delete($start,$end);
	    $self->insert($start,@list);
	    return wantarray ? @elements : $elements[scalar(@elements)-1];
         } else {
            return undef;
	 }
      } else {
	 @elements = $self->get($offset,$offset+$length-1);
         $self->delete($offset,$offset+$length-1);
	 $self->insert($offset,@list);
         return wantarray ? @elements : $elements[scalar(@elements)-1];
      }
   }
}

        

1;
