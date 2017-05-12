package OOP::_getArgs;

use strict;
use Carp;

sub EXISTS {

 my ($self,$key) = @_;

 my $value = $self->{ARGS};
 
 return (exists $value->{$key});

}
sub TIEHASH {

 my ($class, $ARGS) = @_;

 $ARGS->{_INDEX} = {};
 
 my $arguments = $ARGS->{ARGS} || croak "No arguments were passed to the prototype!";
 my $prototype = $ARGS->{PROTOTYPE} || croak "No prototype was passed to the prototype!";

 my $self = $ARGS;

 return bless $self, $class;
 
}
sub STORE {

 my ($self, $key, $val) = @_;

 my $value = $self->{ARGS};
 my $myProto = $self->{PROTOTYPE};

 my $_mainobj = $self->{_MAIN} || $self;

 my $_parent = $_mainobj->{_INDEX}->{$value}->{parent};
 my $_parentkey = $_mainobj->{_INDEX}->{$value}->{parentkey};
 my $_parentPrototype = $_parent->{proto}->{$_parentkey};

 my $_currPrototype;

 if (exists($value->{$key}) &&
     exists($myProto->{$key}) && 
     ref $myProto->{$key} eq 'HASH' && 
     ref $_parentPrototype eq 'HASH' && 
     !exists($myProto->{$key}->{dataType})
    )
  {
   $_currPrototype = $_parentPrototype;
  }
 elsif ((ref $myProto->{$key} eq 'HASH') && exists($myProto->{$key}->{dataType}))
  {
   $_currPrototype = $myProto->{$key};
  }
 else
  {
   my $protoVal = $myProto->{$key};
   my $dataType = exists($myProto->{$key}) ? ($myProto->{$key} ne '' ? ref($myProto->{$key}) : 'scalar') : (ref $val || 'scalar');
   if ((ref $myProto->{$key} eq 'ARRAY') && (scalar @{$myProto->{$key}} == 0))
    {
     $protoVal = '';
    }
   elsif((ref $myProto->{$key} eq 'HASH') && (scalar %{$myProto->{$key}} == 0))
    {
     $protoVal = '';
    }
   elsif ((ref $myProto->{$key} eq '') && (scalar $myProto->{$key} <= 0))
    {
     $protoVal = '';
    }
   $_currPrototype->{dataType} = $dataType;
   $_currPrototype->{writeAccess} = $protoVal eq '' ? 1 : 0;
   $_currPrototype->{readAccess} = 1;
   $_currPrototype->{allowEmpty} = $protoVal ne '' ? 1 : 0;
   $_currPrototype->{locked} = 0;
   $_currPrototype->{required} = 1;
   $_currPrototype->{minLength} = $_currPrototype->{maxLength} = length($protoVal) if $protoVal ne '' ;
   $_currPrototype->{value} = $myProto->{$key};
  }
  
 if (uc($_currPrototype->{dataType}) eq 'HASH')
  {
   ! (exists($_currPrototype->{writeAccess}) && ($_currPrototype->{writeAccess} <= 0)) ||
    ( exists($value->{$key}) || croak "'$key' is an invalid key according to constructor!" );   

   ref $val eq 'HASH' || croak "Attempt to pass improper data type to '$key'!";
  }
 else
  {
   !(exists($_currPrototype->{writeAccess}) && 
    ($_currPrototype->{writeAccess} == 0)) || 
     croak "'$key' is read-only according to constructor!";

   !(exists($_currPrototype->{writeAccess}) && 
    ($_currPrototype->{writeAccess} == -1) &&
    (exists($value->{$key}))) || 
     croak "'$key' is read-only according to constructor!";
    
    my $valType = ref($val) || 'scalar';
    $valType = uc($valType);
    
    uc($_currPrototype->{dataType}) eq $valType || croak "Attempt to pass improper data type to '$key'!";
  }

 $self->_checkArgs({
 		    key => $key,
                    action => 'store',
                    value => $val,
                    argsRef => $value,
 		    hashRef => $myProto
                   });

 $value->{$key} = $val;
 
}
sub DELETE {

  my ($self, $key) = @_;

  my $value = $self->{ARGS};
  
  return unless exists $value->{$key};
  
  my $myProto = $self->{PROTOTYPE};
  my $_currPrototype = $myProto->{$key};
  
  ref $_currPrototype eq 'HASH' && exists($_currPrototype->{locked}) && ($_currPrototype->{locked} == 1) ?
    croak "'$key' may not be removed according to constructor!" :
    delete $value->{$key};
 
}

sub CLEAR {

  my $self = shift;

  my $_mainobj = $self->{_MAIN} || $self;

  $self->{ARGS}->{$_} = undef foreach keys %{$self->{ARGS}};
  
}
sub FETCH {

 my ($self, $key) = @_;

 my $_mainobj = $self->{_MAIN} || $self;
 my $_parent = $self->{PARENT};
 my $_parentkey = $self->{PARENTKEY};
 my $value = $self->{ARGS};
 my $myProto = $self->{PROTOTYPE};

 $self->_checkArgs({
                    key => $key, 
                    action => 'fetch',
                    argsRef => $value,
                    hashRef => $myProto
                   });

 if (ref $myProto eq 'HASH')
  {
   my $protoType = ((ref $myProto->{$key} eq 'HASH') && 
                    (exists($myProto->{$key}->{dataType})) && 
                    (uc($myProto->{$key}->{dataType}) eq 'HASH')) ?
                     $myProto->{$key}->{value}:
  	                 $myProto->{$key};

   $_mainobj->{_INDEX}->{$value} = {
                                    parent => $_parent,
                                    parentkey => $_parentkey
                                   };
  
   if (ref($value->{$key}) eq 'HASH')
    { 
     my $obj = tie(my %test, 'OOP::_getArgs', {
                                               _MAIN => $_mainobj,
                                               PARENT => {
                                                          args => $value,
                                                          proto => $myProto
                                                         },
                                               PARENTKEY => $key,
                                               ARGS => $value->{$key},
                                               PROTOTYPE => $protoType
                      	                    });
                      	                    
     return (\%test);               	         
    }
  } 
  
 return $value->{$key};

}

sub FIRSTKEY {

 my ($self) = @_;

 my $temp = keys %{$self->{ARGS}};

 return scalar each %{$self->{ARGS}};
 
}

sub NEXTKEY {
 
 my ($self) = @_;
 
 return each %{$self->{ARGS}};

}

sub _checkArgs {

 my ($self, $ARGS) = @_;

 my $action = $ARGS->{action};
 my $accessKey = $ARGS->{key};
 my $storeVal = $ARGS->{value};
 my $argsRef = $ARGS->{argsRef};
 my $hashRef = $ARGS->{hashRef};

   if (exists($hashRef->{$accessKey}))
    {
     my $value = $hashRef->{$accessKey};

     $ARGS->{_prototype} = $value;
     $self->_checkParameter($ARGS);
    }
   else
    {
     my $_mainobj = $self->{_MAIN} || $self;
     
     my $_parent = $_mainobj->{_INDEX}->{$argsRef}->{parent} || $self->{PARENT};
     my $_parentkey = $_mainobj->{_INDEX}->{$argsRef}->{parentkey}  || $self->{PARENTKEY};
     my $_parentPrototype = $_parent->{proto}->{$_parentkey};

     $ARGS->{_prototype} = $_parentPrototype;
     $self->_checkParameter($ARGS);
    }
  
 return (); 
  
}
sub _checkParameter {

 my ($self, $ARGS) = @_;

 my $action = $ARGS->{action};
 my $accessKey = $ARGS->{key};
 my $storeVal = $ARGS->{value};
 my $argsRef = $ARGS->{argsRef};
 my $hashRef = $ARGS->{hashRef};
 my $_prototype = $ARGS->{_prototype};

  if ((ref($_prototype) eq 'HASH') && exists($_prototype->{dataType}))
   { 
    $self->_checkAttributes({
                             action => $action,
                             value => $storeVal,
                             attributes => $_prototype,
                             key => $accessKey,
                             argsRef => $argsRef
                            });
   }
  else
   {
    if ((!exists($argsRef->{$accessKey})) && exists($hashRef->{$accessKey}))
     {
      if (uc($action) ne 'STORE')
       {
        croak "Parameter '$accessKey' was not passed to the constructor!";
       }
     }
    elsif (exists($argsRef->{$accessKey}) && (!exists($hashRef->{$accessKey})))
     {
      croak "Parameter '$accessKey' is not permitted!";
     }
    elsif (!exists($argsRef->{$accessKey}) && (!exists($hashRef->{$accessKey})))
     {
      if (((uc($action) ne 'STORE') && (uc($_prototype->{dataType}) eq 'HASH')) ||
          (uc($_prototype->{dataType}) ne 'HASH')
         )
       {
        croak "Parameter '$accessKey' is not a defined key!";
       } 
     }
   }

}
sub _checkAttributes {

 my ($self, $ARGS) = @_;
 
 my $attribute = $ARGS->{attributes}; # prototype
 my $argsRef = $ARGS->{argsRef};
 my $action = uc($ARGS->{action});
 my $storeVal = $ARGS->{value};
 my $key = $ARGS->{key};
 my $_countUp = 0;

 my $_mainobj = $self->{_MAIN} || $self;
 
 my $_parent = $_mainobj->{_INDEX}->{$argsRef}->{parent} || $self->{PARENT};
 my $_parentkey = $_mainobj->{_INDEX}->{$argsRef}->{parentkey}  || $self->{PARENTKEY};
# my $_parent = $_mainobj->{_INDEX}->{$argsRef}->{parent};
# my $_parentkey = $_mainobj->{_INDEX}->{$argsRef}->{parentkey};
 my $_parentArgs = $_parent->{args}->{$_parentkey};
 my $_parentPrototype = $_parent->{proto}->{$_parentkey};

 my ($verbIs, $verbAre);
  
 for (qw( allowEmpty dataType maxLength minLength readAccess required value writeAccess )) 
  { 
   exists $attribute->{$_} || croak "'$key' is missing the $_ attribute!";
  } 

 my $_isChild = ($_parentPrototype eq $attribute) ? 1 : 0;
 
 my $xvalue = (uc($action) eq 'STORE') || (uc($action) eq 'FETCH' && $_isChild ) ? $argsRef : $argsRef->{$key} ;

 if (ref($attribute->{value}) eq 'HASH')
  {
   for (keys(%{$attribute->{value}}))
    {
     my($_key, $_value) = ($_, $attribute->{value}->{$_});
     
      if ((ref $_value eq 'HASH') && ($_value->{required}) && (!exists $xvalue->{$_key})) 
       {
           croak "The required key '$_key' was not passed to the constructor!";
       }
    }
  }

 my $value = $argsRef->{$key};

 if ($action eq 'STORE')
  {
   $verbIs = $verbAre = 'would be';
   $_countUp = 1;
   
   if ($attribute->{writeAccess} <= 0)
    {
     $key = $_isChild ? $_parentkey : $key;
     croak "The '$key' structure is write protected!";
    }
  }
 else
  {
   $verbIs = 'is';
   $verbAre = 'are';
  } 
 
 (my $str = (caller(4))[3]) =~ s/(.|\n)/sprintf("%02lx", ord $1)/eg;
 if (uc($attribute->{dataType}) eq 'SCALAR')
  {
   $attribute->{readAccess} <= 0 and $str =~ /4f4f503a3a4163636573736f723a3a67657450726f7065727479/ || 
    croak "Direct read access to '$key' is prohibited!";
    
   !(uc($action) eq 'STORE') or $value = $storeVal;
  
   !(($attribute->{allowEmpty} <= 0) && ($value eq '')) || 
    croak "'$key' $verbIs empty in violation of constructor's definition!";
   
   if ((length($value) >= $attribute->{maxLength}))
    {
     croak "'$key' $verbIs too long, in violation of constructor's definition!";
    }
   elsif ((length($value) <= $attribute->{minLength}) && (($value ne '') && ($attribute->{allowEmpty} > 0)))
    {
     croak "'$key' $verbIs shorter in violation of constructor's definition!";
    }  
  }
 elsif (uc($attribute->{dataType}) eq 'HASH')
  {
   if ($_isChild)
    {
     $value = $_parentArgs;

     if (uc($action) eq 'FETCH')
      {
       exists($value->{$key}) || croak "The key '$key' does not exist and thus cannot be read!";
      } 
     elsif(uc($action) eq 'STORE')
      {
       !exists($value->{$key}) || ($_countUp = 0);
      }
    }

   if (uc($action) eq 'STORE')
    {
     $key = $_parentkey;
     $value = $_parentArgs;
    }
   else
    {
     $attribute->{readAccess} <= 0 and $str =~ /4f4f503a3a4163636573736f723a3a67657450726f7065727479/ || 
      croak "Direct read access to '$key' is prohibited!";
    }
    
   my $keys = keys(%{$value}) + $_countUp;
   
   if ($attribute->{allowEmpty} <= 0)
    {
     !($keys <= 0) || croak "'$key' $verbIs empty in violation of constructor's definition!";
    }
    
   if (($keys > $attribute->{maxLength}))
    {
     croak "There $verbAre more items in '$key' structure than permitted!";
    }
   elsif (($keys < $attribute->{minLength}))
    {
     croak "There $verbAre fewer items in '$key' structure than permitted!";
    } 
    
  } 
 
 
 return();
 
}

1;

