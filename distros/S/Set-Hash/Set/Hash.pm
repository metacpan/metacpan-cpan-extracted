package Set::Hash;
use strict;
use attributes qw(reftype);
use Want;
use Carp;
use Set::Array;

use subs qw(delete exists keys length print reverse shift values);

use overload
   "==" => "is_equal",
   "!=" => "not_equal",
   "-"  => "difference",
   "*"  => "intersection",
   "+"  => "push",
   "%"  => "symmetric_difference",
   "fallback" => 1;

BEGIN{
   use vars qw(@ISA $VERSION);
   @ISA=qw(Set::Array);
   $VERSION = '0.01';
}

sub new{
   my($class,%hash) = @_;
   %hash = @$class if !%hash && ref($class);
   return bless \%hash, ref($class) || $class;
}

sub clear{
   my $self = CORE::shift;
   %$self = ();
   if(want("OBJECT") || !defined(wantarray)){
      return $self;
   }
   
   return () if wantarray;
   return {};
}

sub delete{
   my($self,@args) = @_;

   my @deleted = CORE::delete(@{$self}{@args});
   
   if( want("OBJECT") || !defined(wantarray) )
   {
      return $self;
   }

   return @deleted if wantarray;
   return \@deleted;
}

sub difference{
   my($op1,$op2,$reversed) = @_;
   ($op2,$op1) = ($op1,$op2) if $reversed;

   my %diff;
   while(my($key,$val) = CORE::each(%$op1))
   {
      unless(CORE::exists($op2->{$key}))
      {
         $diff{$key} = $val;
         next;
      }

      $diff{$key} = $val unless $op1->{$key} == $op2->{$key};
   }

   if(want("OBJECT") || !defined(wantarray))
   {
      %$op1 = %diff;
      return $op1;
   }
   return %diff if wantarray;
   return \%diff;
}

sub exists{
   my($self,@keys) = @_;
   CORE::foreach my $key(@keys)
   {
      return 0 unless CORE::exists($self->{$key});
   }
   return 1;
}

sub intersection{
   my($op1,$op2,$reversed) = @_;
   ($op2,$op1) = ($op1,$op2) if $reversed;

   my %inter;
   while(my($key,$val) = CORE::each(%$op1))
   {
      next unless CORE::exists($op2->{$key});
      if($op1->{$key} == $op2->{$key})
      {
         $inter{$key} = $val;
      }
   }

   if(want("OBJECT") || !defined(wantarray))
   {
      %$op1 = %inter;
      return $op1;
   }
   return %inter if wantarray;
   return \%inter;
}

sub is_equal{
   my($op1,$op2,$reversed) = @_;
   ($op2,$op1) = ($op1,$op2) if $reversed;

   # Automatic failure if they're not the same length
   return 0 unless scalar(CORE::keys(%$op1)) == scalar(CORE::keys(%$op2));

   while(my($key,$val) = CORE::each(%$op1))
   {
      return 0 unless $op1->{$key} == $op2->{$key};
   }
   return 1;
}

sub keys{
   my $self = CORE::shift;
   my @keys = CORE::keys(%$self);
   if(want("OBJECT") || !defined(wantarray)){
      return bless(\@keys);
   }
   
   return @keys if wantarray;
   return \@keys;
}

sub length{
   my $self = CORE::shift;
   my $length;

   if(reftype($self) eq "HASH"){
      $length = scalar(CORE::keys(%$self));
   }
   else{
      $length = $self->SUPER::length;
   }

   if(want("OBJECT") || !defined(wantarray)){
      return bless(\$length);
   }
   return $length;
}

sub not_equal{
   my($op1,$op2,$reversed) = @_;
   ($op2,$op1) = ($op1,$op2) if $reversed;

   # Automatically true if they're not the same length
   return 1 unless scalar(CORE::keys(%$op1)) == scalar(CORE::keys(%$op2));

   while(my($key,$val) = CORE::each(%$op1))
   {
      return 1 unless $op1->{$key} == $op2->{$key};
   }
   return 0;
}

sub print{
   my($self,$char) = @_;
   $char = "\n" if $char >= 1;

   if(reftype($self) eq "HASH"){ CORE::print(%$self) }
   if(reftype($self) eq "ARRAY"){ CORE::print(@$self) }
   if(reftype($self) eq "SCALAR"){ CORE::print($$self) }
   CORE::print($char) if $char;

   return $self;
}

sub push{
   my($self,@args) = @_;

   if(ref($args[0]) eq "Set::Hash")
   {
      my %merged;
      while(my($key,$val) = CORE::each(%$self))
      {
         $merged{$key} = $val;
      }

      while(my($key,$val) = CORE::each(%{$args[0]}))
      {
         $merged{$key} = $val;
      }
      return bless \%merged;
   }

   while(@args)
   {
      my $key = CORE::shift(@args);
      my $val = CORE::shift(@args) || undef;
      $self->{$key} = $val;
   }

   return $self;
}
*unshift = \&push;
*union = \&push;

sub reverse{
   my($self) = @_;

   if( (want('OBJECT')) || (!defined wantarray) ){
      %$self = CORE::reverse %$self;
      return $self;
   }

   my %temp = CORE::reverse %$self;
   if(wantarray){ return %temp }
   if(defined wantarray){ return \%temp }
}

sub shift{
   my $self = CORE::shift;
   
   my($key,$val) = CORE::each(%$self);
   CORE::delete($self->{$key});

   return ($key,$val) if wantarray;
   return {$key,$val} if defined wantarray;
   return $self;
}
*pop = \&shift;

sub symmetric_difference{
   my($op1,$op2,$reversed) = @_;
   ($op2,$op1) = ($op1,$op2) if $reversed;

   
}

sub values{
   my $self = CORE::shift;
   my @vals = CORE::values(%$self);
   if(want("OBJECT") || !defined(wantarray)){
      return bless(\@vals);
   }
   
   return @vals if wantarray;
   return \@vals;
}
1;
__END__

=head1 NAME

Set::Hash - Hashes as objects with lots of handy methods (including set
comparisons) and support for method chaining.

=head1 SYNOPSIS

C<< use Set::Hash; >>

C<< my $sh1 = Set::Hash->new(name=>"dan",age=>33); >>

C<< my $sh2 = Set::Hash->new(qw/weight 185 height 72/); >>

C<< $sh1->length->print; # 2 >>

C<< $sh1->push($sh2); # $sh1 now has weight=>185 and height=>72 >>

C<< $sh1->length->print; # 4 >>

C<< $sh2->values->join(",")->print(1); # 185, 72 >>

=head1 PREREQUISITES

Perl 5.6 or later

Set::Array .10 or later, by me.  Available on CPAN.

Want .05 or later, by Robin Houston.  Available on CPAN.

=head1 DESCRIPTION

Set::Hash allows you to create strings as objects and use OO-style methods
on them.  Many convenient methods are provided here that appear in the
FAQ's, the Perl Cookbook or posts from comp.lang.perl.misc.
In addition, there are Set methods with corresponding (overloaded)
operators for the purpose of Set comparison, i.e. B<+>, B<==>, etc.

The purpose is to provide built-in methods for operations that people are
always asking how to do, and which already exist in languages like Ruby.
This should (hopefully) improve code readability and/or maintainability.  The
other advantage to this module is method-chaining by which any number of
methods may be called on a single object in a single statement.

Note that Set::Hash is a subclass of Set::Array, although most of the methods
of Set::Array have been overloaded, so you'll want to check the documentation
for what each method does exactly.

=head2 OBJECT BEHAVIOR

The exact behavior of the methods depends largely on the calling context.

B<Here are the rules>:

* If a method is called in void context, the object itself is modified.

* If the method called is not the last method in a chain (i.e. it's called
  in object context), the object itself is modified by that method regardless
  of the 'final' context or method call.

* If a method is called in list or scalar context, a list or list refererence
  is returned, respectively. The object itself is B<NOT> modified.

B<Here are the exceptions>:

* Methods that report a value, such as boolean methods like I<exists()> or
  other methods such as I<equals()> or I<not_equals()>, never modify the object.

* The methods I<clear()> and I<delete()> will
  B<always> modify the object. It seemed much too counterintuitive to call these
  methods in any context without actually deleting/clearing/substituting the items!

* The methods I<shift()> and I<pop()> will modify the object B<AND> return
  the key/value pair that was shifted or popped from the hash.  Again, it
  seemed much too counterintuitive for something like C<$val = $sh-E<gt>shift>
  to return a value while leaving the object's list unchanged.

=head2 INSTANCE METHODS

B<delete(>I<keys>B<)> - Deletes the specified I<keys> from the hash.  This
method violates our normal context rules, in that it modifies the receiver,
regardless of context.

Returns an array or array reference of I<values> that were deleted (not
keys), in list or scalar context, respectively.

B<exists(>I<keys>B<)> - Returns 1 (true) if the specified key(s) exist, even if
the corresponding value is undefined.  Otherwise 0 (false) is returned.  If
multiple keys are specified, it returns true only if B<all>keys exist.

B<keys> - Returns an array of keys for the hash, or an array reference in
scalar context.

B<length> - Returns the length of the hash, i.e. the number of pairs (not
total elements).

B<pop> - An alias for I<shift()>.  This will change when support for ordered
hashes is added.

B<push(>I<args>B<)> - Pushes a key/value pair onto the hash.  If an odd number
of elements is pushed, then the value for the odd key will be set to undef.

Optionally, you may pass another I<Set::Hash> object as the argument.

B<reverse> - Turns keys into values and values into keys.  Returns a hash
in list context, or a hash reference in scalar context.

B<shift> - Shifts a key/value pair off the hash.  Returns a 2 element list in
list context, or a hash reference in scalar context.  You cannot predict the
key/value pair that you will get in an unordered hash.

Note that this rule violates our normal context rules.  It B<always> modifies
the receiver, regardless of context.

B<unshift> - An alias for I<push()>.  This will change when support for ordered
hashes is added.

B<values> - Returns an array of values for the hash, or an array reference
in scalar context.

=head2 OVERLOADED OPERATORS

B<==> or B<is_equal> - Tests to see if the hashes have the same keys and the
same values for those keys.  Internal ordering is irrelevant for this test.

Returns 0 on failure, 1 on success.

B<!=> or B<not_equal> - Opposite of I<is_equal()>.

Returns 0 on failure, 1 on success.

B<-> or B<difference(>I<object>B<)> - Returns all the key/value pairs on the
right side that aren't on the left side as a hash or hash reference, in
list or scalar context, respectively.

e.g.

C<< my $sh1 = Set::Hash->new(qw/name dan age 33/); >>

C<< my $sh2 = Set::Hash->new(qw/name dan age 33 weight 185/); >>

C<< my $diff = $sh1->difference($sh2); # {weight => 185} >>

Note that both keys B<and> values are used for this calcuation so
{age=>33} is not the same as {age=>32}, for example.

B<*> or B<intersection(>I<object>B<)> - Returns all they key/value pairs that
are common to both hash objects.  Returns a hash or hash reference in list or
scalar context, respectively.

B<+> or B<union(>I<object>B<)> - Returns the union of both sets.  Since keys
must be unique, keys of the right object will overwrite those on the left if
they're identical.

This is really an alias for the I<push()> method.

=head1 KNOWN BUGS

There is currently a bug in Want-0.05 that prevents use of most of the
overloaded operators.  However, the named version of those operators
should work fine, e.g. "difference()" vs "-".

Also, "==" and "!=" work fine.

=head1 FUTURE PLANS

Optional ordered hash, using I<Tie::IxHash>

each()

symmetric_difference()

flatten()

to_a()

=head1 AUTHOR

Daniel J. Berger
djberg96 at yahoo dot com
