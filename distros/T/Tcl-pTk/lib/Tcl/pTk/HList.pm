

package Tcl::pTk::HList;

our ($VERSION) = ('1.02');

@Tcl::pTk::HList::ISA = (Tcl::pTk::Widget);

use strict;

use Carp;

# Wrapper method for the -indicatorcmd (thru the %replace_options hash in Tcl::pTk::Widget)
#
# perltk's HList -indicatorcmd expects to see the pathname and the event type supplied to the callback.
#  tixHlist -indicatorcmd only defines the pathname to be supplied, So we have to supply an interfacing
#  routine for this option to emulate the perltk behaivor.
sub _procIndicatorCmd{
        my $self = shift;
        my $value = shift;
                
        if( ref($value) ne 'CODE' and ref($value) ne 'ARRAY' ){
                croak("Error in ".__PACKAGE__."::_procIndicatorCmd Supplied value for -indicatorcmd is not a code or array reference\n");
        }
        
        my $callback = Tcl::pTk::Callback->new($value);
        
        $self->{_indicatorcmd} = $callback;
        
        
        # -indicatorcmd supplied to the tcl widget is created here
        my $tclcmd = sub{
                my $entry = shift;
                my $event = $self->call('tixEvent', 'type'); # get the event type usign tixEvent
                $self->{_indicatorcmd}->Call($entry, $event);
        };
        
        $self->call($self->path, 'configure', -indicatorcmd => $tclcmd)
}
                

# Overriden version of add that handles storing any -data option,
#   because the interface between perl and tcl doesn't allow for tie-ing of
#   arbitrary variable references (only scalar and hash references supported now)
sub add
{
        my $self = shift;
        my $item = shift;
        
        
        my %args = @_;
        
        if( defined($args{-data})  ){
                my $data = delete $args{-data};
                #     
                $self->{_HListdata}{$item} = $data;
        }
        
        $self->SUPER::add($item, %args);
}


# Overriden version of entryconfigure that handles storing any -data option,
#   because the interface between perl and tcl doesn't allow for tie-ing of
#   arbitrary variable references (only scalar and hash references supported now)
sub entryconfigure{
        my $self = shift;
        my $item = shift;
        
        
        my %args = @_;
        
        if( defined($args{-data})  ){
                my $data = delete $args{-data};
                #     
 
                
                $self->{_HListdata}{$item} = $data;
                
                return unless( %args); # Don't call parent method if no more args
        }
        
        return $self->SUPER::entryconfigure($item, %args);
        
}

# Overriden version of addChild that handles storing any -data option,
#   because the interface between perl and tcl doesn't allow for tie-ing of
#   arbitrary variable references (only scalar and hash references supported now)
sub addchild{
        my $self = shift;
        my $parentPath = shift;
        
        
        my %args = @_;
        
        if( defined($args{-data})  ){
                my $data = delete $args{-data};
                #     
 
                my $item = $self->SUPER::addchild($parentPath, %args);

                
                $self->{_HListdata}{$item} = $data;
                return $item;
        }
        
        return $self->SUPER::addchild($parentPath, %args);
        
}

# Overriden version of delete that handles delete any -data option dadta
sub delete{
        my $self   = shift;
        my $option = shift;

        my $HListdata = $self->{_HListdata} || {};
        
        my $separator = $self->cget(-separator);

        if( $option eq 'all'){
                %$HListdata = ();
        }
        elsif( $option eq 'entry'){
                my $entry = $_[0];
                delete $HListdata->{$entry};

               # Find child keys of entry
                $entry = quotemeta($entry); # get ready to use entry in regexp
                $separator = quotemeta($separator); # get ready to use $separator in regexp
                my @deleteKeys = grep /$entry$separator.+/, keys %$HListdata;
                delete @$HListdata{@deleteKeys};
 
        }
        elsif( $option eq 'offsprings'){
                my $entry = $_[0];
                
                # Find child keys of entry
                $entry = quotemeta($entry); # get ready to use entry in regexp
                $separator = quotemeta($separator); # get ready to use $separator in regexp
                my @deleteKeys = grep /$entry$separator.+/, keys %$HListdata;
                delete @$HListdata{@deleteKeys};
        }
        elsif( $option eq 'siblings'){
                my $entry = $_[0];
                
                # Find child keys of entry
                my @entryComponents = split($separator, $entry);
                
                # Find parent
                pop @entryComponents;
                my $parent = join($separator, @entryComponents);
                
                $parent = quotemeta($parent); # get ready to use parent in regexp
                $separator = quotemeta($separator); # get ready to use $separator in regexp
                my @deleteKeys = grep $_ ne $entry && /$parent$separator.+/, keys %$HListdata;
                delete @$HListdata{@deleteKeys};
        }
        
        
        $self->SUPER::delete($option, @_);
}
 
# Overriden version of info that handles getting -data storage
sub info{
        my $self   = shift;
        my $option = shift;
        
        if( $option eq 'data'){
                my $HListdata = $self->{_HListdata} || {};
                my $item = shift;
                return $HListdata->{$item};
        }
        
        return $self->call($self, 'info', $option, @_);
}

 
# Overriden version of info that handles getting -data storage and -window itemtypes
sub entrycget{
        my $self   = shift;
        my $item   = shift;
        my $option = shift;
        
        if( $option eq '-data'){
                my $HListdata = $self->{_HListdata} || {};
                return $HListdata->{$item};
        }
        if( $option eq '-window'){
                my $window = $self->SUPER::entrycget($item, $option);
                return $self->interp->widget($window);
        }
	if( $option eq '-image'){
                my $name = $self->SUPER::entrycget($item, $option);
                if( $name){
                    # Turn image into an object;
                    my $type = $self->call('image', 'type', $name);
                    $type = ucfirst($type);
                    my $package = "Tcl::pTk::$type";
                    my $obj = $self->interp->declare_widget($name, $package);
                    return $obj;
            	}
		return $name;
         }

        
        return $self->SUPER::entrycget($item, $option, @_);
}
 

########### Sub Copied from Tk::Hlist for compatibility with perl/tk ######
sub GetNearest
{
 my ($w,$y,$undefafterend) = @_;
 my $ent = $w->nearest($y);
 if (defined $ent)
  {
   if ($undefafterend)
    {
     my $borderwidth = $w->cget('-borderwidth');
     my $highlightthickness = $w->cget('-highlightthickness');
     my $bottomy = ($w->infoBbox($ent))[3];
     $bottomy += $borderwidth + $highlightthickness;
     if ($w->header('exist', 0))
      {
       $bottomy += $w->header('height');
      }
     if ($y > $bottomy)
      {
       #print "$y > $bottomy\n";
       return undef;
      }
    }
   my $state = $w->entrycget($ent, '-state');
   return $ent if (!defined($state) || $state ne 'disabled');
  }
 return undef;
}
        

1;
