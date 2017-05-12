package OOP;

use OOP::Constructor;
use OOP::Accessor;
@ISA = qw(OOP::Constructor OOP::Accessor);

use strict;

#***************************************************************************
############################################################################
#*[OOP]*********************************************************************
#
# Author  : Milan Adamovsky
# Date    : 01/14/2008
# Updated : 04/03/2008
#
# Version : 1.01
#
# Copyright 2007-Present Milan Adamovsky.  All rights reserved.
# It may be used and modified freely, but I do request that this copyright
# notice remain attached to the file.  You may modify this module  as  you 
# wish,  but if you redistribute a modified version,  please attach a note
# listing the modifications you have made.
#
# Purpose : This class (module) provides a developer with various methods
#           that enforce uniform OOP conventions and ensure sound OOP
#           development in PERL.
# 
# Usage   : For a full detailed usage of this class,  please refer to the
#           POD found attached below.  To read it simply type the command
#           'perldoc OOP' at the command-prompt or simply scroll down.
#
# History : 04/03/2008 - Version 1.01
#           Fixed logic that if a dataType is a hash with a writeAccess
#           of '1', that any elements not specified in the value can be
#           added dynamically and do not have to be explicitly specified.
#           Added missing EXISTS to _getArgs.pm
#
#***************************************************************************

$OOP::VERSION='1.01';

sub new {

 my ($class, $ARGS) = (@_);
 
 my $self = bless {}, $class;

 $self->{PROPERTIES} = $self->set_args($ARGS);

 return $self;
 
}

#***************************************************************************  
#*[_init]*******************************************************************
# PLACEHOLDER FOR FUTURE . NOT USED UNTIL THIS NOTICE IS REMOVED!
sub _init
{ 

 no strict;

 my ($self, $ARGS) = @_;

 my $caller = $ARGS->{caller};
 my $callerPkg = ref $ARGS->{caller};
 my $pluginFolder = "./$callerPkg/Core";

 my $obj;

 opendir(COMPONENTS, $pluginFolder);
  my @files = readdir(COMPONENTS);
 closedir(COMPONENTS);

 map {
      /(.*)\.pm/;
      my $cpy = $1;

      if ($cpy)
       {
        ($cpy->use && print "Loading " . $cpy . " version ");
        $obj = $cpy->new($caller);
        
        if ($obj->{inherit})
         {
          push(@$callerPkg::ISA, $cpy) 
         }
         
        $caller->{CORE}->{$cpy} = $obj;
        
        print ${$cpy.'::VERSION'} . "... ";
        print "Ok.\n";
       }
     } @files;

 return();

}

1;
 
__END__

=head1 NAME

OOP - Object Oriented Programming Class

=head1 SYNOPSIS

  # Illustrates how to define a prototype, how the
  # parameters are passed, and how to access the
  # processed parameters.

  use OOP;

  # These are the parameters normally passed 
  # to a class using OOP.pm.
   
  my $classPrototype = {
             one => 1,
             two => 2,
             three => {
                        hi => {
                               dataType => 'hash',
                               allowEmpty => 0,
                               maxLength => 3,
                               minLength => 1,
                               readAccess => 1,
                               required => 1,
                               value => {
                                         bye => '',
                                         ebye => {
                                                  dataType => 'scalar',
                                                  allowEmpty => 0,
                                           	  maxLength => 8,
                                                  minLength => 1,
                                           	  readAccess => 0,     
                                                  required => 0,
                                           	  value => '',
                                           	  writeAccess => 1
                                           	 }
                                        },
                               writeAccess => 1                                      
                              }
                       }
              };
 
  # These are the parameters normally passed 
  # to a class using OOP.pm.
   
  my $objectProperties = {
                          one => 1,
                          two => 2,
                          three => {
                                    hi => {
                                           bye => '12345678'
                                          }
                                   }
                         };      
             
  my $obj = OOP->new({
                      ARGS=> $objectProperties,
                      PROTOTYPE => $classPrototype
                     });
                   

  print $obj->{PROPERTIES}->{three}{hi}{bye} . "\n";
  print $obj->getProperty($obj->{PROPERTIES}->{three}{hi}{bye}) . "\n";

=head1 ABSTRACT

This class is intended to complement Object Oriented Programming ("OOP")
development by offering solutions to common problems in the OOP world. If 
not problems then this class will also attempt to facilitate various OOP
related tasks and ensure that various conventions are followed, where 
possible. It provides a developer with various methods that enforce 
uniform OOP conventions and ensure sound OOP development in PERL.

Simply stated, this class attempts to take out as much of the OOP overhead 
for the developer as possible while at the same time allowing a developer 
to write more robust applications.

=head1 DESCRIPTION

The OOP class allows a developer to restrict property accessbility in more 
ways than one.  The developer can specify anything from how the data should 
be encapsulated to how many elements can be create dynamically to whether 
or not the property is read-only, and more...

The approach used in this class to handled properties relies on PERL's I<tie()> 
function. It is a very useful though often misunderstood and underused feature. 
Don't worry because this class takes care of everything for the developer; thus, 
not even a fundamental understanding of I<tie()> is necessary.  The code is 
readily available to those who desire to understand what is happening, but 
again it is not necessary to do so to use this class.

=head2 PROPERTIES

The class takes a slightly more unconventional approach on how properties
are handled.  The reason for this is to provide greater flexibility and 
expandibility for future releases of the OOP class.  As a matter of fact the
chosen approach is one that everyone can understand. 

There are three types of properties when using this class.  The naming 
conventions are proprietary to this class and have no relation to any outside 
terminology that might overlap.  Let's go over these properties.

=over 2

=item B<System Attributes>

The first type of properties are those passed to the constructor of the OOP
class. For sake of concept separation we will refer to these as I<attributes>.  
These are properties that are more or less static and required for the class to 
know how it is to operate and what it is to operate on.  If this doesn't make 
sense, simply know that these are B<required>.  

These attributes are set when the class is instantiated (or called), as such:

  my $obj = OOP->new({
                      ARGS=> $objectProperties,
                      PROTOTYPE => $classPrototype,
                      CUSTOM => {}
                     });

The argument is an anonymous hash where the keys are the I<system attributes>. 
If this doesn't make sense to you, simply know to follow the convention above 
and include the parenthesis and curly brackets as shown above. 

The corresponding values are hash references. Do not worry about these for right 
now as it would take away from our focus.  Let's keep our focus on the 
attributes themselves.

Presently there are the following system attributes (in alphabetical order):

=over 2

=item B<ARGS>

This property contains all the properties passed to the constructor of the class 
("user class") that uses the OOP class ("OOP class").  An example further down 
in this document will illustrate this better.

=item B<CUSTOM>

This property doesn't exist but is a place holder for future development.  Due 
to the strict nature of this class, it is intended to provide a point of entry 
(or exit) in the event a user would choose to customize the class. 

=item B<PROTOTYPE>

This property contains all the properties and their I<definitions>. Collectively 
this represents the "I<prototype>" for the constructor of the user class.

The prototype is, in effect, the I<design> of how the properties are to be 
handled by the OOP class (and consequently the user class).

=back

These attributes happen to be the other two types of properties.  It is 
important to remember that unless otherwise specified all system attributes are 
required.  All system attributes are reserved meaning that a developer should 
never clutter the namespace by adding custom keys as they could override future 
developments causing for undesirable side-effects.  For this purpose use the 
B<CUSTOM> system attribute as a safe attribute to funnel your custom data 
through.

=item B<Prototype Properties>

This is possibly one of the coolest features of the OOP class.  It permits the 
developer to define accessibility to properties in more ways than just either 
hiding the information or not (encapsulation).  As a matter of fact it allows to 
control properties to an unprecendented level allowing the developer to control 
how much or how little access to a property a user class should have. 

The prototype is built by way of a hash that is passed to the constructor of the 
OOP class via the I<system attributes> (see above), as such:

  my $obj = OOP->new({
                      ARGS=> $objectProperties,
                      PROTOTYPE => {
                                    one => {
                                            dataType => 'hash',
                                            allowEmpty => 0,
                                            maxLength => 3,
                                            minLength => 1,
                                            readAccess => 1,
                                            required => 1,
                                            value => {
                                                      abye => '',
                                                      bbye => {...}
                                                     },
                                            writeAccess => 1                                      
                                           },
                                   two => 'foobar',
                                   three => [1,2,3,4]
                                  },
                      CUSTOM => {}
                     });

Attention should be given to the B<PROTOTYPE> attribute in the above 
illustration where we can see an example of how the prototype properties are 
implemented.

The above illustrates how to define the various restrictions to a particular 
property.  Keep in mind that this is only the prototype so it does not directly 
deal with data passed into a constructor.  One way of seeing it is as a template 
that is overlayed with the actual data from the constructor.

Providing a definition of a property is always optional.  If none is provided then 
various logical defaults apply.  If one does not provide definitions then it will 
be considered that the elements (or properties) in the prototype are not exclusive 
but they are required.  In other words one could add properties dynamically but the 
constructor of the user class would need to have at the very least the properties 
of the prototype passed to it.

The OOP class guesses that it is a property definition by finding the keyword 
I<dataType> which happens to be the only reserved keyword (for a hash key).  This means that when a user 
class uses the OOP class it should try to avoid using a parameter called "I<dataType>" 
as it will trigger the OOP class to process it as a parameter definition and subsequently 
process all other keys within that level of the hash as I<prototype properties>.  

Any other keywords in a property definition each have their own special effects. All 
of them are required as of this writing but could change in the future.  The one 
property worthy pointing out right now is I<value>.  

The I<value> property simply states that if this is the actual value associated with 
the parameter of whose definition we are in.  Thus, in the above example I<value> would 
be the value of the property I<one>.  

To expand on this example, if the property I<two> had a definition then 'foobar' would 
be shifted to I<value>, as such:

  my $obj = OOP->new({
                      ARGS=> $objectProperties,
                      PROTOTYPE => {
                                    one => {
				            abye => '',
				            bbye => {...}
 			                   },
 			            two => {
				            dataType => 'scalar',
				            allowEmpty => 0,
				            maxLength => 7,
				            minLength => 1,
				            readAccess => 1,
				            required => 1,
				            value => 'foobar',
				            writeAccess => 1                                      
 			                   },
 			            three => [1,2,3,4]
                                   },
                       CUSTOM => {}
                     });
                     
In the above example we also see how I<value> of I<one> is the actual value when 
no definition is provided.

The various properties are explained (in alphabetical order):

=over 2

=item B<allowEmpty> 

This is a boolean (0 or 1) that simply defines whether or not the value of this 
parameter is allowed to be empty.  If it is set to zero then there must be a value, 
otherwise a 1 would instruct that the value can be empty.

=item B<dataType> 

This is a literal string containing the type of data found in this parameter. The
possible values presently are : I<hash> and I<scalar>. Others should work too, they 
just have not been tested.

=item B<locked> 

Boolean that takes 1 or 0 to define whether or not the particular property may be 
removed.  If it is set to 1 then it may not be removed otherwise if it set to 0 (zero) 
then a I<delete()> attempt will succeed.

=item B<maxLength> 

This is a number that indicates several things depending on context. The context is
determined by the value of I<dataType>.  The table below illustrates the effects 
based on the corresponding dataType.

=over 2

=item B<'array'>

Specifies the maximum possible elements in the array structure.  This is not yet
supported or enforced as of this writing.

=item B<'hash'>

Specifies the maximum possible elements in the hash structure.  This is enforced
both when the hash is passed as a parameter to the constructor as well as when 
an element is attempted to be added dynamically at runtime.

=item B<'scalar'>

In the event of a scalar it enforces the maximum length of the scalar.

=back

=item B<minLength> 

This is a number that indicates several things depending on context. The context is
determined by the value of I<dataType>.  This has the inverse effect of B<maxLength> 
so see the description of B<maxLength> for an idea of how this property works.

=item B<readAccess> 

A boolean that takes either a 1 or a 0 as a value.  This determines whether a user 
can directly access/read the data in the property.  If it is set to '1' then the 
user can access it directly by specifying the data structure (property).  If it is 
set to '0' however then an accessor needs to be used to access the property safely.

=item B<required> 

A boolean that takes either a 1 or a 0 as a value.  Specifies whether or not 
this property is required or optional.  If a property definition is not given to
a particular property then it is assumed that the element in the prototype is 
always required.  This gives the developer the ability to override that behavior 
by setting it to 0 (zero). 

When this property is set to zero it means that the value is not required but IF 
it exists and if a property definition exists (which it does in this case), then 
enforce the definition as well - even if the element is created dynamically.

A value of 1 indicates that this property I<must> be passed to the constructor.

=item B<value> 

This is the actual value of the property.  Normally this is left empty unless it 
contains further data structures such as hashes, array, etc...  In the event of 
a scalar however, it would indicate the default value and by combining the 
B<writeAccess> property it could be used as a read-only constant value within 
the user class.  See B<Prototype Properties> for more information on B<value>.

=item B<writeAccess> 

A boolean that takes either a 1 or a 0 as a value.  This determines whether a 
user can dynamically write to the data in the property.  If it is set to '1' 
then the user can write and thus overwrite it by specifying a new value.  If it 
is set to '0' however then this property becomes a read-only property.

Additionally, if this is set to '0' and the B<dataType> is a I<hash> or an 
I<array>, then it declares that elements may not be created on-the-fly or by 
passing non-defined elements to the constructor (elements that were not defined 
in the prototype).  Likewise if it is set to '1', then the opposite holds true.

=back

=item B<Object Properties>

As stated several times throughout this document the OOP class is generally going 
to be used in a "user class".  In the context of this document a "user class" is 
quite simply a class that uses this OOP class.

Knowing this the next question is 'how do we tie everything together?'  Good 
question!  This section will cover just that.

Let's say we are designing a new class called I<Foo> and we want to ensure that 
when another developer uses our class that all properties that are passed, used 
and modified are handled according to our prototype (our design). 

The very first thing that we need to do is I<design> the properties for a 
given module by specifying the prototype (see B<System Attributes> and B<Prototype Properties> 
for more details). We will continue with the assumption that we have a prototype 
in place.

The next step is to connect this prototype with our user class I<Foo>.  We will do 
so by instantiating the OOP class from within I<Foo>'s constructor.  This is 
achieved in a similar fashion:

  package Foo;

  use OOP;

  sub new {

   my ($class, $objectProperties) = (@_);
 
   my $self = bless {}, $class;
 
   my $obj = OOP->new({
                       ARGS=> $objectProperties,
                       PROTOTYPE => {
                                     one => {
 				             dataType => 'hash',
 				             allowEmpty => 0,
 				             maxLength => 3,
 				             minLength => 1,
 				             readAccess => 1,
 				             required => 1,
 				             value => {
 				                       abye => '',
 				                       bbye => {...}
 				                      },
 				             writeAccess => 1                                      
  			                    },
  			             two => 'foobar',
  			             three => [1,2,3,4]
                                    }
                      });
   
   $self->{OOP} = $obj;                         # optional but advised
   $self->{myProperties} = $obj->{PROPERTIES};  
   
   return ($self);
   
  }
  
  ...
  
  1;

Now whenever a user class will access the data found in the custom property 
I<$self->{myProperties}> it will be automatically checked against.

In case it wasn't clear from the above example properties are handled/passed just 
as in traditional hash-based objects.  This means that when the user class I<Foo> 
is called it would be called just as it would be called traditionally (without the 
use of the OOP class), as such:

  use Foo;
  
  my $object = Foo->new({
                         one => {
                                 abye => 'Superman!'
                                },
                         two => 'foobar',
                         three => [1,2,3,4]
                        });
  
  $object->{one}->{goodbye} = 'Yes it is valid!';
  $object->{one}->{abye} = 'Sure we could overwrite an element!';
  $object->{one}->{maxLength} = 666;               # no access to definitions
  $object->{PROTOTYPE}->{one}->{maxLength} = 666;  # no access to definitions
  $object->{one}->{badbye} = 'This one would not be good as per prototype!';
  
Can you tell any difference? Of course not, because that is the intended effect.  
It should allow the developer of I<Foo> to be able to distribute I<Foo>, write 
documentation on what properties it takes, and have the peace of mind that the user 
using I<Foo> will properly adhere to the intended usage.  

So while the user cannot tell the difference in the usage of the I<Foo> module, 
there is a great difference of what is happening behind the scenes.  Unlike I<Foo> 
without the OOP class, the OOP powered version gives peace of mind to both the 
user and developer of I<Foo> by ensuring proper adherence to intended usage.
  
=back

=head2 ACCESSORS

An important concept of Object Oriented Programming is the safe accessing of 
properties.  In simple terms, rather than reading the data by accessing 
the property directly, in OOP one accesses the property by way of calling a method 
which in turn accesses the property.  This is accomplished by way of "I<accessors>". 

The OOP class offers accessors that are quite generic in nature as to be most 
flexible.  A list of the presently supported accessors are listed below: 

=over 2

=item B<getProperty>

This is an extremely generic and simply accessor whose only task is to allow for 
a developer to access a property safely.  This counteracts the B<readAccess> 
prototype property when set to zero.  In other words if the prototype says that 
I<readAccess> is forbidden it merely forbids direct access.  In such case one 
has to consciously access it via this accessor.  It is merely a preventative 
measure to prevent accidental data overwrites, mixups, etc... by accessing the 
properties directly.

=back

=head1 AUTHOR INFORMATION

Copyright 2007-Present, Milan Adamovsky.  All rights reserved.  

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 BUGS

Please report them to: milan@adamovsky.com.

=head1 SEE ALSO



=cut

 
 
