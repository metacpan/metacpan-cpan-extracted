use 5.008;
use strict;
use warnings;

package Sub::HandlesVia;

use Exporter::Shiny qw( delegations );

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.028';

sub _generate_delegations {
	my ($me, $name, $args, $globals) = (shift, @_);
	
	my $target = $globals->{into};
	!defined $target and die;
	ref $target and die;

	my $toolkit = $me->detect_toolkit($target);
	return sub { $toolkit->install_delegations(target => $target, @_) };
}

sub _exporter_validate_opts {
	my ($me, $globals) = (shift, @_);

	my $target = $globals->{into};
	!defined $target and die;
	ref $target and die;

	my $toolkit = $me->detect_toolkit($target);
	$toolkit->setup_for($target) if $toolkit->can('setup_for');
}

sub detect_toolkit {
	my $toolkit = sprintf(
		'%s::Toolkit::%s',
		__PACKAGE__,
		shift->_detect_framework(@_),
	);
	eval "require $toolkit" or Exporter::Tiny::_croak($@);
	return $toolkit;
}

sub _detect_framework {
	my ($me, $target) = (shift, @_);
	
	if ($INC{'Moo/Role.pm'}
	and Moo::Role->is_role($target)) {
		return 'Moo';
	}
	
	if ($INC{'Moo.pm'}
	and $Moo::MAKERS{$target}
	and $Moo::MAKERS{$target}{is_class}) {
		return 'Moo';
	}
	
	if ($INC{'Moose/Role.pm'}
	and $target->can('meta')
	and $target->meta->isa('Moose::Meta::Role')) {
		return 'Moose';
	}
	
	if ($INC{'Moose.pm'}
	and $target->can('meta')
	and $target->meta->isa('Moose::Meta::Class')) {
		return 'Moose';
	}

	if ($INC{'Mouse/Role.pm'}
	and $target->can('meta')
	and $target->meta->isa('Mouse::Meta::Role')) {
		return 'Mouse';
	}
	
	if ($INC{'Mouse.pm'}
	and $target->can('meta')
	and $target->meta->isa('Mouse::Meta::Class')) {
		return 'Mouse';
	}
	
	{
		no strict 'refs';
		no warnings 'once';
		if ( ${"$target\::USES_MITE"} ) {
			return 'Mite';
		}
	}
	
	return 'Plain';
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Sub::HandlesVia - alternative handles_via implementation

=head1 SYNOPSIS

 package Kitchen {
   use Moo;
   use Sub::HandlesVia;
   use Types::Standard qw( ArrayRef Str );
   
   has food => (
     is          => 'ro',
     isa         => ArrayRef[Str],
     handles_via => 'Array',
     default     => sub { [] },
     handles     => {
       'add_food'    => 'push',
       'find_food'   => 'grep',
     },
   );
 }

 my $kitchen = Kitchen->new;
 $kitchen->add_food('Bacon');
 $kitchen->add_food('Eggs');
 $kitchen->add_food('Sausages');
 $kitchen->add_food('Beans');
 
 my @foods = $kitchen->find_food(sub { /^B/i });

=head1 DESCRIPTION

If you've used L<Moose>'s native attribute traits, or L<MooX::HandlesVia>
before, you should have a fairly good idea what this does.

Why re-invent the wheel? Well, this is an implementation that should work
okay with Moo, Moose, Mouse, and any other OO toolkit you throw at it.
One ring to rule them all, so to speak.

Also, unlike L<MooX::HandlesVia>, it honours type constraints, plus it
doesn't have the limitation that it can't mutate non-reference values.

Note: as Sub::HandlesVia needs to detect whether you're using Moo, Moose,
or Mouse, and often needs to detect whether your package is a class or a
role, it needs to be loaded I<after> Moo/Moose/Mouse.

=head2 Using with Moo

You should be able to use it as a drop-in replacement for L<MooX::HandlesVia>.

 package Kitchen {
   use Moo;
   use Sub::HandlesVia;
   use Types::Standard qw( ArrayRef Str );
   
   has food => (
     is          => 'ro',
     isa         => ArrayRef[Str],
     handles_via => 'Array',
     default     => sub { [] },
     handles     => {
       'add_food'    => 'push',
       'find_food'   => 'grep',
     },
   );
 }

=head2 Using with Mouse

It works the same as Moo basically.

 package Kitchen {
   use Mouse;
   use Sub::HandlesVia;
   use Types::Standard qw( ArrayRef Str );
   
   has food => (
     is          => 'ro',
     isa         => ArrayRef[Str],
     handles_via => 'Array',
     default     => sub { [] },
     handles     => {
       'add_food'    => 'push',
       'find_food'   => 'grep',
     },
   );
 }

You are not forced to use Types::Standard. Mouse native types should
work fine.

 package Kitchen {
   use Mouse;
   use Sub::HandlesVia;
   
   has food => (
     is          => 'ro',
     isa         => 'ArrayRef[Str]',
     handles_via => 'Array',
     default     => sub { [] },
     handles     => {
       'add_food'    => 'push',
       'find_food'   => 'grep',
     },
   );
 }

Sub::HandlesVia will also recognize L<MooseX::NativeTraits>-style
traits. It will jump in and handle them before L<MooseX::NativeTraits>
notices!

 package Kitchen {
   use Mouse;
   use Sub::HandlesVia;
   
   has food => (
     is          => 'ro',
     isa         => 'ArrayRef[Str]',
     traits      => ['Array'],
     default     => sub { [] },
     handles     => {
       'add_food'    => 'push',
       'find_food'   => 'grep',
     },
   );
 }

(If you have a mouse in your kitchen though, that might not be very
hygienic.)

=head2 Using with Moose

It works the same as Mouse basically.

 package Kitchen {
   use Moose;
   use Sub::HandlesVia;
   use Types::Standard qw( ArrayRef Str );
   
   has food => (
     is          => 'ro',
     isa         => ArrayRef[Str],
     handles_via => 'Array',
     default     => sub { [] },
     handles     => {
       'add_food'    => 'push',
       'find_food'   => 'grep',
     },
   );
 }

You are not forced to use Types::Standard. Moose native types should
work fine.

 package Kitchen {
   use Moose;
   use Sub::HandlesVia;
   
   has food => (
     is          => 'ro',
     isa         => 'ArrayRef[Str]',
     handles_via => 'Array',
     default     => sub { [] },
     handles     => {
       'add_food'    => 'push',
       'find_food'   => 'grep',
     },
   );
 }

Sub::HandlesVia will also recognize native-traits-style traits. It will
jump in and handle them before Moose notices!

 package Kitchen {
   use Moose;
   use Sub::HandlesVia;
   
   has food => (
     is          => 'ro',
     isa         => 'ArrayRef[Str]',
     traits      => ['Array'],
     default     => sub { [] },
     handles     => {
       'add_food'    => 'push',
       'find_food'   => 'grep',
     },
   );
 }

(If you have a moose in your kitchen, that might be even worse than
the mouse.)

=head2 Using with Mite

You should be able to use Sub::HandlesVia with L<Mite> 0.001011 or above.
Your project will still have a dependency on Sub::HandlesVia.

 package MyApp::Kitchen {
   use MyApp::Mite;
   use Sub::HandlesVia;
   
   has food => (
     is          => 'ro',
     isa         => 'ArrayRef[Str]',
     handles_via => 'Array',
     default     => sub { [] },
     handles     => {
       'add_food'    => 'push',
       'find_food'   => 'grep',
     },
   );
 }

=head2 Using with Anything

For Moose and Mouse, Sub::HandlesVia can use their metaobject protocols
to grab an attribute's definition and install the methods it needs to.
For Moo, it can wrap C<has> and do its stuff that way. For other classes,
you need to be more explicit and tell it what methods to delegate to
what attributes.

 package Kitchen {
   use Class::Tiny {
     food => sub { [] },
   };
   
   use Sub::HandlesVia qw( delegations );
   
   delegations(
     attribute   => 'food'
     handles_via => 'Array',
     handles     => {
       'add_food'    => 'push',
       'find_food'   => 'grep',
     },
   );
 }

Setting C<attribute> to "food" means that when Sub::HandlesVia needs
to get the food list, it will call C<< $kitchen->food >> and when
it needs to set the food list, it will call C<< $kitchen->food($value) >>.
If you have separate getter and setter methods, just do:

     attribute   => [ 'get_food', 'set_food' ],

Or if you don't have any accessors and want Sub::HandlesVia to
directly access the underlying hashref:

     attribute   => '{food}',

Or maybe you have a setter, but want to use hashref access for the
getter:

     attribute   => [ '{food}', 'set_food' ],

Or maybe you still want direct access for the getter, but your
object is a blessed arrayref instead of a blessed hashref:

     attribute   => [ '[7]', 'set_food' ],

Or maybe your needs are crazy unique:

     attribute   => [ \&getter, \&setter ],

The coderefs are passed the instance as their first argument, and
the setter is also passed a value to set.

Really, I don't think there's any object system that this won't work
for!

If you supply an arrayref with a getter and setter, it's also
possible to supply a third argument which is a coderef or string
which will be called as a method if needing to "reset" the value.
This can be thought of like a default or builder.

(The C<delegations> function can be imported into Moo/Mouse/Moose classes
too, in which case the C<attribute> needs to be the same attribute name
you passed to C<has>. You cannot use a arrayref, coderef, hash key, or
array index.)

=head2 What methods can be delegated to?

The following table compares Sub::HandlesVia with L<Data::Perl>, L<Moose>
native traits, and L<MouseX::NativeTraits>.

  Array ===========================================
            accessor : SubHV  DataP  Moose  Mouse  
                 all : SubHV  DataP                
            all_true : SubHV                       
                 any : SubHV                Mouse  
               apply : SubHV                Mouse  
               clear : SubHV  DataP  Moose  Mouse  
               count : SubHV  DataP  Moose  Mouse  
              delete : SubHV  DataP  Moose  Mouse  
            elements : SubHV  DataP  Moose  Mouse  
               fetch :                      Mouse  (alias: get)
               first : SubHV  DataP  Moose  Mouse  
         first_index : SubHV  DataP  Moose         
             flatten : SubHV  DataP                
        flatten_deep : SubHV  DataP                
            for_each : SubHV                Mouse  
       for_each_pair : SubHV                Mouse  
                 get : SubHV  DataP  Moose  Mouse  
                grep : SubHV  DataP  Moose  Mouse  
                head : SubHV  DataP                
              insert : SubHV  DataP  Moose  Mouse  
            is_empty : SubHV  DataP  Moose  Mouse  
                join : SubHV  DataP  Moose  Mouse  
                 map : SubHV  DataP  Moose  Mouse  
                 max : SubHV                       
              maxstr : SubHV                       
                 min : SubHV                       
              minstr : SubHV                       
            natatime : SubHV  DataP  Moose         
        not_all_true : SubHV                       
           pairfirst : SubHV                       
            pairgrep : SubHV                       
            pairkeys : SubHV                       
             pairmap : SubHV                       
               pairs : SubHV                       
          pairvalues : SubHV                       
         pick_random : SubHV                       
                 pop : SubHV  DataP  Moose  Mouse  
               print : SubHV  DataP                
             product : SubHV                       
                push : SubHV  DataP  Moose  Mouse  
              reduce : SubHV  DataP  Moose  Mouse  
          reductions : SubHV                       
              remove :                      Mouse  (alias: delete)
               reset : SubHV                       
             reverse : SubHV  DataP                
              sample : SubHV                       
                 set : SubHV  DataP  Moose  Mouse  
       shallow_clone : SubHV  DataP  Moose         
               shift : SubHV  DataP  Moose  Mouse  
             shuffle : SubHV  DataP  Moose  Mouse  
    shuffle_in_place : SubHV                       
                sort : SubHV  DataP  Moose  Mouse  
             sort_by :                      Mouse  (sort)
       sort_in_place : SubHV  DataP  Moose  Mouse  
    sort_in_place_by :                      Mouse  (sort_in_place)
              splice : SubHV  DataP  Moose  Mouse  
               store :                      Mouse  (alias: set)
                 sum : SubHV                       
                tail : SubHV  DataP                
                uniq : SubHV  DataP  Moose  Mouse  
       uniq_in_place : SubHV                       
             uniqnum : SubHV                       
    uniqnum_in_place : SubHV                       
             uniqstr : SubHV                       
    uniqstr_in_place : SubHV                       
             unshift : SubHV  DataP  Moose  Mouse  
  
  Bool ============================================
                 not : SubHV  DataP  Moose  Mouse  
               reset : SubHV                       
                 set : SubHV  DataP  Moose  Mouse  
              toggle : SubHV  DataP  Moose  Mouse  
               unset : SubHV  DataP  Moose  Mouse  
  
  Code ============================================
             execute : SubHV  DataP  Moose  Mouse  
      execute_method : SubHV         Moose  Mouse  
  
  Counter =========================================
                 dec : SubHV  DataP  Moose  Mouse  
                 inc : SubHV  DataP  Moose  Mouse  
               reset : SubHV  DataP  Moose  Mouse  
                 set : SubHV         Moose  Mouse  
  
  Hash ============================================
            accessor : SubHV  DataP  Moose  Mouse  
                 all : SubHV  DataP                
               clear : SubHV  DataP  Moose  Mouse  
               count : SubHV  DataP  Moose  Mouse  
             defined : SubHV  DataP  Moose  Mouse  
              delete : SubHV  DataP  Moose  Mouse  
            elements : SubHV  DataP  Moose  Mouse  
              exists : SubHV  DataP  Moose  Mouse  
               fetch :                      Mouse  (alias: get)
        for_each_key : SubHV                Mouse  
       for_each_pair : SubHV                Mouse  
      for_each_value : SubHV                Mouse  
                 get : SubHV  DataP  Moose  Mouse  
            is_empty : SubHV  DataP  Moose  Mouse  
                keys : SubHV  DataP  Moose  Mouse  
                  kv : SubHV  DataP  Moose  Mouse  
               reset : SubHV                       
                 set : SubHV  DataP  Moose  Mouse  
       shallow_clone : SubHV  DataP  Moose         
         sorted_keys : SubHV                Mouse  
               store :                      Mouse  (alias: set)
              values : SubHV  DataP  Moose  Mouse  
  
  Number ==========================================
                 abs : SubHV  DataP  Moose  Mouse  
                 add : SubHV  DataP  Moose  Mouse  
                 cmp : SubHV                       
                 div : SubHV  DataP  Moose  Mouse  
                  eq : SubHV                       
                  ge : SubHV                       
                 get : SubHV                       
                  gt : SubHV                       
                  le : SubHV                       
                  lt : SubHV                       
                 mod : SubHV  DataP  Moose  Mouse  
                 mul : SubHV  DataP  Moose  Mouse  
                  ne : SubHV                       
                 set : SubHV         Moose         
                 sub : SubHV  DataP  Moose  Mouse  
  
  Scalar ==========================================
         make_getter : SubHV                       
         make_setter : SubHV                       
    scalar_reference : SubHV                       
  
  String ==========================================
              append : SubHV  DataP  Moose  Mouse  
               chomp : SubHV  DataP  Moose  Mouse  
                chop : SubHV  DataP  Moose  Mouse  
               clear : SubHV  DataP  Moose  Mouse  
                 cmp : SubHV                       
                cmpi : SubHV                       
            contains : SubHV                       
          contains_i : SubHV                       
           ends_with : SubHV                       
         ends_with_i : SubHV                       
                  eq : SubHV                       
                 eqi : SubHV                       
                  fc : SubHV                       
                  ge : SubHV                       
                 gei : SubHV                       
                 get : SubHV                       
                  gt : SubHV                       
                 gti : SubHV                       
                 inc : SubHV  DataP  Moose  Mouse  
                  lc : SubHV                       
                  le : SubHV                       
                 lei : SubHV                       
              length : SubHV  DataP  Moose  Mouse  
                  lt : SubHV                       
                 lti : SubHV                       
               match : SubHV  DataP  Moose  Mouse  
             match_i : SubHV                       
                  ne : SubHV                       
                 nei : SubHV                       
             prepend : SubHV  DataP  Moose  Mouse  
             replace : SubHV  DataP  Moose  Mouse  
    replace_globally : SubHV                Mouse  
               reset : SubHV                       
                 set : SubHV                       
         starts_with : SubHV                       
       starts_with_i : SubHV                       
              substr : SubHV  DataP  Moose  Mouse  
                  uc : SubHV                       

For further details see:
L<Array|Sub::HandlesVia::HandlerLibrary::Array>,
L<Bool|Sub::HandlesVia::HandlerLibrary::Bool>,
L<Code|Sub::HandlesVia::HandlerLibrary::Code>,
L<Counter|Sub::HandlesVia::HandlerLibrary::Counter>,
L<Hash|Sub::HandlesVia::HandlerLibrary::Hash>,
L<Number|Sub::HandlesVia::HandlerLibrary::Number>,
L<Scalar|Sub::HandlesVia::HandlerLibrary::Scalar>, and
L<String|Sub::HandlesVia::HandlerLibrary::String>.

=head2 Method Chaining

Say you have the following

     handles_via => 'Array',
     handles     => {
       'add_food'    => 'push',
       'find_food'   => 'grep',
       'remove_food' => 'pop',
     },

Now C<< $kitchen->remove_food >> will remove the last food on the list and
return it. But what if we don't care about what food was removed? We just
want to remove the food and discard it. You can do this:

     handles_via => 'Array',
     handles     => {
       'add_food'    => 'push',
       'find_food'   => 'grep',
       'remove_food' => 'pop...',
     },

Now the C<remove_food> method will return the kitchen object instead of
returning the food. This makes it suitable for chaining method calls:

  # remove the three most recent foods
  $kitchen->remove_food->remove_food->remove_food;

=head2 Hand Waving

Sub::HandlesVia tries to be strict by default, but you can tell it to be
less rigourous checking method arguments, etc using the C<< ~ >> prefix:

     handles_via => 'Array',
     handles     => {
       'find_food'   => '~grep',
     },

=head2 CodeRefs

You can delegate to coderefs:

     handles_via => 'Array',
     handles    => {
       'find_healthiest' => sub { my $foods = shift; ... },
     }

=head2 Named Methods

Let's say "FoodList" is a class where instances are blessed arrayrefs
of strings.

     isa         => InstanceOf['FoodList'],
     handles_via => 'Array',
     handles     => {
       'find_food'             => 'grep',
       'find_healthiest_food'  => 'find_healthiest',
     },

Now C<< $kitchen->find_food($coderef) >> does this (which breaks
encapsulation of course):

  my @result = grep $coderef->(), @{ $kitchen->food };

And C<< $kitchen->find_healthiest_food >> does this:

  $kitchen->food->find_healthiest

Basically, because C<find_healthiest> isn't one of the methods offered
by Sub::HandlesVia::HandlerList::Array, it assumes you want to call it
on the arrayref like a proper method.

=head2 Currying Favour

All this talk of food is making me hungry, but as much as I'd like to eat a
curry right now, that's not the kind of currying we're talking about.

     handles_via => 'Array',
     handles     => {
       'get_food'   => 'get',
     },

C<< $kitchen->get_food(0) >> will return the first item on the list.
C<< $kitchen->get_food(1) >> will return the second item on the list.
And so on.

     handles_via => 'Array',
     handles     => {
       'first_food'   => [ 'get' => 0 ],
       'second_food'  => [ 'get' => 1 ],
     },

I think you already know what this does. Right?

And yes, currying works with coderefs.

     handles_via => 'Array',
     handles     => {
       'blargy'       => [ sub { ... }, @curried ],
     },

=head2 Pick and Mix

    isa         => ArrayRef|HashRef,
    handles_via => [ 'Array', 'Hash' ],
    handles     => {
      the_keys     => 'keys',
      ship_shape   => 'sort_in_place',
    }

Here you have an attribute which might be an arrayref or a hashref.
When it's an arrayref, C<< $object->ship_shape >> will work nicely,
but C<< $object->the_keys >> will fail badly.

Still, this sort of thing can kind of make sense if you have an
object that overloads both C<< @{} >> and C<< %{} >>.

Sometime a method will be ambiguous. For example, there's a C<get>
method for both hashes and arrays. In this case, the array one will
win because you listed it first in C<handles_via>.

But you can be specific:

    isa         => ArrayRef|HashRef,
    handles_via => [ 'Array', 'Hash' ],
    handles     => {
      get_foo => 'Array->get',
      get_bar => 'Hash->get',
    }

=head1 BUGS

Please report any bugs to
L<https://github.com/tobyink/p5-sub-handlesvia/issues>.

(There are known bugs for Moose native types that do coercion.)

=head1 SEE ALSO

Documentation for delegatable methods:
L<Array|Sub::HandlesVia::HandlerLibrary::Array>,
L<Bool|Sub::HandlesVia::HandlerLibrary::Bool>,
L<Code|Sub::HandlesVia::HandlerLibrary::Code>,
L<Counter|Sub::HandlesVia::HandlerLibrary::Counter>,
L<Hash|Sub::HandlesVia::HandlerLibrary::Hash>,
L<Number|Sub::HandlesVia::HandlerLibrary::Number>,
L<Scalar|Sub::HandlesVia::HandlerLibrary::Scalar>, and
L<String|Sub::HandlesVia::HandlerLibrary::String>.

Other implementations of the same concept:
L<Moose::Meta::Attribute::Native>, L<MouseX::NativeTraits>, and
L<MooX::HandlesVia> with L<Data::Perl>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2020, 2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

